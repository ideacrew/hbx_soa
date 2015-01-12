require 'spec_helper'

describe Listeners::EnrollmentSubmittedHandler do
  let(:xml_ns) { { "cv" => "http://openhbx.org/api/terms/1.0" } }
  let(:listener) { Listeners::EnrollmentSubmittedHandler.new(nil, nil) }

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
