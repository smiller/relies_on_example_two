RSpec.describe "Match @RELIES_ON labels in this repo against a @REQUIREMENT in this or a related repo" do
  it "ensure each @RELIES_ON has a matching @REQUIREMENT" do
    relies_ons = retrieve_relies_ons
    matched_relies_ons = match_requirements_to_relies_ons(relies_ons)
    unmatched = matched_relies_ons.select { |_, v| v == false }.keys
    expect(matched_relies_ons.values.uniq).to eq([true]), "@RELIES_ON labels without match a matching @REQUIREMENT label: #{unmatched}"
  end
end
