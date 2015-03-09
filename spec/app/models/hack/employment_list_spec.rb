require 'spec_helper'

describe Hack::EmploymentList do
  describe "with no end date" do
    subject {
      en_spec = Hack::EmploymentList.class_eval("allocate")
      en_spec.instance_variable_set("@employments", employments)
      en_spec
    }

    let(:employment1) {
      double(:match? => true, :start_date => Date.new(2014,12,15))
    }

    let(:employment2) {
      double(:match? => true, :start_date => Date.new(2014,12,14))
    }

    let(:employments) {
      [employment1, employment2]
    }

    it "should match the most recent employment when multiples are matched" do
      expect(subject.match("123456789", "987654321","20120102")).to eq(employment1)
    end
  end
end
