# frozen_string_literal: true

require "interactor"

CustomArgumentError = Class.new(StandardError)

class CustomFailureError < StandardError
  attr_reader :result

  def initialize(result)
    @result = result

    super("Custom failure")
  end
end

MyCustomArgumentError = Class.new(ServiceActor::ArgumentError)
MyCustomFailure = Class.new(ServiceActor::Failure)

RSpec.describe Actor do
  describe ".call" do
    context "when fail! is not called" do
      let(:actor_class) { Class.new(Actor) }

      it { expect(actor_class.call).to be_a(ServiceActor::Result) }
      it { expect(actor_class.call).to be_a_success }
      it { expect(actor_class.call).not_to be_a_failure }
    end

    context "when fail! is called" do
      let(:actor_class) do
        Class.new(Actor) do
          def call
            fail!(error: "Ouch", some_other_key: 42)
          end
        end
      end

      it do
        expect { actor_class.call }
          .to raise_error(ServiceActor::Failure, "Ouch")
      end

      context "when a custom class is specified" do
        let(:actor_class) do
          Class.new(Actor) do
            self.failure_class = MyCustomFailure

            def call
              fail!(error: "Ouch", some_other_key: 42)
            end
          end
        end

        it do
          expect { actor_class.call }.to raise_error(MyCustomFailure, "Ouch")
        end
      end
    end

    context "when updating the context" do
      let(:actor_class) do
        Class.new(Actor) do
          output :name

          def call
            self.name = "Jim"
          end
        end
      end

      it { expect(actor_class.call.name).to eq("Jim") }
    end

    context "when updating the context with a hash" do
      let(:actor_class) do
        Class.new(Actor) do
          output :stuff, type: Hash

          def call
            self.stuff = {name: "Jim"}
          end
        end
      end

      it { expect(actor_class.call.stuff).to eq(name: "Jim") }
    end

    context "when using the same name for the input and output" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name
          output :name

          def call
            self.name = name.downcase
          end
        end
      end

      it { expect(actor_class.call(name: "JIM").name).to eq("jim") }
    end

    context "when given a context instead of a hash" do
      let(:actor_class) do
        Class.new(Actor) do
          output :name

          def call
            self.name = "Jim"
          end
        end
      end

      let(:context) { ServiceActor::Result.new(name: "Boo") }

      it do
        result = actor_class.call(context)
        expect(result.object_id).to eq(context.object_id)
        expect(result.name)
          .to eq(context.name)
          .and eq("Jim")
      end
    end

    context "when given a hash with string keys" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String
          output :name, type: String

          def call
            self.name = name.downcase
          end
        end
      end

      it { expect(actor_class.call({"name" => "Jim"}).name).to eq("jim") }
      it { expect(actor_class.call("name" => "Jim").name).to eq("jim") }
      it { expect(actor_class.call(**{"name" => "Jim"}).name).to eq("jim") }
    end

    context "when an actor changes a value" do
      let(:actor_class) do
        Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end
      end

      it { expect(actor_class.call(value: 1).value).to eq(2) }
    end

    context "when an input has a default" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, default: "world", type: String
          output :greeting, type: String

          def call
            self.greeting = "Hello, #{name}!"
          end
        end
      end

      it { expect(actor_class.call.name).to eq("world") }
      it { expect(actor_class.call.greeting).to eq("Hello, world!") }
      it { expect(actor_class.call(name: "jim").name).to eq("jim") }

      it do
        actor = actor_class.call(ServiceActor::Result.new(name: "jim"))
        expect(actor.name).to eq("jim")
      end
    end

    context "when an input has a default that is a hash" do
      let(:actor_class) do
        Class.new(Actor) do
          input :options, default: -> { {name: "world"} }
          output :greeting, type: String

          def call
            self.greeting = "Hello, #{options[:name]}!"
          end
        end
      end

      it { expect(actor_class.call.options).to eq({name: "world"}) }
      it { expect(actor_class.call.greeting).to eq("Hello, world!") }

      it do
        expect(actor_class.call(options: {name: "Alice"}).options)
          .to eq({name: "Alice"})
      end

      it do
        actor = actor_class.call(
          ServiceActor::Result.new(options: {name: "Alice"}),
        )
        expect(actor.options).to eq({name: "Alice"})
      end
    end

    context "when an input has a lambda default" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, default: -> { "world" }, type: String
          output :greeting, type: String

          def call
            self.greeting = "Hello, #{name}!"
          end
        end
      end

      it { expect(actor_class.call.name).to eq("world") }
      it { expect(actor_class.call.greeting).to eq("Hello, world!") }
    end

    context "when an output has a lambda default" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, default: "world", type: String

          output :greeting, type: String
          output :zero_arity_output_default, type: Integer, default: -> { 42 }
          output :one_arity_output_default,
                 type: String,
                 default: -> actor { actor.name + "!" }
          output :nested_lambda_default, type: Proc, default: -> { -> { 43 } }

          def call
            self.greeting = "Hello, #{name}!"
          end
        end
      end

      it do
        actor = actor_class.call

        expect(actor.zero_arity_output_default).to eq(42)
        expect(actor.one_arity_output_default).to eq("world!")
        expect(actor.nested_lambda_default.call).to eq(43)
      end

      context "when evaluating when lambda is executed" do
        let(:actor_class) do
          Class.new(Actor) do
            output :value, default: -> { raise "Reached" }

            play -> actor { actor.value = 42 }
          end
        end

        it "evaluates lambda default before the actor is executed" do
          expect { actor_class.call }.to raise_error(RuntimeError, "Reached")
        end
      end

      context "when there is a mismatch between output and default lambda" do
        let(:actor_class) do
          Class.new(Actor) do
            output :value, type: Integer, default: -> { "42" }
          end
        end

        it do
          expect { actor_class.call }.to raise_error(
            ServiceActor::ArgumentError,
            /The "value" output on ".+" must be of type "Integer" but was "String"/,
          )
        end
      end
    end

    context "when a lambda default references other inputs" do
      let(:actor_class) do
        Class.new(Actor) do
          input :num, type: Integer
          input :thingy, default: -> actor { "#{actor.num}.0" }, type: String
        end
      end

      it { expect(actor_class.call(num: 42).thingy).to eq("42.0") }
    end

    context "when an input has not been given" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name
        end
      end

      it do
        expect { actor_class.call }
          .to raise_error(
            ServiceActor::ArgumentError,
            /\AThe "name" input on ".+" is missing\z/,
          )
      end
    end

    context "when playing several actors" do
      let(:actor_class) do
        increment_value_class = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        Class.new(Actor) do
          play increment_value_class,
               increment_value_class
        end
      end

      it { expect(actor_class.call(value: 1).value).to eq(3) }
      it { expect(actor_class.call.value).to eq(2) }
    end

    context "when playing several actors where order is important" do
      let(:actor_class) do
        add_name_class = Class.new(Actor) do
          output :name

          def call
            self.name = "JIM"
          end
        end

        downcase_name_class = Class.new(Actor) do
          input :name
          output :name

          def call
            self.name = name.downcase
          end
        end

        Class.new(Actor) do
          play add_name_class,
               downcase_name_class
        end
      end

      it { expect(actor_class.call.name).to eq("jim") }
    end

    context "when using a parent that includes ServiceActor::Base" do
      let(:actor_class) do
        stripped_down_parent = Class.new do
          include ServiceActor::Base
        end

        stripped_down_class = Class.new(stripped_down_parent) do
          output :stripped_down_actor

          def call
            self.stripped_down_actor = true
          end
        end

        Class.new(Actor) do
          play stripped_down_class
        end
      end

      it { expect(actor_class.call.stripped_down_actor).to be(true) }
    end

    context "when playing actors and lambdas" do
      let(:actor_class) do
        increment_value_class = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        Class.new(Actor) do
          play -> actor { actor.value = 3 },
               increment_value_class,
               -> actor { actor.value *= 2 },
               -> _ { {value: "Does nothing"} },
               increment_value_class
        end
      end

      it { expect(actor_class.call.value).to eq((3 + 1) * 2 + 1) }
    end

    context "when playing actors and symbols" do
      let(:actor_class) do
        increment_value_class = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        Class.new(Actor) do
          output :value, type: Integer

          play :set_value,
               increment_value_class,
               :double_value,
               :do_nothing,
               increment_value_class

          private

          def set_value
            self.value = 3
          end

          def double_value
            self.value *= 2
          end

          def do_nothing
            {value: "Does nothing"}
          end
        end
      end

      it { expect(actor_class.call.value).to eq((3 + 1) * 2 + 1) }
    end

    context "when using `play` several times" do
      let(:actor_class) do
        increment_value_class = Class.new(Actor) do
          input :value
          output :value

          def call
            self.value += 1
          end
        end

        double_value_class = Class.new(Actor) do
          input :value
          output :value

          def call
            self.value *= 2
          end
        end

        Class.new(Actor) do
          output :value

          play increment_value_class,
               double_value_class

          play increment_value_class,
               double_value_class

          play increment_value_class
        end
      end

      it do
        expect(actor_class.call(value: 1).value)
          .to eq((((1 + 1) * 2) + 1) * 2 + 1)
      end
    end

    context "when using `play` with conditions" do
      let(:actor_class) do
        increment_value_class = Class.new(Actor) do
          input :value
          output :value

          def call
            self.value += 1
          end
        end

        Class.new(Actor) do
          input :value, default: 0
          input :name

          play increment_value_class

          play increment_value_class,
               if: -> actor { actor.name == "Jim" }

          play increment_value_class,
               increment_value_class,
               unless: -> actor { actor.name == "Tom" }
        end
      end

      it { expect(actor_class.call(name: "Jim").value).to eq(4) }
      it { expect(actor_class.call(name: "Tom").value).to eq(1) }
    end

    context "when using `play` with evaluated conditions" do
      let(:actor_class) do
        Class.new(Actor) do
          input :callable
          input :value, default: 1

          play -> actor { actor.value += 1 },
               -> actor { actor.value += 1 },
               -> actor { actor.value += 1 },
               if: -> actor { actor.callable.call }
        end
      end

      let(:actor) { actor_class.call(callable: callable) }
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
      let(:actor_class) do
        set_name = Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end

        increment_value_with_rollback = Class.new(Actor) do
          input :value, type: Integer
          output :value, type: Integer

          def call
            self.value += 1
          end

          def rollback
            self.value -= 1
          end
        end

        fail_with_error = Class.new(Actor) do
          def call
            fail!(error: "Ouch")
          end
        end

        Class.new(Actor) do
          input :value, type: Integer
          output :value, type: Integer
          output :name, type: String

          play set_name,
               increment_value_with_rollback,
               increment_value_with_rollback,
               fail_with_error,
               increment_value_with_rollback
        end
      end

      let(:actor) { ServiceActor::Result.new(value: 0) }

      it "changes the context up to the failure then calls rollbacks" do
        expect { actor_class.call(actor) }
          .to raise_error(ServiceActor::Failure, "Ouch")

        expect(actor.name).to eq("Jim")
        expect(actor.value).to eq(0)
      end
    end

    context "when playing several actors, one fails, one rolls back" do
      let(:actor_class) do
        catch_error_in_rollback = Class.new(Actor) do
          output :called
          output :found_error

          def call
            self.called = true
          end

          def rollback
            self.found_error = "Found “#{result.error}”"
          end
        end

        fail_with_error = Class.new(Actor) do
          def call
            fail!(error: "Ouch", some_other_key: 42)
          end
        end

        Class.new(Actor) do
          play catch_error_in_rollback,
               fail_with_error
        end
      end

      it "catches the error inside the rollback" do
        actor = actor_class.result

        expect(actor.called).to be(true)
        expect(actor.found_error).to eq("Found “Ouch”")
        expect(actor.some_other_key).to eq(42)
      end
    end

    context "when playing actors and alias_input" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name_to_downcase = Class.new(Actor) do
          input :name, type: String
          output :name, type: String

          def call
            self.name = name.downcase
          end
        end

        Class.new(Actor) do
          output :name, type: String

          play increment_value,
               -> actor { actor.orig_name = "Jim number #{actor.value}" },
               alias_input(name: :orig_name),
               set_name_to_downcase
        end
      end

      it "calls the actors and can be referenced by alias" do
        actor = actor_class.call
        expect(actor.name).to eq("jim number 1")
      end
    end

    context "when called with a matching condition" do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, must: {be_lowercase: -> name { name =~ /\A[a-z]+\z/ }}
            output :name

            def call
              self.name = name.upcase
            end
          end
        end

        it { expect(actor_class.call(name: "joe").name).to eq("JOE") }
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name,
                  must: {be_lowercase: {is: -> name { name =~ /\A[a-z]+\z/ }}}
            output :name

            def call
              self.name = name.upcase
            end
          end
        end

        it { expect(actor_class.call(name: "joe").name).to eq("JOE") }
      end
    end

    context "when called with the wrong condition" do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, must: {be_lowercase: -> name { name =~ /\A[a-z]+\z/ }}
            output :name

            def call
              self.name = name.upcase
            end
          end
        end

        it do
          expect { actor_class.call(name: "42") }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "name" input on ".+" must "be_lowercase" but was "42"\z/,
            )
        end
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name,
                  must: {
                    be_lowercase: {
                      is: -> name { name =~ /\A[a-z]+\z/ },
                      message: (lambda do |check_name:, **|
                        "Failed to apply `#{check_name}`"
                      end),
                    },
                  }

            output :name
          end
        end

        it do
          expect { actor_class.call(name: "42") }
            .to raise_error(
              ServiceActor::ArgumentError,
              "Failed to apply `be_lowercase`",
            )
        end
      end
    end

    context "when called with an error in the code" do
      let(:actor_class) do
        Class.new(Actor) do
          input :per_page,
                type: Integer,
                must: {
                  be_in_range: {
                    is: -> per_page { per_page.between?(3, 9) },
                    message: -> value:, ** { "Wrong range (3-9): #{value}" },
                  },
                }
        end
      end

      context "when type is first" do
        context "when advanced mode" do
          it do
            expect { actor_class.call(per_page: "6") }
              .to raise_error(
                ServiceActor::ArgumentError,
                /\AThe "per_page" input on ".*" must be of type "Integer" but was "String"\z/,
              )
          end
        end
      end

      context "when type is last in advanced mode and expected fail" do
        let(:actor_class) do
          Class.new(Actor) do
            input :per_page,
                  must: {
                    be_in_range: {
                      is: -> per_page { per_page.between?(3, 9) },
                      message: -> value:, ** { "Wrong range (3-9): #{value}" },
                    },
                  },
                  type: Integer

            def call; end
          end
        end

        it do
          expect { actor_class.call(per_page: "6") }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "per_page" input on ".+" has an error in the code inside "be_in_range": \[ArgumentError\] comparison of String with 3 failed\z/,
            )
        end
      end
    end

    context "when called with the wrong type of argument" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String
          output :name

          def call
            self.name = name.downcase
          end
        end
      end

      it do
        expect { actor_class.call(name: 1) }
          .to raise_error(
            ServiceActor::ArgumentError,
            /\AThe "name" input on ".+" must be of type "String" but was "Integer"\z/,
          )
      end
    end

    context "when a type is defined but the argument is nil" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String
          output :name

          def call
            self.name = name.downcase
          end
        end
      end

      it do
        expect { actor_class.call(name: nil) }
          .to raise_error(
            ServiceActor::ArgumentError,
            /\AThe "name" input on ".+" does not allow nil values\z/,
          )
      end
    end

    context "when called with a type as a string instead of a class" do
      let(:actor_class) do
        Class.new(Actor) do
          input :value, type: [Integer, "Float"]
          output :double

          def call
            self.double = value * 2
          end
        end
      end

      it { expect(actor_class.call(value: 2.0).double).to eq(4.0) }

      it do
        expect { actor_class.call(value: "2.0") }
          .to raise_error(
            ServiceActor::ArgumentError,
            /\AThe "value" input on ".+" must be of type "Integer, Float" but was "String"\z/,
          )
      end

      context "with custom message" do
        let(:actor_class) do
          Class.new(Actor) do
            input :value,
                  type: {
                    is: [Integer, "Float"],
                    message: (lambda do |input_key:, expected_type:, given_type:, **|
                      "Wrong type `#{given_type}` for `#{input_key}`. " \
                        "Expected: `#{expected_type}`"
                    end),
                  }
            output :double

            def call
              self.double = value * 2
            end
          end
        end

        it do
          expect { actor_class.call(value: "2.0") }
            .to raise_error(
              ServiceActor::ArgumentError,
              "Wrong type `String` for `value`. Expected: `Integer, Float`",
            )
        end
      end
    end

    context "when setting the wrong type of output" do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            output :name, type: String

            def call
              self.name = 42
            end
          end
        end

        let(:expected_message) do
          /\AThe "name" output on ".+" must be of type "String" but was "Integer"\z/
        end

        it do
          expect { actor_class.call }
            .to raise_error(ServiceActor::ArgumentError, expected_message)
        end
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            output :name,
                   type: {
                     is: String,
                     message: (lambda do |input_key:, expected_type:, given_type:, **|
                       "Wrong type `#{given_type}` for `#{input_key}`. " \
                         "Expected: `#{expected_type}`"
                     end),
                   }
            def call
              self.name = 42
            end
          end
        end

        let(:expected_message) do
          "Wrong type `Integer` for `name`. Expected: `String`"
        end

        it do
          expect { actor_class.call }
            .to raise_error(ServiceActor::ArgumentError, expected_message)
        end
      end

      context "when a custom class is specified" do
        let(:actor_class) do
          Class.new(Actor) do
            self.argument_error_class = MyCustomArgumentError

            output :name, type: String

            def call
              self.name = 42
            end
          end
        end

        let(:expected_message) do
          /\AThe "name" output on ".+" must be of type "String" but was "Integer"\z/
        end

        it do
          expect { actor_class.call }
            .to raise_error(MyCustomArgumentError, expected_message)
        end
      end
    end

    context "with generic type" do
      before do
        stub_const(
          "InternType",
          Object.new.tap do |object|
            class << object
              def ===(value)
                value.is_a?(String) || value.is_a?(Symbol)
              end

              def name
                "InternType"
              end
            end
          end,
        )
      end

      let(:actor) do
        Class.new(Actor) do
          input :value, type: InternType
          output :value, type: InternType

          play -> actor { actor.value = actor.value.succ }
        end
      end

      it "acceptss value satisfying generic type" do
        expect(actor.call(value: :foo).value).to eq(:foo.succ)
        expect(actor.call(value: "foo").value).to eq("foo".succ)
      end

      it "raises when provided value does not match generic type" do
        expect { actor.call(value: 1) }.to raise_error(
          ServiceActor::ArgumentError,
          /The "value" input on .+ must be of type "InternType" but was "Integer"/,
        )
      end
    end

    context "when accessing origins multiple times" do
      let(:actor_class) do
        Class.new(Actor) do
          input :value

          output :value_result
          output :output_with_default, allow_nil: true, default: 42

          play -> actor { actor.value_result = actor.value.succ }
          play -> actor { actor.value_result += 1 }
        end
      end

      it do
        expect(actor_class.call(value: 0).value_result).to eq(2)
        expect(actor_class.call(value: 0).output_with_default).to eq(42)
      end
    end

    context "when setting an unknown output" do
      let(:actor_class) do
        Class.new(Actor) do
          output :name

          def call
            self.foobar = 42
          end
        end
      end

      it do
        expect { actor_class.call }
          .to raise_error(NoMethodError, /undefined method ['`]foobar='/)
      end
    end

    context "when reading an output" do
      let(:actor_class) do
        Class.new(Actor) do
          output :nickname
          output :email

          def call
            self.nickname = "jim"
            self.email = "#{nickname}@example.org"
          end
        end
      end

      it { expect(actor_class.result.email).to eq("jim@example.org") }
    end

    context "when disallowing nil on an input" do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, type: String, allow_nil: false

            def call; end
          end
        end

        context "when given the input" do
          it { expect(actor_class.call(name: "Jim")).to be_a_success }
        end

        context "without the input" do
          it "fails" do
            expect { actor_class.call(name: nil) }
              .to raise_error(
                ServiceActor::ArgumentError,
                /\AThe "name" input on ".+" does not allow nil values\z/,
              )
          end
        end
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name,
                  type: String,
                  allow_nil: {
                    is: false,
                    message: (lambda do |input_key:, **|
                      "The value `#{input_key}` cannot be empty"
                    end),
                  }

            def call; end
          end
        end

        context "when given the input" do
          it { expect(actor_class.call(name: "Jim")).to be_a_success }
        end

        context "without the input" do
          it do
            expect { actor_class.call(name: nil) }
              .to raise_error(
                ServiceActor::ArgumentError,
                "The value `name` cannot be empty",
              )
          end
        end
      end
    end

    context "when setting a default to nil and a type on an input" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String, default: nil
        end
      end

      context "when given the input" do
        it "succeeds" do
          expect(actor_class.call(name: "Jim"))
            .to be_a_success
        end
      end

      context "when not given any input" do
        it "succeeds" do
          expect(actor_class.call).to be_a_success
        end
      end
    end

    context "when disallowing nil on an output" do
      let(:actor_class) do
        Class.new(Actor) do
          output :name, allow_nil: false

          def call
            self.name = "Jim"
          end
        end
      end

      context "when set correctly" do
        it { expect(actor_class.call).to be_a_success }
      end

      context "without the output" do
        let(:actor_class) do
          Class.new(Actor) do
            output :name, allow_nil: false

            def call
              self.name = nil
            end
          end
        end

        it "fails" do
          expect { actor_class.call }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "name" output on ".+" does not allow nil values\z/,
            )
        end
      end
    end

    context "when inheriting" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        Class.new(increment_value) do
          def call
            super

            self.value += 1
          end
        end
      end

      it "calls both the parent and child" do
        expect(actor_class.call(value: 0).value).to eq(2)
      end
    end

    context "when inheriting from play" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name = Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end

        set_name_to_downcase = Class.new(Actor) do
          input :name, type: String
          output :name

          def call
            self.name = name.downcase
          end
        end

        use_stripped_down_actor_test_app = Class.new do
          include ServiceActor::Base
        end

        use_stripped_down_actor = Class.new(use_stripped_down_actor_test_app) do
          output :stripped_down_actor

          def call
            self.stripped_down_actor = true
          end
        end

        do_nothing = Class.new(Actor)

        play_actors = Class.new(Actor) do
          play increment_value,
               do_nothing,
               set_name,
               set_name_to_downcase,
               use_stripped_down_actor,
               increment_value
        end

        Class.new(play_actors) do
          play increment_value
        end
      end

      it "calls both the parent and child" do
        expect(actor_class.call(value: 0).value).to eq(3)
      end
    end

    context "with inclusion" do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :provider,
                  inclusion: %w[MANGOPAY PayPal Stripe],
                  default: "Stripe"
            output :message, type: String

            def call
              self.message = "Money transferred to #{provider}!"
            end
          end
        end

        it "accepts correct values" do
          expect(actor_class.call(provider: "PayPal").message)
            .to eq("Money transferred to PayPal!")
        end

        it "raises on incorrect values" do
          expect { actor_class.call(provider: "Paypal") }
            .to raise_error(
              /\AThe "provider" input must be included in \["MANGOPAY", "PayPal", "Stripe"\] on ".+" instead of "Paypal"\z/,
            )
        end

        it "uses defaults" do
          expect(actor_class.call.message)
            .to eq("Money transferred to Stripe!")
        end
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :provider,
                  inclusion: {
                    in: %w[MANGOPAY PayPal Stripe],
                    message: (lambda do |value:, **|
                      "Payment system \"#{value}\" is not supported"
                    end),
                  },
                  default: "Stripe"

            output :message, type: String

            def call
              self.message = "Money transferred to #{provider}!"
            end
          end
        end

        context "when given a correct value" do
          it do
            actor = actor_class.call(provider: "PayPal")
            expect(actor.message).to eq("Money transferred to PayPal!")
          end
        end

        context "when given an incorrect value" do
          it do
            expect { actor_class.call(provider: "Paypal") }
              .to raise_error("Payment system \"Paypal\" is not supported")
          end
        end

        context "when it has a default" do
          it do
            actor = actor_class.call
            expect(actor.message).to eq("Money transferred to Stripe!")
          end
        end
      end

      context "when using allow_nil" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, inclusion: %w[abc def], allow_nil: true
          end
        end

        context "when not given a value" do
          it do
            expect { actor_class.call }
              .to raise_error(ServiceActor::ArgumentError)
          end
        end

        context "when given a nil value" do
          it "accepts it" do
            actor = actor_class.call(name: nil)
            expect(actor.name).to be_nil
          end
        end

        context "when given an allowed value" do
          it "accepts it" do
            actor = actor_class.call(name: "abc")
            expect(actor.name).to eq("abc")
          end
        end
      end
    end

    context "with must, type, default and allow_nil" do
      let(:actor_class) do
        Class.new(Actor) do
          input :weekdays,
                type: Array,
                allow_nil: true,
                default: [0, 1, 2, 3, 4].freeze,
                must: {
                  be_valid: lambda do |numbers|
                    numbers.nil? || numbers.all? { |number| (0..6).cover?(number) }
                  end,
                }
          def call; end
        end
      end

      context "when not given a value" do
        it do
          actor = actor_class.call
          expect(actor.weekdays).to eq([0, 1, 2, 3, 4])
        end
      end

      context "when given a nil value" do
        it do
          actor = actor_class.call(weekdays: nil)
          expect(actor.weekdays).to be_nil
        end
      end
    end

    context "when using type, inclusion, allow_nil and nil default" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name,
                type: String,
                inclusion: %w[abc def],
                allow_nil: true,
                default: nil
        end
      end

      it { expect(actor_class.call.name).to be_nil }
      it { expect(actor_class.call(name: nil).name).to be_nil }
      it { expect(actor_class.call(name: "abc").name).to eq("abc") }
    end

    context "when using type, inclusion, must and nil default" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name,
                type: String,
                must: {be_valid: -> v { v == "abc" }},
                allow_nil: true,
                default: nil
        end
      end

      it { expect(actor_class.call.name).to be_nil }
      it { expect(actor_class.call(name: nil).name).to be_nil }
      it { expect(actor_class.call(name: "abc").name).to eq("abc") }
    end

    context 'when using "in"' do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :provider, in: %w[MANGOPAY PayPal Stripe], default: "Stripe"
            output :message, type: String

            def call
              self.message = "Money transferred to #{provider}!"
            end
          end
        end

        it "accepts correct values" do
          actor = actor_class.call(provider: "PayPal")
          expect(actor.message).to eq("Money transferred to PayPal!")
        end

        it "rejects incorrect values" do
          expect { actor_class.call(provider: "Paypal") }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "provider" input must be included in \["MANGOPAY", "PayPal", "Stripe"\] on ".+" instead of "Paypal"\z/,
            )
        end

        it "uses defaults" do
          expect(actor_class.call.message).to eq("Money transferred to Stripe!")
        end
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :provider,
                  inclusion: {
                    in: %w[MANGOPAY PayPal Stripe],
                    message: (lambda do |value:, **|
                      "Payment system \"#{value}\" is not supported"
                    end),
                  },
                  default: "Stripe"

            output :message, type: String

            def call
              self.message = "Money transferred to #{provider}!"
            end
          end
        end

        context "when given a correct value" do
          it do
            actor = actor_class.call(provider: "PayPal")
            expect(actor.message).to eq("Money transferred to PayPal!")
          end
        end

        context "when given an incorrect value" do
          it do
            expect { actor_class.call(provider: "Paypal") }
              .to raise_error(
                ServiceActor::ArgumentError,
                "Payment system \"Paypal\" is not supported",
              )
          end
        end

        context "when it has a default" do
          it do
            actor = actor_class.call
            expect(actor.message).to eq("Money transferred to Stripe!")
          end
        end
      end
    end

    context "when playing interactors" do
      let(:actor_class) do
        increment_value_with_interactor = Class.new do
          include Interactor

          def call
            context.value += 1
          end
        end

        Class.new(Actor) do
          input :value, default: 1
          output :value

          play increment_value_with_interactor,
               increment_value_with_interactor
        end
      end

      it { expect(actor_class.call(value: 5).value).to eq(5 + 2) }
    end

    context "when playing a failing interactor" do
      let(:actor_class) do
        increment_value_with_interactor = Class.new do
          include Interactor

          def call
            context.value += 1
          end
        end

        fail_with_interactor = Class.new do
          include Interactor

          def call
            context.fail!(error: "Failed with Interactor")
          end
        end

        Class.new(Actor) do
          input :value, default: 1
          output :value

          play increment_value_with_interactor,
               fail_with_interactor,
               increment_value_with_interactor
        end
      end

      it do
        actor = actor_class.result(value: 5)
        expect(actor).to be_a_failure
        expect(actor.error).to eq("Failed with Interactor")
        expect(actor.value).to eq(5 + 1)
      end
    end

    context "when using advanced mode with checks and not adding message key" do
      context "when using inclusion check" do
        let(:actor_class) do
          Class.new(Actor) do
            input :provider, inclusion: {in: %w[MANGOPAY PayPal Stripe]}
          end
        end

        it do
          expect { actor_class.call(provider: "Paypal2") }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "provider" input must be included in \["MANGOPAY", "PayPal", "Stripe"\] on ".+" instead of "Paypal2"\z/,
            )
        end
      end

      context "when using type check" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, type: {is: String}
          end
        end

        it do
          expect { actor_class.call(name: 2) }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "name" input on ".+" must be of type "String" but was "Integer"\z/,
            )
        end
      end

      context "when using must check" do
        let(:actor_class) do
          Class.new(Actor) do
            input :num, must: {be_smaller: {is: -> name { name < 5 }}}
          end
        end

        it do
          expect { actor_class.call(num: 6) }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "num" input on ".+" must "be_smaller" but was 6\z/,
            )
        end
      end

      context "when using nil check" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, allow_nil: {is: false}
          end
        end

        it do
          expect { actor_class.call(name: nil) }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "name" input on ".+" does not allow nil values\z/,
            )
        end
      end
    end

    context "with unset output and allow_nil: true" do
      let(:actor_class) do
        Class.new(Actor) do
          output :value, type: String, allow_nil: true
        end
      end

      it do
        actor = actor_class.result

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

      it do
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

      it do
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

      it do
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
      let(:actor_class) { Class.new(Actor) }
      let(:actor) { actor_class.result }

      it { expect(actor).to be_a(ServiceActor::Result) }
      it { expect(actor).to be_a_success }
      it { expect(actor).not_to be_a_failure }
    end

    context "when fail! is called" do
      let(:error_class) do
        Class.new(Actor) do
          def call
            fail!(error: "Ouch", some_other_key: 42)
          end
        end
      end

      let(:actor) { error_class.result }

      it { expect(actor).to be_a(ServiceActor::Result) }
      it { expect(actor).to be_a_failure }
      it { expect(actor).not_to be_a_success }
      it { expect(actor.error).to eq("Ouch") }
      it { expect(actor.some_other_key).to eq(42) }
    end

    context "with an argument error, caught by fail_on" do
      let(:actor_class) do
        Class.new(Actor) do
          fail_on ServiceActor::ArgumentError

          input :name, type: String, allow_nil: false

          def call; end
        end
      end

      it do
        actor = actor_class.result(name: 42)

        expect(actor).to be_a_failure
        expect(actor.error).to match(
          /\AThe "name" input on ".+" must be of type "String" but was "Integer"\z/,
        )
      end
    end

    context "when playing several actors" do
      let(:actor_class) do
        increment_value_class = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        Class.new(Actor) do
          play increment_value_class,
               increment_value_class
        end
      end

      it { expect(actor_class.result(value: 1).value).to eq(3) }
    end

    context "when playing several actors with a rollback and one fails" do
      let(:actor_class) do
        set_name = Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end

        increment_value_with_rollback = Class.new(Actor) do
          input :value, type: Integer
          output :value, type: Integer

          def call
            self.value += 1
          end

          def rollback
            self.value -= 1
          end
        end

        fail_with_error = Class.new(Actor) do
          def call
            fail!(error: "Ouch", some_other_key: 42)
          end
        end

        Class.new(Actor) do
          input :value, type: Integer
          output :value, type: Integer
          output :name, type: String

          play set_name,
               increment_value_with_rollback,
               increment_value_with_rollback,
               fail_with_error,
               increment_value_with_rollback
        end
      end

      let(:actor) { actor_class.result(value: 0) }

      it { expect(actor).to be_a_failure }
      it { expect(actor).not_to be_a_success }
      it { expect(actor.name).to eq("Jim") }
      it { expect(actor.value).to eq(0) }
    end

    context "when sending unexpected messages" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name = Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end

        set_name_to_downcase = Class.new(Actor) do
          input :name, type: String
          output :name

          def call
            self.name = name.downcase
          end
        end

        use_stripped_down_actor_test_app = Class.new do
          include ServiceActor::Base
        end

        use_stripped_down_actor = Class.new(use_stripped_down_actor_test_app) do
          output :stripped_down_actor

          def call
            self.stripped_down_actor = true
          end
        end

        do_nothing = Class.new(Actor)

        Class.new(Actor) do
          play increment_value,
               do_nothing,
               set_name,
               set_name_to_downcase,
               use_stripped_down_actor,
               increment_value
        end
      end

      let(:actor) { actor_class.result(value: 42) }

      it { expect(actor).to be_a_success }
      it { expect(actor).to respond_to(:name) }
      it { expect(actor).to respond_to(:name?) }
      it { expect(actor.name).to eq("jim") }

      it { expect(actor).not_to respond_to(:unknown_method) }
      it { expect(actor).not_to respond_to(:unknown_method?) }

      it "raises upon receiving unexpected messages" do
        expect { actor.unknown_method }
          .to raise_error(NoMethodError, /\Aundefined method ['`]unknown_method'/)
      end

      it "raises upon receiving unexpected predicate messages" do
        expect { actor.unknown_method? }
          .to raise_error(NoMethodError, /\Aundefined method ['`]unknown_method\?'/)
      end
    end

    context "when using pattern matching" do
      let(:actor_class) do
        Class.new(Actor) do
          input :month, type: Integer

          output :message, type: String

          def call
            if month < 1 || month > 12
              fail!(reason: :invalid_month)
            elsif month == 12
              self.message = "Come next year!"
              fail!(reason: :holidays)
            else
              self.message = "Welcome!"
            end
          end
        end
      end

      let(:successful_result) { actor_class.result(month: 2) }
      let(:holidays_result) { actor_class.result(month: 12) }
      let(:invalid_result) { actor_class.result(month: -1) }

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

      it { expect(match_result(successful_result)).to eq "Welcome!" }
      it { expect(match_result(holidays_result)).to eq "Come next year!" }
      it { expect(match_result(invalid_result)).to be_nil }
    end
  end

  describe "#value" do
    context "when fail! is not called" do
      let(:actor_class) { Class.new(Actor) }

      it { expect(actor_class.value).to be_nil }
    end

    context "when fail! is called" do
      let(:actor_class) do
        Class.new(Actor) do
          def call
            fail!(error: "Ouch")
          end
        end
      end

      it do
        expect { actor_class.value }
          .to raise_error(ServiceActor::Failure, "Ouch")
      end

      context "when a custom class is specified" do
        let(:actor_class) do
          Class.new(Actor) do
            self.failure_class = MyCustomFailure

            def call
              fail!(error: "Ouch", some_other_key: 42)
            end
          end
        end

        it do
          expect { actor_class.value }.to raise_error(MyCustomFailure, "Ouch")
        end
      end
    end

    context "when an actor updates the context using value" do
      let(:actor_class) do
        Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end
      end

      it { expect(actor_class.value).to eq("Jim") }
    end

    context "when updating the context with a hash" do
      let(:actor_class) do
        Class.new(Actor) do
          output :stuff, type: Hash

          def call
            self.stuff = {name: "Jim"}
          end
        end
      end

      it { expect(actor_class.value).to eq(name: "Jim") }
    end

    context "when an actor uses a method named after the input" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String
          output :name

          def call
            self.name = name.downcase
          end
        end
      end

      it { expect(actor_class.value(name: "JIM")).to eq("jim") }
    end

    context "when given a context instead of a hash" do
      let(:actor_class) do
        Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end
      end

      it "returns the value of the context" do
        actor = ServiceActor::Result.new(name: "Jim")

        expect(actor_class.value(actor)).to eq("Jim")
      end
    end

    context "when an actor changes a value" do
      let(:actor_class) do
        Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end
      end

      it { expect(actor_class.value(value: 1)).to eq(2) }
    end

    context "when an input has a default" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String, default: "world"
          output :greeting, type: String

          def call
            self.greeting = "Hello, #{name}!"
          end
        end
      end

      it { expect(actor_class.value).to eq("Hello, world!") }
      it { expect(actor_class.value(name: "Jim")).to eq("Hello, Jim!") }

      it do
        expect(actor_class.value(ServiceActor::Result.new(name: "jim")))
          .to eq("Hello, jim!")
      end
    end

    context "when an input has a default that is a hash" do
      let(:actor_class) do
        Class.new(Actor) do
          input :options, default: -> { {name: "world"} }
          output :greeting, type: String

          def call
            self.greeting = "Hello, #{options[:name]}!"
          end
        end
      end

      it { expect(actor_class.value).to eq("Hello, world!") }

      it do
        expect(actor_class.value(options: {name: "Alice"}))
          .to eq("Hello, Alice!")
      end

      it do
        output = actor_class.value(
          ServiceActor::Result.new(options: {name: "Alice"}),
        )
        expect(output).to eq("Hello, Alice!")
      end
    end

    context "when an input has a lambda default" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, default: -> { "world" }, type: String
          output :greeting, type: String

          def call
            self.greeting = "Hello, #{name}!"
          end
        end
      end

      it { expect(actor_class.value).to eq("Hello, world!") }
    end

    context "when a lambda default references other inputs" do
      let(:actor_class) do
        Class.new(Actor) do
          input :num, type: Integer
          input :thingy, default: -> actor { "#{actor.num}.0" }, type: String

          def call
            thingy
          end
        end
      end

      it { expect(actor_class.value(num: 42)).to eq("42.0") }
    end

    context "when an input has not been given" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String
          output :name

          def call
            self.name = name.downcase
          end
        end
      end

      it do
        expect { actor_class.value }
          .to raise_error(
            ServiceActor::ArgumentError,
            /\AThe "name" input on ".+" is missing\z/,
          )
      end
    end

    context "when playing several actors" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name = Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end

        set_name_to_downcase = Class.new(Actor) do
          input :name, type: String
          output :name

          def call
            self.name = name.downcase
          end
        end

        use_stripped_down_actor_test_app = Class.new do
          include ServiceActor::Base
        end

        use_stripped_down_actor = Class.new(use_stripped_down_actor_test_app) do
          output :stripped_down_actor

          def call
            self.stripped_down_actor = true
          end
        end

        do_nothing = Class.new(Actor)

        Class.new(Actor) do
          play increment_value,
               do_nothing,
               set_name,
               set_name_to_downcase,
               use_stripped_down_actor,
               increment_value
        end
      end

      it "returns the result of the last actor" do
        expect(actor_class.value(value: 1)).to eq(3)
      end

      context "when not providing arguments" do
        it "uses defaults from the inner actors" do
          expect(actor_class.value).to eq(2)
        end
      end
    end

    context "when playing actors and lambdas" do
      let(:actor_class) do
        increment_value_class = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        Class.new(Actor) do
          play -> actor { actor.value = 3 },
               increment_value_class,
               -> actor { actor.value *= 2 },
               -> _ { {value: "Does nothing"} },
               increment_value_class
        end
      end

      it { expect(actor_class.value).to eq((3 + 1) * 2 + 1) }
    end

    context "when playing actors and symbols" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name_to_downcase = Class.new(Actor) do
          input :name, type: String
          output :name, type: String

          def call
            self.name = name.downcase
          end
        end

        Class.new(Actor) do
          output :value, type: Integer
          output :name, type: String

          play :set_value,
               increment_value,
               :set_name,
               :do_nothing,
               set_name_to_downcase

          private

          def set_value
            self.value = 3
          end

          def set_name
            self.name = "Jim number #{value}"
          end

          def do_nothing
            {name: "Does nothing"}
          end
        end
      end

      it "calls the actors and symbols in order and returns the final value" do
        expect(actor_class.value).to eq("jim number 4")
      end
    end

    context "when using `play` several times" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name = Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end

        set_name_to_downcase = Class.new(Actor) do
          input :name, type: String
          output :name, type: String

          def call
            self.name = name.downcase
          end
        end

        do_nothing = Class.new(Actor)

        Class.new(Actor) do
          input :value, default: 1
          output :value
          output :name

          play increment_value,
               do_nothing

          play set_name,
               set_name_to_downcase

          play increment_value
        end
      end

      it "shares the result between actors and returns the final value" do
        expect(actor_class.value(value: 1)).to eq(3)
      end
    end

    context "when using `play` with conditions" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name = Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end

        fail_with_error = Class.new(Actor) do
          def call
            fail!(error: "Ouch")
          end
        end

        Class.new(Actor) do
          input :value, default: 1

          play set_name
          play increment_value, if: -> actor { actor.name == "Jim" }
          play increment_value, unless: -> actor { actor.name == "Tom" }
          play fail_with_error, if: -> _ { false }
          play fail_with_error, unless: -> _ { true }
        end
      end

      it "does not trigger actors with conditions and returns the final value" do
        expect(actor_class.value).to eq(3)
      end
    end

    context "when using `play` with evaluated conditions" do
      let(:actor_class) do
        Class.new(Actor) do
          input :callable
          input :value, default: 1

          play -> actor { actor.value += 1 },
               -> actor { actor.value += 1 },
               -> actor { actor.value += 1 },
               if: -> actor { actor.callable.call }
        end
      end

      let(:callable) { double :callable }

      before do
        allow(callable).to receive(:call).and_return(true)
      end

      it "does not evaluate conditions multiple times" do
        expect(actor_class.value(callable: callable)).to eq(4)
        expect(callable).to have_received(:call).once
      end
    end

    context "when playing actors and alias_input" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name_to_downcase = Class.new(Actor) do
          input :name, type: String
          output :name, type: String

          def call
            self.name = name.downcase
          end
        end

        Class.new(Actor) do
          output :name, type: String

          play increment_value,
               -> actor { actor.orig_name = "Jim number #{actor.value}" },
               alias_input(name: :orig_name),
               set_name_to_downcase
        end
      end

      it "calls the actors and can be referenced by alias" do
        expect(actor_class.value).to eq("jim number 1")
      end
    end

    context "when value'd with a matching condition" do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, must: {be_lowercase: -> name { name =~ /\A[a-z]+\z/ }}
            output :name

            def call
              self.name = name.upcase
            end
          end
        end

        it { expect(actor_class.value(name: "joe")).to eq("JOE") }
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name,
                  must: {be_lowercase: {is: -> name { name =~ /\A[a-z]+\z/ }}}
            output :name

            def call
              name.upcase
            end
          end
        end

        it { expect(actor_class.value(name: "joe")).to eq("JOE") }
      end
    end

    context "when value'd with the wrong condition" do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, must: {be_lowercase: -> name { name =~ /\A[a-z]+\z/ }}
            output :name

            def call
              self.name = name.upcase
            end
          end
        end

        it do
          expect { actor_class.value(name: "42") }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "name" input on ".+" must "be_lowercase" but was "42"\z/,
            )
        end
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name,
                  must: {
                    be_lowercase: {
                      is: -> name { name =~ /\A[a-z]+\z/ },
                      message: (lambda do |check_name:, **|
                        "Failed to apply `#{check_name}`"
                      end),
                    },
                  }
            output :name

            def call
              self.name = name.upcase
            end
          end
        end

        it do
          expected_error = "Failed to apply `be_lowercase`"

          expect { actor_class.value(name: "42") }
            .to raise_error(ServiceActor::ArgumentError, expected_error)
        end
      end
    end

    context "when value'd with an error in the code" do
      let(:actor_class) do
        Class.new(Actor) do
          input :per_page,
                type: Integer,
                must: {
                  be_in_range: {
                    is: -> per_page { per_page.between?(3, 9) },
                    message: -> value:, ** { "Wrong range (3-9): #{value}" },
                  },
                }
        end
      end

      it do
        expect { actor_class.value(per_page: "6") }
          .to raise_error(
            ServiceActor::ArgumentError,
            /The "per_page" input on ".+" must be of type "Integer" but was "String"/,
          )
      end
    end

    context "when value'd with the wrong type of argument" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String
          output :name, type: String

          def call
            self.name = name.downcase
          end
        end
      end

      it do
        expect { actor_class.value(name: 1) }
          .to raise_error(
            ServiceActor::ArgumentError,
            /\AThe "name" input on ".+" must be of type "String" but was "Integer"\z/,
          )
      end
    end

    context "when a type is defined but the argument is nil" do
      let(:actor_class) do
        Class.new(Actor) do
          input :name, type: String
          output :name, type: String

          def call
            self.name = name.downcase
          end
        end
      end

      it do
        expect { actor_class.value(name: nil) }
          .to raise_error(
            ServiceActor::ArgumentError,
            /\AThe "name" input on ".+" does not allow nil values\z/,
          )
      end
    end

    context "when called with a type as a string instead of a class" do
      let(:actor_class) do
        Class.new(Actor) do
          input :value, type: [Integer, "Float"]
          output :double

          def call
            self.double = value * 2
          end
        end
      end

      it { expect(actor_class.value(value: 2.0)).to eq(4.0) }
    end

    context "when disallowing nil on an input" do
      context "when normal mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, type: String, allow_nil: false

            def call; end
          end
        end

        context "when given the input" do
          it { expect(actor_class.value(name: "Jim")).to be_nil }
        end

        context "without the input" do
          it do
            expect { actor_class.value(name: nil) }
              .to raise_error(
                ServiceActor::ArgumentError,
                /\AThe "name" input on ".+" does not allow nil values\z/,
              )
          end
        end
      end

      context "when advanced mode" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name,
                  type: String,
                  allow_nil: {
                    is: false,
                    message: (lambda do |input_key:, **|
                      "The value `#{input_key}` cannot be empty"
                    end),
                  }

            def call; end
          end
        end

        context "when given the input" do
          it { expect(actor_class.value(name: "Jim")).to be_nil }
        end

        context "without the input" do
          it do
            expect { actor_class.value(name: nil) }
              .to raise_error(
                ServiceActor::ArgumentError,
                "The value `name` cannot be empty",
              )
          end
        end
      end
    end

    context "when disallowing nil on an output" do
      let(:actor_class) do
        Class.new(Actor) do
          output :name, allow_nil: false

          def call
            self.name = "Jim"
          end
        end
      end

      context "when set correctly" do
        it { expect(actor_class.value).to eq("Jim") }
      end

      context "without the output" do
        let(:actor_class) do
          Class.new(Actor) do
            output :name, allow_nil: false

            def call
              self.name = nil
            end
          end
        end

        it "fails" do
          expect { actor_class.call }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "name" output on ".+" does not allow nil values\z/,
            )
        end
      end
    end

    context "when inheriting" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        Class.new(increment_value) do
          def call
            super

            self.value += 1
          end
        end
      end

      it "calls both the parent and child" do
        expect(actor_class.value(value: 0)).to eq(2)
      end
    end

    context "when inheriting from play" do
      let(:actor_class) do
        increment_value = Class.new(Actor) do
          input :value, type: Integer, default: 0
          output :value, type: Integer

          def call
            self.value += 1
          end
        end

        set_name = Class.new(Actor) do
          output :name, type: String

          def call
            self.name = "Jim"
          end
        end

        set_name_to_downcase = Class.new(Actor) do
          input :name, type: String
          output :name

          def call
            self.name = name.downcase
          end
        end

        use_stripped_down_actor_test_app = Class.new do
          include ServiceActor::Base
        end

        use_stripped_down_actor = Class.new(use_stripped_down_actor_test_app) do
          output :stripped_down_actor

          def call
            self.stripped_down_actor = true
          end
        end

        do_nothing = Class.new(Actor)

        play_actors = Class.new(Actor) do
          play increment_value,
               do_nothing,
               set_name,
               set_name_to_downcase,
               use_stripped_down_actor,
               increment_value
        end

        Class.new(play_actors) do
          play increment_value
        end
      end

      it "calls both the parent and child" do
        expect(actor_class.value(value: 0)).to eq(3)
      end
    end

    context "when using advanced mode with checks and not adding message key" do
      context "when using inclusion check" do
        let(:actor_class) do
          Class.new(Actor) do
            input :provider, inclusion: {in: %w[MANGOPAY PayPal Stripe]}
          end
        end

        it do
          expect { actor_class.value(provider: "Paypal2") }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "provider" input must be included in \["MANGOPAY", "PayPal", "Stripe"\] on ".+" instead of "Paypal2"\z/,
            )
        end
      end

      context "when using type check" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, type: {is: String}
          end
        end

        it do
          expect { actor_class.value(name: 2) }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "name" input on ".+" must be of type "String" but was "Integer"\z/,
            )
        end
      end

      context "when using must check" do
        let(:actor_class) do
          Class.new(Actor) do
            input :num, must: {be_smaller: {is: -> name { name < 5 }}}
          end
        end

        it do
          expect { actor_class.value(num: 6) }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "num" input on ".+" must "be_smaller" but was 6\z/,
            )
        end
      end

      context "when using nil check" do
        let(:actor_class) do
          Class.new(Actor) do
            input :name, allow_nil: {is: false}
          end
        end

        it do
          expect { actor_class.value(name: nil) }
            .to raise_error(
              ServiceActor::ArgumentError,
              /\AThe "name" input on ".+" does not allow nil values\z/,
            )
        end
      end
    end

    context "with unset output and allow_nil: true" do
      let(:actor_class) do
        Class.new(Actor) do
          output :value, type: String, allow_nil: true
        end
      end

      it { expect(actor_class.value).to be_nil }
    end
  end

  context "when playing something that returns nil" do
    let(:actor_class) do
      returns_nil = Class.new(Actor) do
        input :call_counter

        def call
          call_counter.trigger

          nil
        end
      end

      Class.new(Actor) do
        play returns_nil
      end
    end

    let(:call_counter) { double :call_counter, trigger: nil }

    it "does not fail" do
      expect(actor_class.call(call_counter: call_counter)).to be_a_success

      expect(call_counter).to have_received(:trigger).once
    end
  end

  context "when an input is called :error" do
    let(:actor_class) do
      Class.new(Actor) do
        input :error
      end
    end

    it { expect(actor_class.call(error: "A message")).to be_a_success }
  end

  context "when calling result with fail_on" do
    let(:actor_class) do
      Class.new(Actor) do
        fail_on CustomArgumentError
        self.argument_error_class = CustomArgumentError
        self.failure_class = CustomFailureError

        input :value, type: Integer
      end
    end

    it "does not raise" do
      result = actor_class.result(value: "boop")
      expect(result).to be_a_failure
      expect(result.error).to start_with('The "value" input on')
    end
  end

  context "when actor inherits from `BasicObject`" do
    let(:actor) do
      basic_class = Class.new(BasicObject) do
        class << self
          def [](attribute, value)
            new(attribute, value)
          end
        end

        def initialize(attribute, value)
          @attribute, @value = attribute, value
        end

        def call(actor)
          actor.__send__(:"#{@attribute}=", @value)
        end
      end

      Class.new(Actor) do
        output :value, type: Integer

        play basic_class[:value, 42]
      end
    end

    it do
      result = actor.result

      expect(result).to be_a_success
      expect(result.value).to eq(42)
    end
  end

  context "when actor has origin with default which is not a proc or an immutable object" do
    include_context "with mocked `Kernel.warn` method"

    context "with input origin" do
      let(:actor) do
        Class.new(Actor) do
          input :options, default: {}
        end
      end

      it "emits a warning on MRI" do
        actor

        if engine_mri?
          expect(Kernel).to have_received(:warn)
            .with(/DEPRECATED: Actor .+ has input `options` with default which is not a Proc or an immutable object./)
            .once
        else
          expect(Kernel).not_to have_received(:warn)
        end
      end
    end

    context "with output origin" do
      let(:actor) do
        Class.new(Actor) do
          output :options, default: {}
        end
      end

      it "emits a warning" do
        actor

        if engine_mri?
          expect(Kernel).to have_received(:warn)
            .with(/DEPRECATED: Actor .+ has output `options` with default which is not a Proc or an immutable object./)
            .once
        else
          expect(Kernel).not_to have_received(:warn)
        end
      end
    end
  end
end
