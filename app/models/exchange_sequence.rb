class ExchangeSequence < Ohm::Model
  attribute :name
  index :name

  attribute :last_used

  def self.generate_identifiers(sequence_name, count = 1)
    count_value = count || 1
    sequence = self.find(name: sequence_name).first
    return nil unless sequence
    old_val = sequence.last_used.to_i
    new_val = sequence.incr_attribute(:last_used, count_value)
    all_vals = ((old_val + 1)..new_val).to_a
    [sequence, all_vals]
  end

  def incr_attribute(att, count = 1)
    redis.call("HINCRBY", key, att, count)
  end
end
