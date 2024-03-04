# frozen_string_literal: true

RSpec.describe ServiceActor::ArgumentsValidator do
  describe ".validate_origin_name" do
    let(:expected_error_message) do
      <<~TXT
        Defined input `to_s` collides with `ServiceActor::Result` instance method
      TXT
    end

    it "raises if collision present" do
      expect { described_class.validate_origin_name(:to_s, origin: :input) }
        .to raise_error(ArgumentError, expected_error_message)
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
