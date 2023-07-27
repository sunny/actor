# frozen_string_literal: true

RSpec.describe ServiceActor::Result do
  let(:result) { described_class.new }

  it "defines a method ending with *? suffix for each attribute" do
    result.name = "Sunny"

    expect(result.respond_to?(:name?)).to be true
  end

  context "when input is String" do
    context "when is empty" do
      it "returns false" do
        result.name = ""

        expect(result.name?).to be false
      end
    end

    context "when is not empty" do
      it "returns true" do
        result.name = "Actor"

        expect(result.name?).to be true
      end
    end
  end

  context "when input is Array" do
    context "when is empty" do
      it "returns false" do
        result.options = []

        expect(result.options?).to be false
      end
    end

    context "when is not empty" do
      it "returns true" do
        result.options = [1, 2, 3]

        expect(result.options?).to be true
      end
    end
  end

  context "when input is Hash" do
    context "when empty" do
      it "returns false" do
        result.options = {}

        expect(result.options?).to be false
      end
    end

    context "when not empty" do
      it "returns true" do
        result.options = {name: "Actor"}

        expect(result.options?).to be true
      end
    end
  end

  context "when input is NilClass" do
    it "returns false" do
      result.name = nil

      expect(result.name?).to be false
    end
  end

  context "when input is TrueClass" do
    it "returns true" do
      result.name = true

      expect(result.name?).to be true
    end
  end

  context "when input is FalseClass" do
    it "returns true" do
      result.name = false

      expect(result.name?).to be false
    end
  end

  describe "#fail!" do
    it "merges the hash into the result and marks the result as failed" do
      expect { result.fail!(name: "Sunny") }
        .to raise_error(ServiceActor::Failure)

      expect(result.name).to eq("Sunny")
      expect(result).to be_a_failure
    end

    context "with no arguments" do
      it "raises and marks the result as failed" do
        expect { result.fail! }.to raise_error(ServiceActor::Failure)

        expect(result).to be_a_failure
      end
    end
  end
end
