require 'spec_helper'

describe Hack::Employment do
  describe "with no end date" do
    subject {
      Hack::Employment.new({
        :fein => "123456789",
        :ssn => "987654321",
        :start_date => "20141215",
      }) 
    }

    it "should not match a missing fein" do
      expect(subject.match?("asdfdf", nil, nil)).to be_falsey
    end

    it "should not match a missing ssn" do
      expect(subject.match?("123456789", "asdvbe", nil)).to be_falsey
    end

    it "should not match a coverage date before the hire date" do
      expect(subject.match?("123456789", "987654321", "20141210")).to be_falsey
      expect(subject.match?("123456789", "987654321", "20141214")).to be_falsey
    end

    it "should match a coverage date after or on the hire date" do
      expect(subject.match?("123456789", "987654321", "20141215")).to be_truthy
      expect(subject.match?("123456789", "987654321", "20150120")).to be_truthy
    end
  end
end
