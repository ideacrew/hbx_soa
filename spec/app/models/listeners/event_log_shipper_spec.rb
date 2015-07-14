require 'spec_helper'

describe Listeners::EventLogShipper do
  let(:mock_channel) { double }
  let(:mock_queue) { double }

  subject { Listeners::EventLogShipper.new(mock_channel, mock_queue) }

  describe "give a message with only a timestamp" do
    let(:timestamp_value) { Time.mktime(2014, 5, 25, 0, 5, 21) }
    let(:properties_hash) { { :timestamp => timestamp_value } }

    it "should use the timestamp to construct the time" do
      expect(subject.extract_time_value(properties_hash)).to eq timestamp_value
    end
  end

  describe "given a message with both submitted_at and a timestamp" do
    let(:submitted_timestamp_value) { Time.utc(2014, 6, 23, 10, 59, 56) }
    let(:timestamp_value) { Time.mktime(2014, 5, 25, 0, 5, 21) }
    let(:properties_hash) { { :timestamp => timestamp_value, :headers => {
      :submitted_timestamp => "20140623105956"
    } } }

    it "should use the submitted_at to construct the time" do
      expect(subject.extract_time_value(properties_hash)).to eq submitted_timestamp_value
    end
  end

  describe "given neither a timestamp nor a submitted at" do
    let(:mock_time) { Time.mktime(2013, 2, 15, 10, 22, 15) }
    let(:properties_hash) { { } }

    it "should use Time.now for the time" do
      allow(Time).to receive(:now).and_return(mock_time)
      expect(subject.extract_time_value(properties_hash)).to eq mock_time
    end
  end

end

describe Listeners::EventLogShipper, "creating a gelf hash" do
  let(:mock_channel) { double }
  let(:mock_queue) { double }
  let(:mock_delivery_info) { double(:routing_key => "info.events.some_service.message") }
  let(:mock_properties) { double(properties_hash.merge({:to_hash => properties_hash})) }
  let(:mock_headers) { {} }
  let(:properties_hash) { { :headers => mock_headers } }

  subject { Listeners::EventLogShipper.new(mock_channel, mock_queue) }

  it "should get the facility from the second part of the routing key" do
    expect(subject.extract_gelf_hash(mock_delivery_info, mock_properties)[:facility]).to eq "events"
  end

  it "should get the level from the first part of the routing key" do
    expect(subject.extract_gelf_hash(mock_delivery_info, mock_properties)[:level]).to eq 6
  end

  it "should use the rest of the routing key as the message" do
    expect(subject.extract_gelf_hash(mock_delivery_info, mock_properties)[:short_message]).to eq "some_service.message"
  end


  describe "given a message with a custom key in the properties" do
    let(:custom_key_value) { "some app id" }
    let(:mock_headers) { {} }
    let(:properties_hash) { { :headers => mock_headers, :app_id => custom_key_value } }

    it "should include that key in the hash with an underscore" do
      expect(subject.extract_gelf_hash(mock_delivery_info, mock_properties)["_app_id"]).to eq custom_key_value
    end
  end

  describe "given a message with a custom key in the headers" do
    let(:custom_key_value) { "some app id" }
    let(:mock_headers) { {:app_id => custom_key_value } }
    let(:properties_hash) { { :headers => mock_headers } }

    it "should include that key in the hash with an underscore" do
      expect(subject.extract_gelf_hash(mock_delivery_info, mock_properties)["_app_id"]).to eq custom_key_value
    end
  end
end
