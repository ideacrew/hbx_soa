module Hack
  class Employment
    include Virtus.model

    attribute :fein, String
    attribute :ssn, String
    attribute :start_date, Date
    attribute :end_date, Date

    def match?(other_fein, other_ssn, coverage_start)
      return false unless fein == other_fein
      return false unless ssn == other_ssn
      coverage_begin_date = Date.strptime(coverage_start, "%Y%m%d")
      if end_date.blank?
        (coverage_begin_date >= start_date)
      else
        (coverage_begin_date >= start_date) && (coverage_begin_date <= end_date)
      end
    end
  end
end
