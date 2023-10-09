RSpec::Matchers.define :include_key do |key, requirement|
  match { |hash| hash.include?(key) }

  failure_message do
    "expected #{actual.keys} to include key #{key}, but it didn't\n- #{actual}\n#{relies_on_message(requirement)}"
  end

  failure_message_when_negated do
    "expected #{actual.keys} not to include key #{key}, but it did\n- #{actual}\n#{relies_on_message(requirement)}"
  end
end
