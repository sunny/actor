# frozen_string_literal: true

RSpec.describe ServiceActor::Result do
  it "defines a method ending with *? suffix for each attribute" do
    result = described_class.new
    result.name = "Sunny"

    expect(result.respond_to?(:name?)).to be true
  end

  context "when input is String" do
    context "when is empty" do
      it "returns false" do
        result = described_class.new
        result.name = ""

        expect(result.name?).to be false
      end
    end

    context "when is not empty" do
      it "returns true" do
        result = described_class.new
        result.name = "Actor"

        expect(result.name?).to be true
      end
    end
  end

  context "when input is Array" do
    context "when is empty" do
      it "returns false" do
        result = described_class.new
        result.options = []

        expect(result.options?).to be false
      end
    end

    context "when is not empty" do
      it "returns true" do
        result = described_class.new
        result.options = [1, 2, 3]

        expect(result.options?).to be true
      end
    end
  end

  context "when input is Hash" do
    context "when empty" do
      it "returns false" do
        result = described_class.new
        result.options = {}

        expect(result.options?).to be false
      end
    end

    context "when not empty" do
      it "returns true" do
        result = described_class.new
        result.options = { name: "Actor" }

        expect(result.options?).to be true
      end
    end
  end

  context "when input is NilClass" do
    it "returns false" do
      result = described_class.new
      result.name = nil

      expect(result.name?).to be false
    end
  end

  context "when input is TrueClass" do
    it "returns true" do
      result = described_class.new
      result.name = true

      expect(result.name?).to be true
    end
  end

  context "when input is FalseClass" do
    it "returns true" do
      result = described_class.new
      result.name = false

      expect(result.name?).to be false
    end
  end
end
