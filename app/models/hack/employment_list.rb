require 'csv'

module Hack
  class EmploymentList
    include Singleton

    def initialize
      @employments = []
      parse_file(File.join(Padrino.root, "config/employee_roster.csv"))
    end

    def parse_file(file)
      CSV.foreach(file, headers: true) do |row|
        @employments << ::Hack::Employment.new(row.to_hash)
      end
    end

    def match(other_fein, other_ssn, coverage_start)
      @employments.detect { |empl| empl.match?(other_fein, other_ssn, coverage_start) }
    end

    def self.match(other_fein, other_ssn, coverage_start)
      self.instance.match(other_fein, other_ssn, coverage_start)
    end
  end
end
