require "spec_helper"

describe ExchangeSequence do
  describe "asked to provide a list of ids" do
    let(:subject) { ExchangeSequence.new(last_used: last_used, name: sequence_name) }
    let(:redis) { double("redis") }
    let(:last_used) { 5 }
    let(:sequence_name) { "test_sequence" }
    let(:subject_key) { "ExchangeSequence:#{sequence_name}" }

    before :each do
      allow(subject).to receive(:redis).and_return(redis)
      allow(subject).to receive(:key).and_return(subject_key)
      allow(redis).to receive(:call).with("HINCRBY",subject_key, :last_used, requested_size).and_return(new_last_used)
      allow(ExchangeSequence).to receive(:find).with(name: sequence_name).and_return([subject])
    end

    describe "asked for 5 ids with simultaneous requests where last_used will be innacurate" do

      let(:new_last_used) { 13 }
      let(:requested_size) { 5 }

      it "returns the correct sequence numbers from .generate_identifiers" do
        returned_sequence, values = ExchangeSequence.generate_identifiers(sequence_name, 5)
        expect(values).to eq [9, 10, 11, 12, 13]
      end

      it "returns the correct sequence from .generate_identifiers" do
        returned_sequence, values = ExchangeSequence.generate_identifiers(sequence_name, 5)
        expect(returned_sequence).to eq subject
      end

    end
  end
end
