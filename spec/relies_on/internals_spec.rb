RSpec.describe "relies_on internals" do

  context "using '@REQUIREMENT: ' and '@RELIES_ON: '" do
    describe "@REQUIREMENT: " do
      # @REQUIREMENT: my_hounds includes :breeding_stock
      it "includes :breeding_stock" do
        expect(Service.my_hounds).to include_key(:breeding_stock, read_requirement(__FILE__, __LINE__ - 2))
      end

      # @REQUIREMENT: my_hounds includes :traits
      it "includes :traits" do
        expect(Service.my_hounds).to include_key(:traits, read_requirement(__FILE__, __LINE__ - 2))
      end
    end

    describe "@RELIES_ON: " do
      # @RELIES_ON: my_hounds includes :breeding_stock
      it "does something with :breeding_stock" do
        expect(Service.my_hounds[:breeding_stock]).to eq("Spartan")
      end

      # @RELIES_ON: my_hounds includes :traits
      it "does something with :traits" do
        expect(Service.my_hounds[:traits][:flewed_as]).to eq("Spartan")
      end

      # @RELIES_ON: my_hounds includes :breeding_stock
      it "does something else with :breeding_stock" do
        expect(Service.my_hounds[:breeding_stock]).not_to eq("Athenian")
      end
    end
  end

  context "wrong arguments to #read_requirement: line pointed at doesn't include requirement" do
    # @REQUIREMENT: for unhappy_path test
    it "raises error with helpful message" do
      expect {
        read_requirement(__FILE__, __LINE__ - 5)
      }.to raise_error("requirement expected but not found at file ./spec/relies_on/internals_spec.rb line 33")
    end
  end

  context "#relies_on_message" do
    it "for :breeding_stock" do
      expect(relies_on_message("my_hounds includes :breeding_stock")).to include("Other specs relying on requirement 'my_hounds includes :breeding_stock':",
         "- https://github.com/smiller/relies_on_example_two/blob/main/spec/relies_on/internals_spec.rb#L17",
         "- https://github.com/smiller/relies_on_example_two/blob/main/spec/relies_on/internals_spec.rb#L27\n",
         "- https://github.com/smiller/relies_on_example_two_related_repo/blob/main/spec/relies_on_related_repo_spec.rb#L3")
    end

    it "for :traits" do
      expect(relies_on_message("my_hounds includes :traits")).to include(
        "Other specs relying on requirement 'my_hounds includes :traits':",
        "- https://github.com/smiller/relies_on_example_two/blob/main/spec/relies_on/internals_spec.rb#L22")
    end

    it "for a requirement nothing relies on yet" do
      expect(relies_on_message("but nothing relies on this requirement yet")).to eq("")
    end
  end

  # This is the internal spec using the internal repos list, so we can test both happy and unhappy paths.
  # The validate_labels_match_spec is intended to be added to the repo using relies_on and to test
  # that project's repos list, so it should pass, or there's a problem.
  context "ensure all @RELIES_ON labels in this repo match a @REQUIREMENT label in this or another repo" do
    describe "unhappy path (inserts an extra unmatched relies_on)" do
      # @RELIES_ON: <repo:relies_on_example_two_related_repo> A requirement in a related repo
      it "fails" do
        relies_ons = retrieve_relies_ons
        relies_ons << "this is a made-up relies_on and should fail"
        matched_relies_ons = match_requirements_to_relies_ons(relies_ons)
        expect(matched_relies_ons.values.uniq).to eq([true, false])
      end
    end

    describe "happy path" do
      # @RELIES_ON: <repo:relies_on_example_two_related_repo> A requirement in a related repo
      it "succeeds" do
        relies_ons = retrieve_relies_ons
        matched_relies_ons = match_requirements_to_relies_ons(relies_ons)
        expect(matched_relies_ons.values.uniq).to eq([true])
      end
    end
  end
end

class Service
  def self.my_hounds
    {
      breeding_stock: "Spartan",
      traits: {
        flewed_as: "Spartan",
        sanded_as: "Spartan"
      }
    }
  end
end
