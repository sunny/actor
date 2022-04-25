# frozen_string_literal: true

RSpec.describe ServiceActor::Result do
  it "defines a method ending with *? suffix for each attribute" do
    result = described_class.new
    result.name = "Sunny"

    expect(result.respond_to?(:name?)).to eq true
  end

  context "when input is String" do
    context "when is empty" do
      it "returns false" do
        result = described_class.new
        result.name = ""

        expect(result.name?).to eq false
      end
    end

    context "when is not empty" do
      it "returns true" do
        result = described_class.new
        result.name = "Actor"

        expect(result.name?).to eq true
      end
    end
  end

  context "when input is Array" do
    context "when is empty" do
      it "returns false" do
        result = described_class.new
        result.array = []

        expect(result.array?).to eq false
      end
    end

    context "when is not empty" do
      it "returns true" do
        result = described_class.new
        result.array = [1, 2, 3]

        expect(result.array?).to eq true
      end
    end
  end

  context "when input is Hash" do
    context "when empty" do
      it "returns false" do
        result = described_class.new
        result.hash = {}

        expect(result.hash?).to eq false
      end
    end

    context "when not empty" do
      it "returns true" do
        result = described_class.new
        result.hash = { name: "Actor" }

        expect(result.hash?).to eq true
      end
    end
  end

  context "when input is NilClass" do
    it "returns false" do
      result = described_class.new
      result.name = nil

      expect(result.name?).to eq false
    end
  end

  context "when input is TrueClass" do
    it "returns true" do
      result = described_class.new
      result.name = true

      expect(result.name?).to eq true
    end
  end

  context "when input is FalseClass" do
    it "returns true" do
      result = described_class.new
      result.name = false

      expect(result.name?).to eq false
    end
  end
end
