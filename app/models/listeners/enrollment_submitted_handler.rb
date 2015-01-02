module Listeners
  class EnrollmentSubmittedHandler

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.enrollment_submitted"
    end

    def self.event_key
      "enrollment.submitted"
    end

  end
end
