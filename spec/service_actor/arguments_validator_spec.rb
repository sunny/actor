# frozen_string_literal: true

RSpec.describe ServiceActor::ArgumentsValidator do
  describe ".validate_origin_name" do
    it "raises on name collision" do
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

  describe ".validate_default_value" do
    include_context "with mocked `Kernel.warn` method"

    [[], {}, {a: 1}, {a: []}.freeze, Struct.new(:a).new].each do |mutable_value|
      context "when `Ractor` API is supported" do
        it "emits a warning if default value `#{mutable_value}` is mutable" do
          described_class.validate_default_value(mutable_value, origin_type: :input, origin_name: :value, actor: "actor_name")

          if engine_mri?
            expect(Kernel).to have_received(:warn)
              .with("DEPRECATED: Actor `actor_name` has input `value` with default which is not a Proc or an immutable object.")
              .once
          else
            expect(Kernel).not_to have_received(:warn)
          end
        end
      end

      context "when `Ractor` API is not supported" do
        before { hide_const("Ractor") }

        it "does not emit a warning" do
          described_class.validate_default_value(mutable_value, origin_type: :input, origin_name: :value, actor: "actor_name")

          expect(Kernel).not_to have_received(:warn)
        end
      end
    end

    [[].freeze, {}.freeze, {a: 1}.freeze, {a: [].freeze}.freeze, Struct.new(:a).new.freeze].each do |immutable_value|
      it "does not emit a warning if default value `#{immutable_value}` is immutable" do
        described_class.validate_default_value(immutable_value, origin_type: :input, origin_name: :value, actor: "actor_name")

        expect(Kernel).not_to have_received(:warn)
      end
    end

    it "does not emit a warning for a lambda default" do
      described_class.validate_default_value(-> {}, origin_type: :input, origin_name: :value, actor: "actor_name")
      described_class.validate_default_value(-> a { a }, origin_type: :input, origin_name: :value, actor: "actor_name")

      expect(Kernel).not_to have_received(:warn)
    end
  end
end
