sequence_names = %w(
e_case_id
organization_id
policy_id
member_id
irs_group_id
)

sequence_names.each do |sn|
  ExchangeSequence.create(name: sn.strip, last_used: 1)
end
