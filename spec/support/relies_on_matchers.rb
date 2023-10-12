module ReliesOnMatchers
  extend RSpec::Matchers::DSL

  matcher :include_key do |key, requirement|
    match { |hash| hash.include?(key) }

    failure_message do
      "expected #{actual.keys} to include key #{key}, but it didn't\n- #{actual}\n#{relies_on_message(requirement)}"
    end

    failure_message_when_negated do
      "expected #{actual.keys} not to include key #{key}, but it did\n- #{actual}\n#{relies_on_message(requirement)}"
    end
  end

  def relies_on_message(requirement)
    relies_on = RSpec.configuration.relies_on.fetch(requirement, [])
    if relies_on.any?
      "\nOther specs relying on requirement '#{requirement}':\n- #{relies_on.join("\n- ")}"
    else
      ""
    end
  end
end
