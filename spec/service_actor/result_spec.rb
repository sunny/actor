# frozen_string_literal: true

RSpec.describe ServiceActor::Result do
  let(:result) { described_class.new }

  it "defines a method ending with *? suffix for each attribute" do
    result.name = "Sunny"

    expect(result.respond_to?(:name?)).to be true
  end

  it "has indifferent access" do
    result.name = "Sunny"

    expect(result[:name]).to eq("Sunny")
    expect(result["name"]).to eq("Sunny")
  end

  describe ".instance_methods" do
    let(:expected_methods) do
      [
        :__binding__,
        :__id__,
        :__send__,
        :!,
        :!=,
        :[],
        :[]=,
        :==,
        :blank?,
        :block_given?,
        :class,
        :deconstruct_keys,
        :delete!,
        :equal?,
        :error,
        :fail!,
        :failure?,
        :hash,
        :inspect,
        :instance_eval,
        :instance_exec,
        :instance_of?,
        :instance_variables,
        :is_a?,
        :key?,
        :kind_of?,
        :merge!,
        :method,
        :methods,
        :nil?,
        :object_id,
        :pretty_print,
        :private_methods,
        :public_send,
        :respond_to?,
        :send,
        :success?,
        :tap,
        :then,
        :to_h,
        :yield_self,
      ]
    end

    it "stays the same across supported Rubies" do
      expect(described_class.instance_methods)
        .to match_array(expected_methods)
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
    it "returns false" do
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

  describe "#pretty_print" do
    context "without nested attributes" do
      it "correctly pretty prints the result" do
        expect(PP.pp(result, +"")).to eq("#<ServiceActor::Result {}>\n")
      end
    end

    context "with nested attributes" do
      let(:result) { described_class.new(a: 1, b: "hello") }

      # Test for the new hash syntax introduced in Ruby 3.4.0dev
      let(:new_pp_ruby_syntax?) { PP.pp({hash: "test"}, +"").include?("hash:") }

      let(:expected_result) do
        if new_pp_ruby_syntax?
          "#<ServiceActor::Result {a: 1, b: \"hello\"}>\n"
        else
          "#<ServiceActor::Result {:a=>1, :b=>\"hello\"}>\n"
        end
      end

      it "correctly pretty prints the result" do
        expect(PP.pp(result, +"")).to eq(expected_result)
      end
    end
  end
end
