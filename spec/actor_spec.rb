# frozen_string_literal: true

RSpec.describe Actor do
  describe '#call' do
    context 'when fail! is not called' do
      let(:result) { DoNothing.call }

      it { expect(result).to be_kind_of(ServiceActor::Result) }
      it { expect(result).to be_a_success }
      it { expect(result).not_to be_a_failure }
    end

    context 'when fail! is called' do
      it 'raises the error message' do
        expect { FailWithError.call }
          .to raise_error(ServiceActor::Failure, 'Ouch')
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
        result = ServiceActor::Result.new(name: 'Jim')

        expect(AddNameToContext.call(result)).to eq(result)
      end

      it 'can update the given context' do
        result = ServiceActor::Result.new(name: 'Jim')

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
        result = AddGreetingWithDefault.call(
          ServiceActor::Result.new(name: 'jim'),
        )
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
            ServiceActor::ArgumentError,
            'Input name on SetNameToDowncase is missing.',
          )
      end
    end

    context 'when playing several actors' do
      let(:result) { PlayActors.call(value: 1) }

      it 'shares the result between actors' do
        expect(result.value).to eq(3)
      end

      it 'calls the actors in order' do
        expect(result.name).to eq('jim')
      end
    end

    context 'when playing actors and lambdas' do
      let(:result) { PlayLambdas.call }

      it 'calls the actors and lambdas in order' do
        expect(result.name).to eq('jim number 4')
      end
    end

    context 'when using `play` several times' do
      let(:result) { PlayMultipleTimes.call(value: 1) }

      it 'shares the result between actors' do
        expect(result.value).to eq(3)
      end

      it 'calls the actors in order' do
        expect(result.name).to eq('jim')
      end
    end

    context 'when using `play` with conditions' do
      let(:result) { PlayMultipleTimesWithConditions.call }

      it 'does not trigger actors with conditions' do
        expect(result.name).to eq('Jim')
      end

      it 'shares the result between actors' do
        expect(result.value).to eq(3)
      end
    end

    context 'when playing several actors and one fails' do
      let(:result) { ServiceActor::Result.new(value: 0) }

      it 'raises with the message' do
        expect { FailPlayingActionsWithRollback.call(result) }
          .to raise_error(ServiceActor::Failure, 'Ouch')
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'changes the context up to the failure then calls rollbacks' do
        expect { FailPlayingActionsWithRollback.call(result) }
          .to raise_error(ServiceActor::Failure)

        expect(result.name).to eq('Jim')
        expect(result.value).to eq(0)
      end
      # rubocop:enable RSpec/MultipleExpectations
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
          .to raise_error(ServiceActor::ArgumentError, expected_error)
      end
    end

    context 'when called with the wrong type of argument' do
      let(:expected_message) do
        'Input name on SetNameToDowncase must be of type String but was ' \
        'Integer'
      end

      it 'raises' do
        expect { SetNameToDowncase.call(name: 1) }
          .to raise_error(ServiceActor::ArgumentError, expected_message)
      end
    end

    context 'when called with a type as a string instead of a class' do
      it 'succeeds' do
        result = DoubleWithTypeAsString.call(value: 2.0)
        expect(result.double).to eq(4.0)
      end

      it 'does not allow other types' do
        expected_error =
          'Input value on DoubleWithTypeAsString must be of type Integer, ' \
          'Float but was String'
        expect { DoubleWithTypeAsString.call(value: '2.0') }
          .to raise_error(ServiceActor::ArgumentError, expected_error)
      end
    end

    context 'when setting the wrong type of output' do
      let(:expected_message) do
        'Output name on SetWrongTypeOfOutput must be of type String but was ' \
        'Integer'
      end

      it 'raises' do
        expect { SetWrongTypeOfOutput.call }
          .to raise_error(ServiceActor::ArgumentError, expected_message)
      end
    end

    context 'when using an output called display' do
      it 'returns it' do
        expect(SetOutputCalledDisplay.call.display).to eq('Foobar')
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
            .to raise_error(ServiceActor::ArgumentError, expected_error)
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
        let(:muffled_result) do
          result = nil

          expect do
            result = DisallowNilOnInputWithDeprecatedRequired.call(name: 'Jim')
          end.to output(expected_warning).to_stderr

          result
        end

        it { expect(muffled_result).to be_a_success }
      end

      context 'without the input' do
        let(:expected_error) do
          'The input "name" on DisallowNilOnInputWithDeprecatedRequired ' \
          'does not allow nil values.'
        end

        it 'fails' do
          expect { DisallowNilOnInputWithDeprecatedRequired.call(name: nil) }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
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
            .to raise_error(ServiceActor::ArgumentError, expected_error)
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

      let(:call) do
        DisallowNilOnOutputWithDeprecatedRequired.call
      end

      let(:muffled_result) do
        result = nil

        expect { result = call }.to output(expected_warning).to_stderr

        result
      end

      it { expect(muffled_result).to be_a_success }

      context 'without the output' do
        let(:call) do
          DisallowNilOnOutputWithDeprecatedRequired.call(
            test_without_output: true,
          )
        end

        let(:expected_error) do
          'The output "name" on DisallowNilOnOutputWithDeprecatedRequired ' \
          'does not allow nil values.'
        end

        it 'fails' do
          expect { muffled_result }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context 'when calling an actor that succeeds early' do
      let(:result) { SucceedEarly.call }

      it { expect(result).to be_kind_of(ServiceActor::Result) }
      it { expect(result).to be_a_success }
      it { expect(result).not_to be_a_failure }
    end

    context 'when playing an actor that succeeds early' do
      let(:result) { SucceedPlayingActions.call }

      it { expect(result).to be_kind_of(ServiceActor::Result) }
      it { expect(result).to be_a_success }
      it { expect(result).not_to be_a_failure }
      it { expect(result.count).to eq(1) }
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
    let(:expected_warning) do
      "DEPRECATED: Prefer `DoNothing.call` to `DoNothing.call!`.\n"
    end

    let(:muffled_result) do
      result = nil
      expect { result = DoNothing.call! }.to output(expected_warning).to_stderr
      result
    end

    it { expect(muffled_result).to be_kind_of(ServiceActor::Result) }
    it { expect(muffled_result).to be_a_success }
    it { expect(muffled_result).not_to be_a_failure }
  end

  describe '#result' do
    context 'when fail! is not called' do
      let(:result) { DoNothing.result }

      it { expect(result).to be_kind_of(ServiceActor::Result) }
      it { expect(result).to be_a_success }
      it { expect(result).not_to be_a_failure }
    end

    context 'when fail! is called' do
      let(:result) { FailWithError.result }

      it { expect(result).to be_kind_of(ServiceActor::Result) }
      it { expect(result).to be_a_failure }
      it { expect(result).not_to be_a_success }
      it { expect(result.error).to eq('Ouch') }
      it { expect(result.some_other_key).to eq(42) }
    end

    context 'when playing several actors' do
      let(:result) { PlayActors.result(value: 1) }

      it { expect(result).to be_a_success }
      it { expect(result.name).to eq('jim') }
      it { expect(result.value).to eq(3) }
    end

    context 'when playing several actors with a rollback and one fails' do
      let(:result) { FailPlayingActionsWithRollback.result(value: 0) }

      it { expect(result).to be_a_failure }
      it { expect(result).not_to be_a_success }
      it { expect(result.name).to eq('Jim') }
      it { expect(result.value).to eq(0) }
    end

    context 'when calling an actor that succeeds early' do
      let(:result) { SucceedEarly.result }

      it { expect(result).to be_kind_of(ServiceActor::Result) }
      it { expect(result).to be_a_success }
      it { expect(result).not_to be_a_failure }
    end

    context 'when playing an actor that succeeds early' do
      let(:result) { SucceedPlayingActions.result }

      it { expect(result).to be_kind_of(ServiceActor::Result) }
      it { expect(result).to be_a_success }
      it { expect(result).not_to be_a_failure }
      it { expect(result.count).to eq(1) }
    end
  end
end
