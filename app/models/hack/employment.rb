module Hack
  class Employment
    include Virtus.model

    attribute :fein, String
    attribute :ssn, String
    attribute :start_date, Date
    attribute :end_date, Date

    def match?(other_fein, other_ssn)
      return false unless fein == other_fein
      ssn == other_ssn
    end
  end
end
