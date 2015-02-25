module Listeners
  class EnrollmentSubmittedHandler < Amqp::Client
    FailureResponse = Struct.new(
      :enrollment_payload, :eg_uri, :st, :error_code, :kind, :response_code
    )

    PolicyProperties = Struct.new(
      :eg_id, :submitted_timestamp, :kind
    )

    def xml_ns 
      { "cv" => "http://openhbx.org/api/terms/1.0" }
    end

    def get_policy_id(doc)
      doc.xpath("//cv:policy/cv:id/cv:id", xml_ns).map do |node|
        node.content
      end.join(",")
    end

    def get_employment_eligibility_elements(doc)
      employer_fein = Maybe.new(doc.at_xpath("//cv:employer_link/cv:id/cv:id",xml_ns)).content.strip.split("#").last.value
      subscriber_ssn = Maybe.new(
        doc.at_xpath("//cv:enrollee[contains(cv:is_subscriber, 'true')]/cv:member/cv:person_demographics/cv:ssn",xml_ns)
      ).content.strip.value
      subscriber_coverage_start = Maybe.new(
        doc.at_xpath("//cv:enrollee[contains(cv:is_subscriber, 'true')]/cv:benefit/cv:begin_date",xml_ns)
      ).content.strip.value
      [employer_fein,subscriber_ssn]
    end

    def fix_start_dates(doc, employment)
      coverage_start = Date.new(employment.start_date.year, employment.start_date.month, 1) >> 1
      if coverage_start < Hack::EmploymentList::EARLIEST_ENROLLMENT
        coverage_start = Hack::EmploymentList::EARLIEST_ENROLLMENT
      end
      doc.xpath("//cv:benefit/cv:begin_date", xml_ns).each do |node|
        node.content = coverage_start.strftime("%Y%m%d")
      end
      doc
    end

    def on_message(delivery_info, properties, payload)
      parsed_payload = Nokogiri::XML(payload)
      with_m_ids_payload = generate_member_ids(parsed_payload)
      with_ids_payload = generate_policy_ids(with_m_ids_payload)
      eg_id = properties.headers["eg_uri"]
      st = properties.headers["submitted_timestamp"]
      workflow = Fail.new do |fresp|
        fail_with_message(fresp.enrollment_payload, fresp.eg_uri, fresp.st, fresp.error_code, fresp.kind, fresp.response_code)
      end
      if is_shop?(with_ids_payload)
        workflow.bind do |data|
          working_payload, props, eg_uri, sub_time = data
          with_employer_payload = substitute_employer_uri(working_payload)
          elig_info = get_employment_eligibility_elements(with_employer_payload)
          employment = ::Hack::EmploymentList.match(*elig_info)
          if employment.blank?
            failure_data = {
              :reason => "no matching employment",
              :employer_fein => elig_info.first,
              :subscriber_ssn => elig_info[1],
              :coverage_start => sub_time.to_s
            }
            throw :fail, FailureResponse.new(with_employer_payload.canonicalize, eg_uri, sub_time, JSON.dump(failure_data), "employer_employee", "422")
          end
          fixed_payload = fix_start_dates(with_employer_payload, employment).canonicalize
          [fixed_payload, props, PolicyProperties.new(eg_uri, sub_time, "employer_employee")]
        end
      else
        workflow.bind do |data|
          working_payload, props, eg_uri, sub_time = data
          fixed_payload = working_payload.canonicalize
          [fixed_payload, props, PolicyProperties.new(eg_uri, sub_time, "individual")]
        end
      end
      workflow.bind do |data|
        fixed_payload, props, pol_props = data
        validate_enrollment(fixed_payload, props, pol_props)
        create_enrollment(fixed_payload, props, pol_props.kind, pol_props.eg_id, pol_props.submitted_timestamp)
      end
      workflow.call([with_ids_payload, properties, eg_id, st])
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def replace_with_map(doc, id_mapping)
      id_mapping.each_pair do |k,v|
        xpath_query = "//*[contains(text(),'#{k}')]"
        doc.xpath(xpath_query, xml_ns).each do |node|
          node.content = v.to_s
        end
      end
      doc
    end

    def replace_uris(doc, old_ids, new_ids)
      id_mapping = {}
      (0..(old_ids.length - 1)).to_a.each do |val|
        id_mapping[old_ids[val]] = new_ids[val]
      end
      replace_with_map(doc, id_mapping)
    end

    def substitute_employer_uri(doc)
      m_ids = []
      doc.xpath("//cv:employer_link/cv:id/cv:id", xml_ns).each do |node|
        id_uri = node.content
        if (id_uri =~ /urn:dc0:terms:v1:employer_names/)
          m_ids << node.content
        end
      end
      all_ids = m_ids.uniq
      return doc if all_ids.length < 1
      replace_map = {}
      all_ids.each do |e_id|
        replace_map[e_id] = UriReference.resolve_uri(e_id)
      end
      replace_with_map(doc, replace_map)
    end

    def generate_member_ids(doc)
      m_ids = []
      doc.xpath("//cv:enrollee/cv:member/cv:id/cv:id", xml_ns).each do |node|
        id_uri = node.content
        if (id_uri =~ /urn:dc0:person:portal_generated_id/)
          m_ids << node.content
        end
      end
      all_ids = m_ids.uniq
      return doc if all_ids.length < 1
      new_ids = ExchangeSequence.generate_identifiers("member_id", all_ids.length)
      replace_uris(doc, all_ids, new_ids.last)
    end

    def generate_policy_ids(doc)
      m_ids = []
      doc.xpath("//cv:policy/cv:id/cv:id", xml_ns).each do |node|
        id_uri = node.content
        if (id_uri =~ /urn:dc0:policy:portal_generated_id/)
          m_ids << node.content
        end
      end
      all_ids = m_ids.uniq
      return doc if all_ids.length < 1
      new_ids = ExchangeSequence.generate_identifiers("policy_id", all_ids.length)
      replace_uris(doc, all_ids, new_ids.last)
    end

    def fail_with_message(enrollment_payload, eg_uri, st, error_code, kind, code)
      publish_properties = {
        :routing_key => "error.events.#{kind}.initial_enrollment",
        :app_id => "hbx_soa.enrollment_submitted_handler",
          :headers => {
          :submitted_timestamp => st,
          :eg_uri => eg_uri,
          :return_status => code,
          :error_code => error_code
        },
        :timestamp => generate_timestamp
      }
      ex = channel.fanout(ExchangeInformation.event_publish_exchange, {:durable => true})
      ex.publish(enrollment_payload, publish_properties)
    end

    def enrollment_invalid(enrollment_payload, code, errors, kind, eg_uri, st)
      fail_with_message(enrollment_payload, eg_uri, st, errors, kind, code)
    end

    def enrollment_valid(enrollment_payload, properties, kind, eg_uri, st)
      publish_properties = {
        :routing_key => "info.events.#{kind}.initial_enrollment",
        :app_id => "hbx_soa.enrollment_submitted_handler",
          :headers => {
          :submitted_timestamp => st,
          :eg_uri => eg_uri,
          :return_status => "202"
        },
        :timestamp => generate_timestamp
      }
      ex = channel.fanout(ExchangeInformation.event_publish_exchange, {:durable => true})
      ex.publish(enrollment_payload, publish_properties)
    end

    def generate_timestamp
      Time.now.to_i
    end

    def validate_enrollment(enrollment_payload, original_headers, pol_props)
      qr_uri = "urn:dc0:terms:v1:qualifying_life_event#initial_enrollment"
      request_props = {
        :routing_key => "enrollment.validate",
        :headers => {
          :qualifying_reason_uri => qr_uri
        }
      }

      di, prop, payload = request(request_props, enrollment_payload, 30)
      return_code = prop.headers["return_status"]
      if "200" != return_code
        throw :fail, FailureResponse.new(enrollment_payload, pol_props.eg_id, pol_props.submitted_timestamp, payload, pol_props.kind, return_code)
      end
    end

    def create_enrollment(enrollment_payload, original_headers, kind, eg_id, st)
      qr_uri = "urn:dc0:terms:v1:qualifying_life_event#initial_enrollment"
      request_props = {
        :routing_key => "enrollment.create",
        :headers => {
          :qualifying_reason_uri => qr_uri
        }
      }

      di, prop, payload = request(request_props, enrollment_payload, 30)
      return_code = prop.headers["return_status"]
      if "200" != return_code
        throw :fail, FailureResponse.new(enrollment_payload, pol_props.eg_id, pol_props.submitted_timestamp, payload, pol_props.kind, return_code)
      end
      enrollment_valid(enrollment_payload, original_headers, kind, eg_id, st)
    end

    def is_shop?(doc)
      !doc.at_xpath("//cv:employer_link/cv:id/cv:id",xml_ns).blank?
    end

    def self.run
      conn = Bunny.new(ExchangeInformation.amqp_uri)
      conn.start
      ch = conn.create_channel
      ch.prefetch(1)
      q = ch.queue(queue_name, :durable => true)

      self.new(ch, q).subscribe(:block => true, :manual_ack => true)
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.enrollment_submitted"
    end

    def self.event_key
      "enrollment.submitted"
    end

  end
end
