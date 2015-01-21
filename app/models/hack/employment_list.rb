require 'csv'

module Hack
  class EmploymentList
    include Singleton
    EARLIEST_ENROLLMENT = Date.new(2015, 1, 1)

    def initialize
      @employments = []
      parse_file(File.join(Padrino.root, "config/employee_roster.csv"))
    end

    def parse_file(file)
      CSV.foreach(file, headers: true) do |row|
        @employments << ::Hack::Employment.new(row.to_hash)
      end
    end

    def match(other_fein, other_ssn)
      matched = @employments.select { |empl| empl.match?(other_fein, other_ssn) }
      matched.sort_by(&:start_date).last
    end

    def self.match(other_fein, other_ssn)
      self.instance.match(other_fein, other_ssn)
    end
  end
end
