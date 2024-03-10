# frozen_string_literal: true

# DSL to document the accepted attributes.
#
#   class CreateUser < Actor
#     input :name
#     output :name
#   end
module ServiceActor::Attributable
  class << self
    def included(base)
      base.extend(ClassMethods)
    end
  end

  module ClassMethods
    def inherited(child)
      super

      child.inputs.merge!(inputs)
      child.outputs.merge!(outputs)
    end

    def input(name, **arguments)
      ServiceActor::ArgumentsValidator.validate_origin_name(
        name, origin: :input
      )

      inputs[name] = arguments

      define_method(name) do
        result[name]
      end

      # To avoid method redefined warning messages.
      alias_method(name, name) if method_defined?(name)

      protected name
    end

    def inputs
      @inputs ||= {}
    end

    def output(name, **arguments)
      ServiceActor::ArgumentsValidator.validate_origin_name(
        name, origin: :output
      )

      outputs[name] = arguments

      define_method(name) do
        result[name]
      end
      protected name

      define_method(:"#{name}=") do |value|
        result[name] = value
      end
      protected :"#{name}="
    end

    def outputs
      @outputs ||= {}
    end
  end
end
