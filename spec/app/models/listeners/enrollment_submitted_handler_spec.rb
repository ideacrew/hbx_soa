require 'spec_helper'

describe Listeners::EnrollmentSubmittedHandler do
  let(:xml_ns) { { "cv" => "http://openhbx.org/api/terms/1.0" } }
  let(:listener) { Listeners::EnrollmentSubmittedHandler.new(nil, nil) }

  describe "which finds coverage elements" do
    let(:input_xml) { f = File.open(File.join(Padrino.root, "spec/data/submitted_enrollment.xml")); Nokogiri::XML(f) }

    it "should provide the correct coverage elements" do
       allow(UriReference).to receive(:resolve_uri).with("urn:dc0:terms:v1:employer_names#senate").and_return("some_id")
       doc = listener.substitute_employer_uri(input_xml)
       e_elements = listener.get_employment_eligibility_elements(doc)
       expect(e_elements).to eq ["some_id","112233445","20150101"]
    end
  end

  describe "which has a matching employment" do
    let(:enrollment_match) { instance_double("Hack::Employment", :start_date => Date.new(2015, 1, 15) ) }

    let(:input_xml) { f = File.open(File.join(Padrino.root, "spec/data/submitted_enrollment.xml")); Nokogiri::XML(f) }

    it "should provide the correct coverage date" do
      result = listener.fix_start_dates(input_xml, enrollment_match)
      expect(result.at_xpath("//cv:enrollee[contains(cv:is_subscriber, 'true')]/cv:benefit/cv:begin_date[text()='20150201']",xml_ns).blank?).to be_falsey
    end 
  end

  describe "which replaces member ids" do
    let(:input_xml) { f = File.open(File.join(Padrino.root, "spec/data/submitted_enrollment.xml")); Nokogiri::XML(f) }

    it "should replace the member ids" do
       allow(ExchangeSequence).to receive(:generate_identifiers).with("member_id", 1).and_return([1])
       result = listener.generate_member_ids(input_xml)
       portal_member_ids = result.xpath("//*[contains(., 'urn:dc0:person:portal_generated_id')]").any?
       expect(portal_member_ids).to be_falsey
    end
  end

  describe "which replaces policy ids" do
    let(:input_xml) { f = File.open(File.join(Padrino.root, "spec/data/submitted_enrollment.xml")); Nokogiri::XML(f) }

    it "should replace the policy ids" do
       allow(ExchangeSequence).to receive(:generate_identifiers).with("policy_id", 1).and_return([1])
       result = listener.generate_policy_ids(input_xml)
       portal_member_ids = result.xpath("//*[contains(., 'urn:dc0:policy:portal_generated_id')]").any?
       expect(portal_member_ids).to be_falsey
    end
  end

  describe "which replaces employer ids" do
    let(:input_xml) { f = File.open(File.join(Padrino.root, "spec/data/submitted_enrollment.xml")); Nokogiri::XML(f) }

    it "should replace the employer ids" do
       allow(UriReference).to receive(:resolve_uri).with("urn:dc0:terms:v1:employer_names#senate").and_return("some_id")
       result = listener.substitute_employer_uri(input_xml)
       portal_member_ids = result.xpath("//*[contains(., 'urn:dc0:terms:v1:employer_names#senate')]").any?
       expect(portal_member_ids).to be_falsey
    end
  end

end
