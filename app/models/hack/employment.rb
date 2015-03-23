module Hack
  class Employment
    include Virtus.model

    attribute :fein, String
    attribute :ssn, String
    attribute :start_date, Date
    attribute :end_date, Date
    attribute :dob, Date

    def match?(other_fein, other_ssn, other_dob)
      return false unless fein == other_fein
      ssn == other_ssn && dob == other_dob
    end

    def dob=(val)
      if val.kind_of?(Date)
        super val
      else
        super Date.strptime(val.to_s, "%Y%m%d")
      end
    end

    def start_date=(val)
      if val.kind_of?(Date)
        super val
      else
        super Date.strptime(val.to_s, "%Y%m%d")
      end
    end

    def end_date=(val)
      unless val.blank?
        if val.kind_of?(Date)
          super val
        else
          super Date.strptime(val.to_s, "%Y%m%d")
        end
      end
    end
  end
end
