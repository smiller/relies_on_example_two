require "service"

RSpec.describe "with requirement" do

  subject { Service.new.my_hounds }

  context "my_hounds" do
    describe "keys in response" do
      # @REQUIREMENT: my_hounds includes :breeding_stock
      it "includes :breeding_stock" do
        expect(subject).to include_key(:breeding_stock, "my_hounds includes :breeding_stock")
      end

      # @REQUIREMENT: my_hounds includes :traits
      it "includes :traits" do
        expect(subject).to include_key(:traits, "my_hounds includes :traits")
      end
    end
  end

  context "using my_hounds" do
    describe "for one thing" do
      # @RELIES_ON: my_hounds includes :breeding_stock
      it "does something with :breeding_stock" do
        expect(subject[:breeding_stock]).to eq("Spartan")
      end

      # @RELIES_ON: my_hounds includes :traits
      it "does something with :traits" do
        expect(subject[:traits][:flewed_as]).to eq("Spartan")
      end
    end

    describe "for another thing" do
      # @RELIES_ON: my_hounds includes :breeding_stock
      it "checks something else" do
        expect(subject[:breeding_stock]).not_to eq("Athenian")
      end
    end
  end
end
