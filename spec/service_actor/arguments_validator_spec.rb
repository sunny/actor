# frozen_string_literal: true

RSpec.describe ServiceActor::ArgumentsValidator do
  describe ".validate_origin_name" do
    before { allow(Kernel).to receive(:warn).with(kind_of(String)) }

    it "raises if collision present" do
      described_class.validate_origin_name(:fail!, origin: :input)

      expect(Kernel).to have_received(:warn)
        .with(/DEPRECATED: Defining inputs, .* input: `fail!`/)
        .once
    end

    it do
      described_class.validate_origin_name(:some_method, origin: :output)

      expect(Kernel).not_to have_received(:warn)
    end
  end

  describe ".validate_error_class" do
    it "with an exception class" do
      expect { described_class.validate_error_class(ArgumentError) }
        .not_to raise_error
    end

    it "with a non-class object" do
      expect { described_class.validate_error_class("123") }
        .to raise_error(
          ArgumentError,
          "Expected 123 to be a subclass of Exception",
        )
    end

    it "with a non-exception class" do
      expect { described_class.validate_error_class(Class.new) }
        .to raise_error(
          ArgumentError,
          /Expected .+ to be a subclass of Exception/,
        )
    end
  end
end
