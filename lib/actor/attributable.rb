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
          context[name]
        end

        protected name
      end

      def inputs
        @inputs ||= {}
      end

      def output(name, **arguments)
        outputs[name] = arguments

        define_method(name) do
          context[name]
        end

        define_method("#{name}=") do |value|
          context[name] = value
        end

        protected name, "#{name}="
      end

      def outputs
        @outputs ||= {}
      end
    end
  end
end
