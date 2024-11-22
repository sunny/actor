# frozen_string_literal: true

CustomArgumentError = Class.new(StandardError)

class CustomFailureError < StandardError
  attr_reader :result

  def initialize(result)
    @result = result

    super("Custom failure")
  end
end

RSpec.describe Actor do
  shared_context "with mocked `Kernel.warn` method" do
    before { allow(Kernel).to receive(:warn).with(kind_of(String)) }
  end

  describe "#call" do
    context "when fail! is not called" do
      let(:actor) { DoNothing.call }

      it { expect(actor).to be_a(ServiceActor::Result) }
      it { expect(actor).to be_a_success }
      it { expect(actor).not_to be_a_failure }
    end

    context "when fail! is called" do
      it "raises the error message" do
        expect { FailWithError.call }
          .to raise_error(ServiceActor::Failure, "Ouch")
      end

      context "when a custom class is specified" do
        it "raises the error message" do
          expect { FailWithErrorWithCustomFailureClass.call }
            .to raise_error(MyCustomFailure, "Ouch")
        end
      end
    end

    context "when an actor updates the context" do
      it "returns the context with the change" do
        actor = AddNameToContext.call
        expect(actor.name).to eq("Jim")
      end
    end

    context "when an actor updates the context with a hash" do
      it "returns the hash with the change" do
        actor = AddHashToContext.call
        expect(actor.stuff).to eq(name: "Jim")
      end
    end

    context "when an actor uses a method named after the input" do
      it "returns what is in the context" do
        actor = SetNameToDowncase.call(name: "JIM")
        expect(actor.name).to eq("jim")
      end
    end

    context "when given a context instead of a hash" do
      it "returns the same context" do
        actor = ServiceActor::Result.new(name: "Jim")

        expect(AddNameToContext.call(actor)).to eq(actor)
      end

      it "can update the given context" do
        actor = ServiceActor::Result.new(name: "Jim")

        SetNameToDowncase.call(actor)

        expect(actor.name).to eq("jim")
      end
    end

    context "when given a hash with string keys" do
      it "accepts them" do
        actor = SetNameToDowncase.call({"name" => "Jim"})

        expect(actor.name).to eq("jim")
      end

      it "accepts implicit hashes" do
        actor = SetNameToDowncase.call("name" => "ImplicitJim")

        expect(actor.name).to eq("implicitjim")
      end

      it "accepts splatted hashes" do
        actor = SetNameToDowncase.call(**{"name" => "SplattedJim"})

        expect(actor.name).to eq("splattedjim")
      end
    end

    context "when an actor changes a value" do
      it "returns a context with the updated value" do
        actor = IncrementValue.call(value: 1)
        expect(actor.value).to eq(2)
      end
    end

    context "when an input has a default" do
      it "adds it to the context" do
        actor = AddGreetingWithDefault.call
        expect(actor.name).to eq("world")
      end

      it "can use it" do
        actor = AddGreetingWithDefault.call
        expect(actor.greeting).to eq("Hello, world!")
      end

      it "is overridden by values added to call" do
        actor = AddGreetingWithDefault.call(name: "jim")
        expect(actor.name).to eq("jim")
      end

      it "is overridden by values already in the context" do
        actor = AddGreetingWithDefault.call(
          ServiceActor::Result.new(name: "jim"),
        )
        expect(actor.name).to eq("jim")
      end
    end

    context "when an input has a default that is a hash" do
      it "adds it to the context" do
        actor = AddGreetingWithHashDefault.call
        expect(actor.options).to eq({name: "world"})
      end

      it "can use it" do
        actor = AddGreetingWithHashDefault.call
        expect(actor.greeting).to eq("Hello, world!")
      end

      it "is overridden by values added to call" do
        actor = AddGreetingWithHashDefault.call(options: {name: "Alice"})
        expect(actor.options).to eq({name: "Alice"})
      end

      it "is overridden by values already in the context" do
        actor = AddGreetingWithHashDefault.call(
          ServiceActor::Result.new(options: {name: "Alice"}),
        )
        expect(actor.options).to eq({name: "Alice"})
      end
    end

    context "when an input has a lambda default" do
      it "adds it to the context" do
        actor = AddGreetingWithLambdaDefault.call
        expect(actor.name).to eq("world")
      end

      it "can use it" do
        actor = AddGreetingWithLambdaDefault.call
        expect(actor.greeting).to eq("Hello, world!")
      end
    end

    context "when a lambda default references other inputs" do
      it "adds the computed default" do
        actor = LambdaDefaultWithReference.call(old_project_id: 77_392)
        expect(actor.project_id).to eq("77392.0")
      end
    end

    context "when an input has not been given" do
      it "raises an error" do
        expect { SetNameToDowncase.call }
          .to raise_error(
            ServiceActor::ArgumentError,
            "The \"name\" input on \"SetNameToDowncase\" is missing",
          )
      end
    end

    context "when playing several actors" do
      let(:actor) { PlayActors.call(value: 1) }

      it "shares the result between actors" do
        expect(actor.value).to eq(3)
      end

      it "calls the actors in order" do
        expect(actor.name).to eq("jim")
      end

      context "when not providing arguments" do
        let(:actor) { PlayActors.call }

        it "uses defaults from the inner actors" do
          expect(actor.value).to eq(2)
        end
      end
    end

    context "when playing actors and lambdas" do
      let(:actor) { PlayLambdas.call }

      it "calls the actors and lambdas in order" do
        expect(actor.name).to eq("jim number 4")
      end
    end

    context "when playing actors and symbols" do
      let(:actor) { PlayInstanceMethods.call }

      it "calls the actors and symbols in order" do
        expect(actor.name).to eq("jim number 4")
      end
    end

    context "when playing actors that do not inherit from Actor" do
      let(:actor) { PlayActors.call }

      it "merges the result" do
        expect(actor.stripped_down_actor).to be(true)
      end
    end

    context "when using `play` several times" do
      let(:actor) { PlayMultipleTimes.call(value: 1) }

      it "shares the result between actors" do
        expect(actor.value).to eq(3)
      end

      it "calls the actors in order" do
        expect(actor.name).to eq("jim")
      end
    end

    context "when using `play` with conditions" do
      let(:actor) { PlayMultipleTimesWithConditions.call }

      it "does not trigger actors with conditions" do
        expect(actor.name).to eq("Jim")
      end

      it "shares the result between actors" do
        expect(actor.value).to eq(3)
      end
    end

    context "when using `play` with evaluated conditions" do
      let(:actor) do
        PlayMultipleTimesWithEvaluatedConditions.call(callable: callable)
      end
      let(:callable) { -> {} }

      before do
        allow(callable).to receive(:call).and_return(true)
      end

      it "does not evaluate conditions multiple times" do
        expect(actor.value).to eq(4)
        expect(callable).to have_received(:call).once
      end
    end

    context "when playing several actors and one fails" do
      let(:actor) { ServiceActor::Result.new(value: 0) }

      it "raises with the message" do
        expect { FailPlayingActionsWithRollback.call(actor) }
          .to raise_error(ServiceActor::Failure, "Ouch")
      end

      it "changes the context up to the failure then calls rollbacks" do
        expect { FailPlayingActionsWithRollback.call(actor) }
          .to raise_error(ServiceActor::Failure)

        expect(actor.name).to eq("Jim")
        expect(actor.value).to eq(0)
      end
    end

    context "when playing several actors, one fails, one rolls back" do
      let(:actor) { PlayErrorAndCatchItInRollback.result }

      it "catches the error inside the rollback" do
        expect(actor.called).to be(true)
        expect(actor.found_error).to eq("Found “Ouch”")
        expect(actor.some_other_key).to eq(42)
      end
    end

    context "when playing actors and alias_input" do
      let(:actor) { PlayAliasInput.call }

      it "calls the actors and can be referenced by alias" do
        expect(actor.name).to eq("jim number 1")
      end
    end

    context "when called with a matching condition" do
      context "when normal mode" do
        it "suceeds" do
          expect(SetNameWithInputCondition.call(name: "joe").name).to eq("JOE")
        end
      end

      context "when advanced mode" do
        it "suceeds" do
          expect(SetNameWithInputConditionAdvanced.call(name: "joe").name)
            .to eq("JOE")
        end
      end
    end

    context "when called with the wrong condition" do
      context "when normal mode" do
        it "raises" do
          expected_error =
            "The \"name\" input on \"SetNameWithInputCondition\" " \
              "must \"be_lowercase\" but was \"42\""

          expect { SetNameWithInputCondition.call(name: "42") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end

      context "when advanced mode" do
        it "raises" do
          expected_error = "Failed to apply `be_lowercase`"

          expect { SetNameWithInputConditionAdvanced.call(name: "42") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "when called with an error in the code" do
      describe "and type is first" do
        context "when advanced mode" do
          let(:expected_message) do
            "The \"per_page\" input on " \
              "\"ExpectedFailInMustWhenTypeIsFirstAdvanced\" must be " \
              "of type \"Integer\" but was \"String\""
          end

          it "raises" do
            expect do
              ExpectedFailInMustWhenTypeIsFirstAdvanced.call(per_page: "6")
            end.to raise_error(ServiceActor::ArgumentError, expected_message)
          end
        end
      end

      describe "and type is last" do
        context "when advanced mode" do
          let(:expected_message) do
            "The \"per_page\" input on " \
              "\"ExpectedFailInMustWhenTypeIsLastAdvanced\" has an error " \
              "in the code inside \"be_in_range\": " \
              "[ArgumentError] comparison of String with 3 failed"
          end

          it "raises" do
            expect do
              ExpectedFailInMustWhenTypeIsLastAdvanced.call(per_page: "6")
            end.to raise_error(ServiceActor::ArgumentError, expected_message)
          end
        end
      end
    end

    context "when called with the wrong type of argument" do
      let(:expected_message) do
        "The \"name\" input on \"SetNameToDowncase\" must be of " \
          "type \"String\" but was \"Integer\""
      end

      it "raises" do
        expect { SetNameToDowncase.call(name: 1) }
          .to raise_error(ServiceActor::ArgumentError, expected_message)
      end
    end

    context "when a type is defined but the argument is nil" do
      let(:expected_message) do
        'The "name" input on "SetNameToDowncase" does not allow nil values'
      end

      it "raises" do
        expect { SetNameToDowncase.call(name: nil) }
          .to raise_error(ServiceActor::ArgumentError, expected_message)
      end
    end

    context "when called with a type as a string instead of a class" do
      it "succeeds" do
        actor = DoubleWithTypeAsString.call(value: 2.0)
        expect(actor.double).to eq(4.0)
      end

      context "when normal mode" do
        it "does not allow other types" do
          expected_error =
            "The \"value\" input on \"DoubleWithTypeAsString\" must " \
              "be of type \"Integer, Float\" but was \"String\""
          expect { DoubleWithTypeAsString.call(value: "2.0") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end

      context "when advanced mode" do
        it "does not allow other types" do
          expected_error =
            "Wrong type `String` for `value`. Expected: `Integer, Float`"
          expect { DoubleWithTypeAsStringAdvanced.call(value: "2.0") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "when setting the wrong type of output" do
      context "when normal mode" do
        let(:expected_message) do
          "The \"name\" output on \"SetWrongTypeOfOutput\" must " \
            "be of type \"String\" but was \"Integer\""
        end

        it "raises" do
          expect { SetWrongTypeOfOutput.call }
            .to raise_error(ServiceActor::ArgumentError, expected_message)
        end
      end

      context "when advanced mode" do
        let(:expected_message) do
          "Wrong type `Integer` for `name`. Expected: `String`"
        end

        it "raises" do
          expect { SetWrongTypeOfOutputAdvanced.call }
            .to raise_error(ServiceActor::ArgumentError, expected_message)
        end
      end

      context "when a custom class is specified" do
        let(:expected_message) do
          "The \"name\" output on " \
            "\"SetWrongTypeOfOutputWithCustomArgumentErrorClass\" must " \
            "be of type \"String\" but was \"Integer\""
        end

        it "raises" do
          expect { SetWrongTypeOfOutputWithCustomArgumentErrorClass.call }
            .to raise_error(MyCustomArgumentError, expected_message)
        end
      end
    end

    context "with accessing origins multiple times" do
      it "returns expected value" do
        expect(AccessOriginsMultipleTimes.call(value: 0).value_result).to eq(2)
        expect(AccessOriginsMultipleTimes.call(value: 0).output_with_default).to eq(42)
      end
    end

    context "when setting an unknown output" do
      it "raises" do
        expect { SetUnknownOutput.call }
          .to raise_error(NoMethodError, /undefined method ['`]foobar='/)
      end
    end

    context "when reading an output" do
      it "succeeds" do
        actor = SetAndAccessOutput.result
        expect(actor.email).to eq("jim@example.org")
      end
    end

    context "when disallowing nil on an input" do
      context "when normal mode" do
        context "when given the input" do
          it "succeeds" do
            expect(DisallowNilOnInput.call(name: "Jim")).to be_a_success
          end
        end

        context "without the input" do
          it "fails" do
            expected_error =
              "The \"name\" input on \"DisallowNilOnInput\" does not " \
                "allow nil values"

            expect { DisallowNilOnInput.call(name: nil) }
              .to raise_error(ServiceActor::ArgumentError, expected_error)
          end
        end
      end

      context "when advanced mode" do
        context "when given the input" do
          it "succeeds" do
            expect(DisallowNilOnInputAdvanced.call(name: "Jim")).to be_a_success
          end
        end

        context "without the input" do
          it "fails" do
            expected_error = "The value `name` cannot be empty"

            expect { DisallowNilOnInputAdvanced.call(name: nil) }
              .to raise_error(ServiceActor::ArgumentError, expected_error)
          end
        end
      end
    end

    context "when setting a default to nil and a type on an input" do
      context "when given the input" do
        it "succeeds" do
          expect(AllowNilOnInputWithTypeAndDefaultNil.call(name: "Jim"))
            .to be_a_success
        end
      end

      context "when not given any input" do
        it "succeeds" do
          expect(AllowNilOnInputWithTypeAndDefaultNil.call).to be_a_success
        end
      end
    end

    context "when disallowing nil on an output" do
      context "when set correctly" do
        it "succeeds" do
          expect(DisallowNilOnOutput.call).to be_a_success
        end
      end

      context "without the output" do
        it "fails" do
          expected_error =
            "The \"name\" output on \"DisallowNilOnOutput\" " \
              "does not allow nil values"

          expect { DisallowNilOnOutput.call(test_without_output: true) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "when inheriting" do
      it "calls both the parent and child" do
        actor = InheritFromIncrementValue.call(value: 0)
        expect(actor.value).to eq(2)
      end
    end

    context "when inheriting from play" do
      it "calls both the parent and child" do
        actor = InheritFromPlay.call(value: 0)
        expect(actor.value).to eq(3)
      end
    end

    context "when using type, default, allow_nil and must" do
      context "when not given a value" do
        it "uses the default" do
          actor = ValidateWeekdays.call
          expect(actor.weekdays).to eq([0, 1, 2, 3, 4])
        end
      end

      context "when given a nil value" do
        it "returns nil" do
          actor = ValidateWeekdays.call(weekdays: nil)
          expect(actor.weekdays).to be_nil
        end
      end
    end

    context 'when using "inclusion"' do
      context "when normal mode" do
        context "when given a correct value" do
          it "returns the message" do
            actor = PayWithProviderInclusion.call(provider: "PayPal")
            expect(actor.message).to eq("Money transferred to PayPal!")
          end
        end

        context "when given an incorrect value" do
          let(:expected_alert) do
            'The "provider" input must be included in ' \
              '["MANGOPAY", "PayPal", "Stripe"] on ' \
              '"PayWithProviderInclusion" instead of "Paypal"'
          end

          it "fails" do
            expect { PayWithProviderInclusion.call(provider: "Paypal") }
              .to raise_error(expected_alert)
          end
        end

        context "when it has a default" do
          it "uses it" do
            actor = PayWithProviderInclusion.call
            expect(actor.message).to eq("Money transferred to Stripe!")
          end
        end
      end

      context "when advanced mode" do
        context "when given a correct value" do
          it "returns the message" do
            actor = PayWithProviderInclusionAdvanced.call(provider: "PayPal")
            expect(actor.message).to eq("Money transferred to PayPal!")
          end
        end

        context "when given an incorrect value" do
          let(:expected_alert) do
            "Payment system \"Paypal\" is not supported"
          end

          it "fails" do
            expect { PayWithProviderInclusionAdvanced.call(provider: "Paypal") }
              .to raise_error(expected_alert)
          end
        end

        context "when it has a default" do
          it "uses it" do
            actor = PayWithProviderInclusionAdvanced.call
            expect(actor.message).to eq("Money transferred to Stripe!")
          end
        end
      end
    end

    context 'when using "in"' do
      context "when normal mode" do
        context "when given a correct value" do
          it "returns the message" do
            actor = PayWithProvider.call(provider: "PayPal")
            expect(actor.message).to eq("Money transferred to PayPal!")
          end
        end

        context "when given an incorrect value" do
          let(:expected_alert) do
            'The "provider" input must be included in ' \
              '["MANGOPAY", "PayPal", "Stripe"] on "PayWithProvider" ' \
              'instead of "Paypal"'
          end

          it "fails" do
            expect { PayWithProvider.call(provider: "Paypal") }
              .to raise_error(ServiceActor::ArgumentError, expected_alert)
          end
        end

        context "when it has a default" do
          it "uses it" do
            actor = PayWithProvider.call
            expect(actor.message).to eq("Money transferred to Stripe!")
          end
        end
      end

      context "when advanced mode" do
        context "when given a correct value" do
          it "returns the message" do
            actor = PayWithProviderAdvanced.call(provider: "PayPal")
            expect(actor.message).to eq("Money transferred to PayPal!")
          end
        end

        context "when given an incorrect value" do
          let(:expected_alert) do
            "Payment system \"Paypal\" is not supported"
          end

          it "fails" do
            expect { PayWithProviderAdvanced.call(provider: "Paypal") }
              .to raise_error(ServiceActor::ArgumentError, expected_alert)
          end
        end

        context "when it has a default" do
          it "uses it" do
            actor = PayWithProviderAdvanced.call
            expect(actor.message).to eq("Money transferred to Stripe!")
          end
        end
      end
    end

    context "when playing interactors" do
      it "succeeds" do
        actor = PlayInteractor.call(value: 5)
        expect(actor.value).to eq(5 + 2)
      end
    end

    context "when playing a failing interactor" do
      it "fails" do
        actor = PlayInteractorFailure.result(value: 5)
        expect(actor).to be_a_failure
        expect(actor.error).to eq("Failed with Interactor")
        expect(actor.value).to eq(5 + 1)
      end
    end

    context "when using advanced mode with checks and not adding message key" do
      context "when using inclusion check" do
        let(:expected_alert) do
          'The "provider" input must be included ' \
            'in ["MANGOPAY", "PayPal", "Stripe"] on ' \
            '"PayWithProviderAdvancedNoMessage" ' \
            'instead of "Paypal2"'
        end

        it "returns the default message" do
          expect { PayWithProviderAdvancedNoMessage.call(provider: "Paypal2") }
            .to raise_error(ServiceActor::ArgumentError, expected_alert)
        end
      end

      context "when using type check" do
        let(:expected_error) do
          "The \"name\" input on \"CheckTypeAdvanced\" must " \
            "be of type \"String\" but was \"Integer\""
        end

        it "returns the default message" do
          expect { CheckTypeAdvanced.call(name: 2) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end

      context "when using must check" do
        let(:expected_error) do
          "The \"num\" input on \"CheckMustAdvancedNoMessage\" " \
            "must \"be_smaller\" " \
            "but was 6"
        end

        it "returns the default message" do
          expect { CheckMustAdvancedNoMessage.call(num: 6) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end

      context "when using nil check" do
        let(:expected_error) do
          "The \"name\" input on \"CheckNilAdvancedNoMessage\" " \
            "does not allow nil values"
        end

        it "returns the default message" do
          expect { CheckNilAdvancedNoMessage.call(name: nil) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "with unset output and allow_nil: true" do
      it "succeeds" do
        actor = WithUnsetOutput.result

        expect(actor).to be_a_success
        expect(actor.value).to be_nil
      end
    end

    context "with `input` name that collides with result methods" do
      include_context "with mocked `Kernel.warn` method"

      let(:actor) do
        Class.new(Actor) do
          input :value, type: Integer
          input :kind_of?, type: String
        end
      end

      specify do
        expect { actor }.to raise_error(
          ArgumentError,
          "input `kind_of?` overrides `ServiceActor::Result` instance method",
        )
      end
    end

    context "with `output` name that collides with result methods" do
      include_context "with mocked `Kernel.warn` method"

      let(:actor) do
        Class.new(Actor) do
          input :value, type: Integer
          output :fail!, type: String
        end
      end

      specify do
        expect { actor }.to raise_error(
          ArgumentError,
          "output `fail!` overrides `ServiceActor::Result` instance method",
        )
      end
    end

    context "with `alias_input` that collides with result methods" do
      include_context "with mocked `Kernel.warn` method"

      let(:actor) do
        Class.new(Actor) do
          input :value, type: Integer

          play alias_input(merge!: :value)
        end
      end

      specify do
        expect { actor }.to raise_error(
          ArgumentError,
          "alias `merge!` overrides `ServiceActor::Result` instance method",
        )
      end
    end

    context "with `failure_class` which is not a class" do
      let(:actor) do
        Class.new(Actor) do
          self.failure_class = 1
        end
      end

      it do
        expect { actor }.to raise_error(
          ArgumentError,
          "Expected 1 to be a subclass of Exception",
        )
      end
    end

    context "with `failure_class` that does not inherit `Exception`" do
      let(:actor) do
        Class.new(Actor) do
          self.failure_class = Class.new
        end
      end

      it do
        expect { actor }.to raise_error(
          ArgumentError,
          /Expected .+ to be a subclass of Exception/,
        )
      end
    end

    context "with `argument_error_class` which is not a class" do
      let(:actor) do
        Class.new(Actor) do
          self.argument_error_class = 1
        end
      end

      it do
        expect { actor }.to raise_error(
          ArgumentError,
          "Expected 1 to be a subclass of Exception",
        )
      end
    end

    context "with `argument_error_class` that does not inherit `Exception`" do
      let(:actor) do
        Class.new(Actor) do
          self.argument_error_class = Class.new
        end
      end

      it do
        expect { actor }.to raise_error(
          ArgumentError,
          /Expected .+ to be a subclass of Exception/,
        )
      end
    end

    context "with `fail_on` which is not a class" do
      let(:actor) do
        Class.new(Actor) do
          fail_on ArgumentError, "Some string", RuntimeError
        end
      end

      it do
        expect { actor }.to raise_error(
          ArgumentError,
          "Expected Some string to be a subclass of Exception",
        )
      end
    end

    context "with `fail_on` which does not inherit `Exception`" do
      let(:actor) do
        Class.new(Actor) do
          fail_on ArgumentError, Class.new
        end
      end

      it do
        expect { actor }.to raise_error(
          ArgumentError,
          /Expected .+ to be a subclass of Exception/,
        )
      end
    end
  end

  describe "#result" do
    context "when fail! is not called" do
      let(:actor) { DoNothing.result }

      it { expect(actor).to be_a(ServiceActor::Result) }
      it { expect(actor).to be_a_success }
      it { expect(actor).not_to be_a_failure }
    end

    context "when fail! is called" do
      let(:actor) { FailWithError.result }

      it { expect(actor).to be_a(ServiceActor::Result) }
      it { expect(actor).to be_a_failure }
      it { expect(actor).not_to be_a_success }
      it { expect(actor.error).to eq("Ouch") }
      it { expect(actor.some_other_key).to eq(42) }
    end

    context "with an argument error, caught by fail_on" do
      let(:actor) { FailOnArgumentError.result(name: 42) }
      let(:expected_error_message) do
        "The \"name\" input on \"FailOnArgumentError\" must " \
          "be of type \"String\" but was \"Integer\""
      end

      it { expect(actor).to be_a_failure }
      it { expect(actor.error).to eq(expected_error_message) }
    end

    context "when playing several actors" do
      let(:actor) { PlayActors.result(value: 1) }

      it { expect(actor).to be_a_success }
      it { expect(actor.name).to eq("jim") }
      it { expect(actor.value).to eq(3) }
    end

    context "when playing several actors with a rollback and one fails" do
      let(:actor) { FailPlayingActionsWithRollback.result(value: 0) }

      it { expect(actor).to be_a_failure }
      it { expect(actor).not_to be_a_success }
      it { expect(actor.name).to eq("Jim") }
      it { expect(actor.value).to eq(0) }
    end

    context "with sending unexpected messages" do
      include_context "with mocked `Kernel.warn` method"

      let(:actor) { PlayActors.result(value: 42) }

      it { expect(actor).to be_a_success }
      it { expect(actor).to respond_to(:name) }
      it { expect(actor).to respond_to(:name?) }
      it { expect(actor.name).to eq("jim") }

      it { expect(actor).not_to respond_to(:unknown_method) }
      it { expect(actor).not_to respond_to(:unknown_method?) }

      it "warns about sending unexpected messages" do
        actor.unknown_method

        expect(Kernel).to have_received(:warn).with(
          include("unknown_method"),
        )
      end

      it "warns about sending unexpected predicate messages" do
        actor.unknown_method?

        expect(Kernel).to have_received(:warn).with(
          include("unknown_method?"),
        )
      end
    end

    context "when using pattern matching" do
      let(:successful_result) { FailForDifferentReasons.result(month: 2) }
      let(:holidays_result) { FailForDifferentReasons.result(month: 12) }
      let(:invalid_result) { FailForDifferentReasons.result(month: -1) }

      it { expect(match_result(successful_result)).to eq "Welcome!" }
      it { expect(match_result(holidays_result)).to eq "Come next year!" }
      it { expect(match_result(invalid_result)).to be_nil }

      def match_result(result)
        case result
        in {success: true, message:}
          message
        in {failure: true, reason: :holidays, message:}
          message
        in {failure: true, reason: :invalid_month}
          nil
        end
      end
    end
  end

  describe "#value" do
    context "when fail! is not called" do
      let(:output) { DoNothing.value }

      it { expect(output).to be_nil }
    end

    context "when fail! is called" do
      it "raises the error message" do
        expect { FailWithError.value }
          .to raise_error(ServiceActor::Failure, "Ouch")
      end

      context "when a custom class is specified" do
        it "raises the error message" do
          expect { FailWithErrorWithCustomFailureClass.value }
            .to raise_error(MyCustomFailure, "Ouch")
        end
      end
    end

    context "when an actor updates the context using value" do
      it "returns the value of the context change" do
        output = AddNameToContext.value
        expect(output).to eq("Jim")
      end
    end

    context "when an actor updates the context with a hash using value" do
      it "returns the hash value of the context change" do
        output = AddHashToContext.value
        expect(output).to eq(name: "Jim")
      end
    end

    context "when an actor uses a method named after the input" do
      it "returns what is assigned to the context" do
        output = SetNameToDowncase.value(name: "JIM")
        expect(output).to eq("jim")
      end
    end

    context "when given a context instead of a hash" do
      it "returns the value of the context" do
        actor = ServiceActor::Result.new(name: "Jim")

        expect(AddNameToContext.value(actor)).to eq("Jim")
      end
    end

    context "when an actor changes a value" do
      it "returns the updated value" do
        expect(IncrementValue.value(value: 1)).to eq(2)
      end
    end

    context "when an input has a default" do
      it "can use it" do
        expect(AddGreetingWithDefault.value).to eq("Hello, world!")
      end

      it "is overridden by values added to call" do
        expect(AddGreetingWithDefault.value(name: "Jim")).to eq("Hello, Jim!")
      end

      it "is overridden by values already in the context" do
        output = AddGreetingWithDefault.value(
          ServiceActor::Result.new(name: "jim"),
        )
        expect(output).to eq("Hello, jim!")
      end
    end

    context "when an input has a default that is a hash" do
      it "can use it" do
        expect(AddGreetingWithHashDefault.value).to eq("Hello, world!")
      end

      it "is overridden by values added to call" do
        output = AddGreetingWithHashDefault.value(options: {name: "Alice"})
        expect(output).to eq("Hello, Alice!")
      end

      it "is overridden by values already in the context" do
        output = AddGreetingWithHashDefault.value(
          ServiceActor::Result.new(options: {name: "Alice"}),
        )
        expect(output).to eq("Hello, Alice!")
      end
    end

    context "when an input has a lambda default" do
      it "can use it" do
        output = AddGreetingWithLambdaDefault.value
        expect(output).to eq("Hello, world!")
      end
    end

    context "when a lambda default references other inputs" do
      it "adds the computed default" do
        output = LambdaDefaultWithReference.value(old_project_id: 77_392)
        expect(output).to eq(project_id: "77392.0")
      end
    end

    context "when an input has not been given" do
      it "raises an error" do
        expect { SetNameToDowncase.value }
          .to raise_error(
            ServiceActor::ArgumentError,
            "The \"name\" input on \"SetNameToDowncase\" is missing",
          )
      end
    end

    context "when playing several actors" do
      it "returns the result of the last actor" do
        expect(PlayActors.value(value: 1)).to eq(3)
      end

      context "when not providing arguments" do
        it "uses defaults from the inner actors" do
          expect(PlayActors.value).to eq(2)
        end
      end
    end

    context "when playing actors and lambdas" do
      it "calls the actors and lambdas in order and returns the final value" do
        expect(PlayLambdas.value).to eq("jim number 4")
      end
    end

    context "when playing actors and symbols" do
      it "calls the actors and symbols in order and returns the final value" do
        expect(PlayInstanceMethods.value).to eq("jim number 4")
      end
    end

    context "when using `play` several times" do
      it "shares the result between actors and returns the final value" do
        expect(PlayMultipleTimes.value(value: 1)).to eq(3)
      end
    end

    context "when using `play` with conditions" do
      it "does not trigger actors with conditions and returns the final value" do
        expect(PlayMultipleTimesWithConditions.value).to eq(3)
      end
    end

    context "when using `play` with evaluated conditions" do
      let(:output) do
        PlayMultipleTimesWithEvaluatedConditions.value(callable: callable)
      end
      let(:callable) { -> {} }

      before do
        allow(callable).to receive(:call).and_return(true)
      end

      it "does not evaluate conditions multiple times" do
        expect(output).to eq(4)
        expect(callable).to have_received(:call).once
      end
    end

    context "when playing several actors and one fails" do
      let(:actor) { ServiceActor::Result.new(value: 0) }

      it "raises with the message" do
        expect { FailPlayingActionsWithRollback.value(actor) }
          .to raise_error(ServiceActor::Failure, "Ouch")
      end
    end

    context "when playing actors and alias_input" do
      it "calls the actors and can be referenced by alias" do
        expect(PlayAliasInput.value).to eq("jim number 1")
      end
    end

    context "when value'd with a matching condition" do
      context "when normal mode" do
        it "suceeds" do
          expect(SetNameWithInputCondition.value(name: "joe")).to eq("JOE")
        end
      end

      context "when advanced mode" do
        it "suceeds" do
          expect(SetNameWithInputConditionAdvanced.value(name: "joe"))
            .to eq("JOE")
        end
      end
    end

    context "when value'd with the wrong condition" do
      context "when normal mode" do
        it "raises" do
          expected_error =
            "The \"name\" input on \"SetNameWithInputCondition\" " \
              "must \"be_lowercase\" but was \"42\""

          expect { SetNameWithInputCondition.value(name: "42") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end

      context "when advanced mode" do
        it "raises" do
          expected_error = "Failed to apply `be_lowercase`"

          expect { SetNameWithInputConditionAdvanced.value(name: "42") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "when value'd with an error in the code" do
      describe "and type is first" do
        context "when advanced mode" do
          let(:expected_message) do
            "The \"per_page\" input on " \
              "\"ExpectedFailInMustWhenTypeIsFirstAdvanced\" must be " \
              "of type \"Integer\" but was \"String\""
          end

          it "raises" do
            expect do
              ExpectedFailInMustWhenTypeIsFirstAdvanced.value(per_page: "6")
            end.to raise_error(ServiceActor::ArgumentError, expected_message)
          end
        end
      end

      describe "and type is last" do
        context "when advanced mode" do
          let(:expected_message) do
            "The \"per_page\" input on " \
              "\"ExpectedFailInMustWhenTypeIsLastAdvanced\" has an error " \
              "in the code inside \"be_in_range\": " \
              "[ArgumentError] comparison of String with 3 failed"
          end

          it "raises" do
            expect do
              ExpectedFailInMustWhenTypeIsLastAdvanced.value(per_page: "6")
            end.to raise_error(ServiceActor::ArgumentError, expected_message)
          end
        end
      end
    end

    context "when value'd with the wrong type of argument" do
      let(:expected_message) do
        "The \"name\" input on \"SetNameToDowncase\" must be of " \
          "type \"String\" but was \"Integer\""
      end

      it "raises" do
        expect { SetNameToDowncase.value(name: 1) }
          .to raise_error(ServiceActor::ArgumentError, expected_message)
      end
    end

    context "when a type is defined but the argument is nil" do
      let(:expected_message) do
        'The "name" input on "SetNameToDowncase" does not allow nil values'
      end

      it "raises" do
        expect { SetNameToDowncase.value(name: nil) }
          .to raise_error(ServiceActor::ArgumentError, expected_message)
      end
    end

    context "when called with a type as a string instead of a class" do
      it "succeeds" do
        expect(DoubleWithTypeAsString.value(value: 2.0)).to eq(4.0)
      end

      context "when normal mode" do
        it "does not allow other types" do
          expected_error =
            "The \"value\" input on \"DoubleWithTypeAsString\" must " \
              "be of type \"Integer, Float\" but was \"String\""
          expect { DoubleWithTypeAsString.value(value: "2.0") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end

      context "when advanced mode" do
        it "does not allow other types" do
          expected_error =
            "Wrong type `String` for `value`. Expected: `Integer, Float`"
          expect { DoubleWithTypeAsStringAdvanced.value(value: "2.0") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "when disallowing nil on an input" do
      context "when normal mode" do
        context "when given the input" do
          it "does not fail" do
            expect(DisallowNilOnInput.value(name: "Jim")).to be_nil
          end
        end

        context "without the input" do
          it "fails" do
            expected_error =
              "The \"name\" input on \"DisallowNilOnInput\" does not " \
                "allow nil values"

            expect { DisallowNilOnInput.value(name: nil) }
              .to raise_error(ServiceActor::ArgumentError, expected_error)
          end
        end
      end

      context "when advanced mode" do
        context "when given the input" do
          it "does not fail" do
            expect(DisallowNilOnInputAdvanced.value(name: "Jim")).to be_nil
          end
        end

        context "without the input" do
          it "fails" do
            expected_error = "The value `name` cannot be empty"

            expect { DisallowNilOnInputAdvanced.value(name: nil) }
              .to raise_error(ServiceActor::ArgumentError, expected_error)
          end
        end
      end
    end

    context "when disallowing nil on an output" do
      context "when set correctly" do
        it "succeeds" do
          expect(DisallowNilOnOutput.value).to eq("Jim")
        end
      end

      context "without the output" do
        it "fails" do
          expected_error =
            "The \"name\" output on \"DisallowNilOnOutput\" " \
              "does not allow nil values"

          expect { DisallowNilOnOutput.value(test_without_output: true) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "when inheriting" do
      it "calls both the parent and child" do
        expect(InheritFromIncrementValue.value(value: 0)).to eq(2)
      end
    end

    context "when inheriting from play" do
      it "calls both the parent and child" do
        expect(InheritFromPlay.value(value: 0)).to eq(3)
      end
    end

    context "when playing interactors" do
      it "succeeds" do
        expect(PlayInteractor.value(value: 5).value).to eq(5 + 2)
      end
    end

    context "when using advanced mode with checks and not adding message key" do
      context "when using inclusion check" do
        let(:expected_alert) do
          'The "provider" input must be included ' \
            'in ["MANGOPAY", "PayPal", "Stripe"] on ' \
            '"PayWithProviderAdvancedNoMessage" ' \
            'instead of "Paypal2"'
        end

        it "returns the default message" do
          expect { PayWithProviderAdvancedNoMessage.value(provider: "Paypal2") }
            .to raise_error(ServiceActor::ArgumentError, expected_alert)
        end
      end

      context "when using type check" do
        let(:expected_error) do
          "The \"name\" input on \"CheckTypeAdvanced\" must " \
            "be of type \"String\" but was \"Integer\""
        end

        it "returns the default message" do
          expect { CheckTypeAdvanced.value(name: 2) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end

      context "when using must check" do
        let(:expected_error) do
          "The \"num\" input on \"CheckMustAdvancedNoMessage\" " \
            "must \"be_smaller\" " \
            "but was 6"
        end

        it "returns the default message" do
          expect { CheckMustAdvancedNoMessage.value(num: 6) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end

      context "when using nil check" do
        let(:expected_error) do
          "The \"name\" input on \"CheckNilAdvancedNoMessage\" " \
            "does not allow nil values"
        end

        it "returns the default message" do
          expect { CheckNilAdvancedNoMessage.value(name: nil) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "with unset output and allow_nil: true" do
      it "does not fail" do
        expect(WithUnsetOutput.value).to be_nil
      end
    end
  end

  context "when playing something that returns nil" do
    let(:call_counter) { double :call_counter, trigger: nil }

    it "does not fail" do
      expect(PlayReturnsNil.call(call_counter: call_counter)).to be_a_success

      expect(call_counter).to have_received(:trigger).once
    end
  end

  context "when an input is called :error" do
    it "does not fail" do
      expect(HandleInputCalledError.call(error: "A message")).to be_a_success
    end
  end

  context "when calling result with fail_on" do
    let(:actor) do
      Class.new(Actor) do
        fail_on CustomArgumentError
        self.argument_error_class = CustomArgumentError
        self.failure_class = CustomFailureError

        input :value, type: Integer
      end
    end

    it "does not raise" do
      result = actor.result(value: "boop")
      expect(result).to be_a_failure
      expect(result.error).to start_with('The "value" input on')
    end
  end
end
