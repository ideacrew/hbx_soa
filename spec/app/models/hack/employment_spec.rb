require 'spec_helper'

describe Hack::Employment do
  describe "with no end date" do
    subject {
      Hack::Employment.new({
        :fein => "123456789",
        :ssn => "987654321",
        :start_date => "20141215",
        :dob => "20120102"
      }) 
    }

    it "should not match a missing fein" do
      expect(subject.match?("asdfdf", nil)).to be_falsey
    end

    it "should not match a missing ssn" do
      expect(subject.match?("123456789", "asdvbe")).to be_falsey
    end
  end
end
