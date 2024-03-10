# frozen_string_literal: true

RSpec.describe ServiceActor::ArgumentsValidator do
  describe ".validate_origin_name" do
    it "raises if collision present" do # rubocop:disable RSpec/ExampleLength
      expect do
        described_class.validate_origin_name(:fail!, origin: :input)
      end.to raise_error(
        ArgumentError,
        "input `fail!` overrides `ServiceActor::Result` instance method",
      )
    end

    it do
      expect do
        described_class.validate_origin_name(:some_method, origin: :output)
      end.not_to raise_error
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
