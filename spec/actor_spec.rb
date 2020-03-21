# frozen_string_literal: true

Dir['./spec/examples/*'].sort.each { |f| require f }

RSpec.describe Actor do
  it 'has a version number' do
    expect(Actor::VERSION).not_to be_nil
  end

  describe '#call' do
    context 'when fail! is not called' do
      it 'succeeds' do
        result = DoNothing.call
        expect(result).to be_kind_of(Actor::Context)
        expect(result).to be_a_success
        expect(result).not_to be_a_failure
      end
    end

    context 'when fail! is called' do
      it 'raises the error message' do
        expect { FailWithError.call }.to raise_error(Actor::Failure, 'Ouch')
      end
    end

    context 'when an actor updates the context' do
      it 'returns the context with the change' do
        result = AddNameToContext.call
        expect(result.name).to eq('Jim')
      end
    end

    context 'when an actor updates the context with a hash' do
      it 'returns the hash with the change' do
        result = AddHashToContext.call
        expect(result.stuff).to eq(name: 'Jim')
      end
    end

    context 'when an actor uses a method named after the input' do
      it 'returns what is in the context' do
        result = SetNameToDowncase.call(name: 'JIM')
        expect(result.name).to eq('jim')
      end
    end

    context 'when given a context instead of a hash' do
      it 'returns the same context' do
        result = Actor::Context.new(name: 'Jim')

        expect(AddNameToContext.call(result)).to eq(result)
      end

      it 'can update the given context' do
        result = Actor::Context.new(name: 'Jim')

        SetNameToDowncase.call(result)

        expect(result.name).to eq('jim')
      end
    end

    context 'when an actor changes a value' do
      it 'returns a context with the updated value' do
        result = IncrementValue.call(value: 1)
        expect(result.value).to eq(2)
      end
    end

    context 'when an input has a default' do
      it 'adds it to the context' do
        result = AddGreetingWithDefault.call
        expect(result.name).to eq('world')
      end

      it 'can use it' do
        result = AddGreetingWithDefault.call
        expect(result.greeting).to eq('Hello, world!')
      end

      it 'ignores values added to call' do
        result = AddGreetingWithDefault.call(name: 'jim')
        expect(result.name).to eq('jim')
      end

      it 'ignores values already in the context' do
        result = AddGreetingWithDefault.call(Actor::Context.new(name: 'jim'))
        expect(result.name).to eq('jim')
      end
    end

    context 'when an input has a lambda default' do
      it 'adds it to the context' do
        result = AddGreetingWithLambdaDefault.call
        expect(result.name).to eq('world')
      end

      it 'can use it' do
        result = AddGreetingWithLambdaDefault.call
        expect(result.greeting).to eq('Hello, world!')
      end
    end

    context 'when an input has not been given' do
      it 'raises an error' do
        expect { SetNameToDowncase.call }
          .to raise_error(
            Actor::ArgumentError,
            'Input name on SetNameToDowncase is missing.',
          )
      end
    end

    context 'when playing several actors' do
      it 'calls the actors in order' do
        result = PlayActors.call(value: 1)
        expect(result.name).to eq('jim')
        expect(result.value).to eq(3)
      end
    end

    context 'when playing actors and lambdas' do
      it 'calls the actors and lambdas in order' do
        result = PlayLambdas.call
        expect(result.name).to eq('jim number 4')
      end
    end

    context 'when using `play` several times' do
      it 'calls the actors in order' do
        result = PlayMultipleTimes.call(value: 1)
        expect(result.name).to eq('jim')
        expect(result.value).to eq(3)
      end
    end

    context 'when using `play` with conditions' do
      it 'calls the actors in order' do
        result = PlayMultipleTimesWithConditions.call
        expect(result.name).to eq('Jim')
        expect(result.value).to eq(3)
      end
    end

    context 'when playing several actors and one fails' do
      it 'raises with the message' do
        expect { FailPlayingActionsWithRollback.call(value: 0) }
          .to raise_error(Actor::Failure, 'Ouch')
      end

      it 'changes the context up to the failure and calls rollbacks' do
        data = { value: 0 }
        result = Actor::Context.new(data)

        expect { FailPlayingActionsWithRollback.call(result) }
          .to raise_error(Actor::Failure)

        expect(result.name).to eq('Jim')
        expect(result.value).to eq(0)
      end
    end

    context 'when called with a matching condition' do
      it 'suceeds' do
        expect(SetNameWithInputCondition.call(name: 'joe').name).to eq('JOE')
      end
    end

    context 'when called with the wrong condition' do
      it 'suceeds' do
        expected_error = 'Input name must be_lowercase but was "42".'

        expect { SetNameWithInputCondition.call(name: '42') }
          .to raise_error(Actor::ArgumentError, expected_error)
      end
    end

    context 'when called with the wrong type of argument' do
      it 'raises with a message' do
        expect { SetNameToDowncase.call(name: 1) }
          .to raise_error(
            Actor::ArgumentError,
            'Input name on SetNameToDowncase must be of type String but was ' \
              'Integer',
          )
      end
    end

    context 'when setting the wrong type of output' do
      it 'raises with a message' do
        expect { SetWrongTypeOfOutput.call }
          .to raise_error(
            Actor::ArgumentError,
            'Output name on SetWrongTypeOfOutput must be of type String but ' \
              'was Integer',
          )
      end
    end

    context 'when using an output called display' do
      it 'returns it' do
        expect(SetOutputCalledDisplay.call.display).to eq('Foobar')
      end
    end

    context 'when using an unknown input' do
      it 'raises with a message' do
        expect { UseUnknownInput.call }
          .to raise_error(Actor::ArgumentError, /Cannot call foobar on/)
      end
    end

    context 'when setting an unknown output' do
      it 'raises' do
        expect { SetUnknownOutput.call }
          .to raise_error(NoMethodError, /undefined method `foobar='/)
      end
    end

    context 'when reading an output' do
      it 'succeeds' do
        result = SetAndAccessOutput.result
        expect(result.email).to eq('jim@example.org')
      end
    end

    context 'when disallowing nil on an input' do
      context 'when given the input' do
        it 'succeeds' do
          expect(DisallowNilOnInput.call(name: 'Jim')).to be_a_success
        end
      end

      context 'without the input' do
        it 'fails' do
          expected_error =
            'The input "name" on DisallowNilOnInput does not allow nil values.'

          expect { DisallowNilOnInput.call(name: nil) }
            .to raise_error(Actor::ArgumentError, expected_error)
        end
      end
    end

    context 'when disallowing nil on an input with the deprecated required ' \
            'argument' do
      let(:expected_warning) do
        'DEPRECATED: The "required" option is deprecated. Replace `input ' \
        ':name, required: true` by `input :name, allow_nil: false` in ' \
        "DisallowNilOnInputWithDeprecatedRequired.\n"
      end

      context 'when given the input' do
        it 'succeeds with a warning' do
          result = nil

          expect do
            result = DisallowNilOnInputWithDeprecatedRequired.call(name: 'Jim')
          end.to output(expected_warning).to_stderr

          expect(result).to be_a_success
        end
      end

      context 'without the input' do
        it 'fails' do
          expected_error =
            'The input "name" on DisallowNilOnInputWithDeprecatedRequired ' \
            'does not allow nil values.'

          expect { DisallowNilOnInputWithDeprecatedRequired.call(name: nil) }
            .to raise_error(Actor::ArgumentError, expected_error)
            .and output(expected_warning).to_stderr
        end
      end
    end

    context 'when disallowing nil on an output' do
      context 'when set correctly' do
        it 'succeeds' do
          expect(DisallowNilOnOutput.call).to be_a_success
        end
      end

      context 'without the output' do
        it 'fails' do
          expected_error =
            'The output "name" on DisallowNilOnOutput does not allow nil ' \
            'values.'

          expect { DisallowNilOnOutput.call(test_without_output: true) }
            .to raise_error(Actor::ArgumentError, expected_error)
        end
      end
    end

    context 'when disallowing nil on an output with the deprecated required ' \
            'argument' do
      let(:expected_warning) do
        'DEPRECATED: The "required" option is deprecated. Replace `output ' \
        ':name, required: true` by `output :name, allow_nil: false` in ' \
        "DisallowNilOnOutputWithDeprecatedRequired.\n"
      end

      context 'when set correctly' do
        it 'succeeds' do
          result = nil

          expect do
            result = DisallowNilOnOutputWithDeprecatedRequired.call
          end.to output(expected_warning).to_stderr

          expect(result).to be_a_success
        end
      end

      context 'without the output' do
        it 'fails' do
          expected_error =
            'The output "name" on DisallowNilOnOutputWithDeprecatedRequired ' \
            'does not allow nil values.'

          expect do
            DisallowNilOnOutputWithDeprecatedRequired.call(
              test_without_output: true,
            )
          end
            .to raise_error(Actor::ArgumentError, expected_error)
            .and output(expected_warning).to_stderr
        end
      end
    end

    context 'when calling an actor that succeeds early' do
      it 'succeeds' do
        result = SucceedEarly.call
        expect(result).to be_kind_of(Actor::Context)
        expect(result).to be_a_success
        expect(result).not_to be_a_failure
      end
    end

    context 'when playing an actor that succeeds early' do
      it 'succeeds' do
        result = SucceedPlayingActions.call
        expect(result).to be_kind_of(Actor::Context)
        expect(result).to be_a_success
        expect(result).not_to be_a_failure
        expect(result.count).to eq(1)
      end
    end

    context 'when inheriting' do
      it 'calls both the parent and child' do
        result = InheritFromIncrementValue.call(value: 0)
        expect(result.value).to eq(2)
      end
    end

    context 'when inheriting from play' do
      it 'calls both the parent and child' do
        result = InheritFromPlay.call(value: 0)
        expect(result.value).to eq(3)
      end
    end
  end

  describe '#call!' do
    it 'is an alias to call' do
      expected_warning =
        "DEPRECATED: Prefer `DoNothing.call` to `DoNothing.call!`.\n"

      result = nil
      expect { result = DoNothing.call! }
        .to output(expected_warning)
        .to_stderr

      expect(result).to be_kind_of(Actor::Context)
      expect(result).to be_a_success
      expect(result).not_to be_a_failure
    end
  end

  describe '#result' do
    context 'when fail! is not called' do
      it 'succeeds' do
        result = DoNothing.result
        expect(result).to be_kind_of(Actor::Context)
        expect(result).to be_a_success
        expect(result).not_to be_a_failure
      end
    end

    context 'when fail! is called' do
      it 'fails' do
        result = FailWithError.result
        expect(result).to be_kind_of(Actor::Context)
        expect(result).to be_a_failure
        expect(result).not_to be_a_success
      end

      it 'adds failure data to the context' do
        result = FailWithError.result
        expect(result.error).to eq('Ouch')
        expect(result.some_other_key).to eq(42)
      end
    end

    context 'when playing several actors' do
      it 'calls the actors in order' do
        result = PlayActors.result(value: 1)
        expect(result).to be_a_success
        expect(result.name).to eq('jim')
        expect(result.value).to eq(3)
      end
    end

    context 'when playing several actors and one fails' do
      it 'calls the rollback method' do
        result = FailPlayingActionsWithRollback.result(value: 0)
        expect(result).to be_a_failure
        expect(result).not_to be_a_success
        expect(result.name).to eq('Jim')
        expect(result.value).to eq(0)
      end
    end

    context 'when calling an actor that succeeds early' do
      it 'succeeds' do
        result = SucceedEarly.result
        expect(result).to be_kind_of(Actor::Context)
        expect(result).to be_a_success
        expect(result).not_to be_a_failure
      end
    end

    context 'when playing an actor that succeeds early' do
      it 'succeeds' do
        result = SucceedPlayingActions.result
        expect(result).to be_kind_of(Actor::Context)
        expect(result).to be_a_success
        expect(result).not_to be_a_failure
        expect(result.count).to eq(1)
      end
    end
  end
end
