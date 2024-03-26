# frozen_string_literal: true

RSpec.describe ServiceActor::Result do
  let(:result) { described_class.new }

  it "defines a method ending with *? suffix for each attribute" do
    result.name = "Sunny"

    expect(result.respond_to?(:name?)).to be true
  end

  describe ".instance_methods" do
    it "stays the same across supported Rubies" do # rubocop:disable RSpec/ExampleLength
      expect(described_class.instance_methods).to contain_exactly(
        :merge!,
        :send,
        :public_send,
        :object_id,
        :delete!,
        :key?,
        :pretty_print,
        :failure?,
        :error,
        :inspect,
        :fail!,
        :class,
        :success?,
        :deconstruct_keys,
        :[]=,
        :[],
        :kind_of?,
        :is_a?,
        :respond_to?,
        :to_h,
        :equal?,
        :!,
        :__send__,
        :==,
        :!=,
        :__binding__,
        :instance_eval,
        :instance_exec,
        :__id__,
        :tap,
        :then,
        :yield_self,
        :block_given?,
        :instance_variables,
      )
    end
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

  describe "#object_id" do
    it "is defined" do
      expect(result.object_id).to be_a(Integer)
    end
  end

  describe "#public_send" do
    it "returns the underlying data" do
      result.name = "Sunny"

      expect(result.public_send(:name)).to eq("Sunny")
    end
  end

  describe "#instance_variables" do
    it "returns the instance variables" do
      expect(result.instance_variables).to eq([:@data])
    end
  end

  describe "#error" do
    it "returns the error key from the data hash" do
      result.error = "Something went wrong"

      expect(result.error).to eq("Something went wrong")
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
