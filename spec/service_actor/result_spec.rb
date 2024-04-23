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
        :__binding__,
        :__id__,
        :__send__,
        :!,
        :!=,
        :[],
        :[]=,
        :==,
        :block_given?,
        :class,
        :deconstruct_keys,
        :delete!,
        :equal?,
        :error,
        :fail!,
        :failure?,
        :inspect,
        :instance_eval,
        :instance_exec,
        :instance_variables,
        :is_a?,
        :key?,
        :kind_of?,
        :merge!,
        :nil?,
        :object_id,
        :pretty_print,
        :public_send,
        :respond_to?,
        :send,
        :success?,
        :tap,
        :then,
        :to_h,
        :yield_self,
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

  describe "#success?" do
    it "returns true if the result is not a failure" do
      expect(result).to be_a_success
    end

    it "returns false after a failure" do
      expect { result.fail! }.to raise_error(ServiceActor::Failure)

      expect(result).not_to be_a_success
    end
  end

  describe "#failure?" do
    it "returns false if the result is not a failure" do
      expect(result).not_to be_a_failure
    end

    it "returns true after a failure" do
      expect { result.fail! }.to raise_error(ServiceActor::Failure)

      expect(result).to be_a_failure
    end

    it "returns true when setting failure" do
      result = described_class.new(failure: true)

      expect(result).to be_a_failure
    end

    it "returns true when setting a failure with a question mark" do
      result = described_class.new(failure?: true)

      expect(result).to be_a_failure
    end
  end
end
