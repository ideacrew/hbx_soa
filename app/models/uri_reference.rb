class UriReference < Ohm::Model
  attribute :reference
  index :reference

  attribute :resolved_uri

  def self.resolve_uri(ref)
    resolved = self.find(reference: ref).first
    return nil unless resolved
    resolved.resolved_uri
  end
end
