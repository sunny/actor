# frozen_string_literal: true

require 'rspec'
require 'pry'

require 'actor'

require 'examples/add_name_to_context'
require 'examples/do_nothing'
require 'examples/increment_value'
require 'examples/increment_value_with_rollback'
require 'examples/set_name_to_downcase'
require 'examples/fail_with_error'
require 'examples/add_greeting_with_default'
require 'examples/add_greeting_with_lambda_default'
require 'examples/set_wrong_type_of_output'

require 'examples/fail_chaining_actions'
require 'examples/fail_chaining_actions_with_rollback'
require 'examples/chain_actors'
require 'examples/chain_lambdas'

RSpec.describe Actor do
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

    context 'when playing several actors' do
      it 'calls the actors in order' do
        result = ChainActors.call(value: 1)
        expect(result.name).to eq('jim')
        expect(result.value).to eq(3)
      end
    end

    context 'when playing actors and lambdas' do
      it 'calls the actors and lambdas in order' do
        result = ChainLambdas.call
        expect(result.name).to eq('jim number 4')
      end
    end

    context 'when playing several actors and one fails' do
      it 'raises with the message' do
        expect { FailChainingActionsWithRollback.call(value: 0) }
          .to raise_error(Actor::Failure, 'Ouch')
      end

      it 'changes the context up to the failure and calls rollbacks' do
        data = { value: 0 }
        result = Actor::Context.new(data)

        expect { FailChainingActionsWithRollback.call(result) }
          .to raise_error(Actor::Failure)

        expect(result.name).to eq('Jim')
        expect(result.value).to eq(0)
      end
    end

    context 'when called with the wrong type of argument' do
      it 'raises with a message' do
        expect { SetNameToDowncase.call(name: 1) }
          .to raise_error(
            ArgumentError,
            'Input name on SetNameToDowncase must be of type String but was ' \
              'Integer',
          )
      end
    end

    context 'when setting the wrong type of output' do
      it 'raises with a message' do
        expect { SetWrongTypeOfOutput.call }
          .to raise_error(
            ArgumentError,
            'Output name on SetWrongTypeOfOutput must be of type String but ' \
              'was Integer',
          )
      end
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
        result = ChainActors.result(value: 1)
        expect(result).to be_a_success
        expect(result.name).to eq('jim')
        expect(result.value).to eq(3)
      end
    end

    context 'when playing several actors and one fails' do
      it 'calls the rollback method' do
        result = FailChainingActionsWithRollback.result(value: 0)
        expect(result).to be_a_failure
        expect(result).not_to be_a_success
        expect(result.name).to eq('Jim')
        expect(result.value).to eq(0)
      end
    end
  end
end
