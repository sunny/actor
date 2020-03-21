# frozen_string_literal: true

class Actor
  # DSL to document the accepted attributes.
  #
  #   class CreateUser < Actor
  #     input :name
  #     output :name
  #   end
  module Attributable
    def self.included(base)
      base.extend(ClassMethods)
      base.prepend(PrependedMethods)
    end

    module ClassMethods
      def inherited(child)
        super

        child.inputs.merge!(inputs)
        child.outputs.merge!(outputs)
      end

      def input(name, **arguments)
        inputs[name] = arguments

        define_method(name) do
          context.public_send(name)
        end

        private name
      end

      def inputs
        @inputs ||= {}
      end

      def output(name, **arguments)
        outputs[name] = arguments

        define_method(name) do
          context.public_send(name)
        end

        define_method("#{name}=") do |value|
          context.public_send("#{name}=", value)
        end

        private name, "#{name}="
      end

      def outputs
        @outputs ||= {}
      end
    end

    module PrependedMethods
      # rubocop:disable Naming/MemoizedInstanceVariableName
      def context
        @filtered_context ||= Actor::FilteredContext.new(
          super,
          readers: self.class.inputs.keys,
          setters: self.class.outputs.keys,
        )
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end
  end
end
