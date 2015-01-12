module Listeners
  class EnrollmentSubmittedHandler < Amqp::Client

    def xml_ns 
      { "cv" => "http://openhbx.org/api/terms/1.0" }
    end

    def on_message(delivery_info, properties, payload)
      parsed_payload = Nokogiri::XML(payload)
      new_payload = substitute_employer_uri(parsed_payload)
      with_m_ids_payload = generate_member_ids(new_payload)
      with_ids_payload = generate_policy_ids(with_m_ids_payload)
      create_enrollment(with_ids_payload.canonicalize, properties.headers.to_hash)
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
      replace_uris(doc, all_ids, new_ids)
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
      replace_uris(doc, all_ids, new_ids)
    end

    def create_enrollment(enrollment_payload, original_headers)
       qr_uri = "urn:dc0:terms:v1:qualifying_life_event#initial_enrollment"
       request_props = {
         :routing_key => "enrollment.create",
         :headers => {
           :qualifying_reason_uri => qr_uri
         }
       }

       di, prop, payload = request(request_props, enrollment_payload, 30)
       return_code = prop.headers["return_status"]
       case return_code
       when "200"
       else
        channel.direct(ExchangeInformation.request_exchange, {:durable => true}).publish(
          payload,
          {
            :routing_key => "enrollment.error",
            :headers => original_headers.merge({:return_status => return_code})
          }
        )
      end
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
