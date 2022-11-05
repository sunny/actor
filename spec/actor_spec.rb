# frozen_string_literal: true

RSpec.describe Actor do
  describe "#call" do
    context "when fail! is not called" do
      let(:actor) { DoNothing.call }

      it { expect(actor).to be_kind_of(ServiceActor::Result) }
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

      it "ignores values added to call" do
        actor = AddGreetingWithDefault.call(name: "jim")
        expect(actor.name).to eq("jim")
      end

      it "ignores values already in the context" do
        actor = AddGreetingWithDefault.call(
          ServiceActor::Result.new(name: "jim"),
        )
        expect(actor.name).to eq("jim")
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

    context "when using an output called display" do
      it "returns it" do
        expect(SetOutputCalledDisplay.call.display).to eq("Foobar")
      end
    end

    context "when setting an unknown output" do
      it "raises" do
        expect { SetUnknownOutput.call }
          .to raise_error(NoMethodError, /undefined method `foobar='/)
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
            '["MANGOPAY", "PayPal", "Stripe"] on "PayWithProviderInclusion" ' \
            'instead of "Paypal"'
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
  end

  describe "#result" do
    context "when fail! is not called" do
      let(:actor) { DoNothing.result }

      it { expect(actor).to be_kind_of(ServiceActor::Result) }
      it { expect(actor).to be_a_success }
      it { expect(actor).not_to be_a_failure }
    end

    context "when fail! is called" do
      let(:actor) { FailWithError.result }

      it { expect(actor).to be_kind_of(ServiceActor::Result) }
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
  end
end
