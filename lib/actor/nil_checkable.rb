# frozen_string_literal: true

class Actor
  # Ensure your inputs and outputs are not nil by adding `allow_nil: false`.
  #
  # Example:
  #
  #   class CreateUser < Actor
  #     input :name, allow_nil: false
  #     output :user, allow_nil: false
  #   end
  module NilCheckable
    def before
      super

      check_context_for_nil(self.class.inputs, origin: 'input')
    end

    def after
      super

      check_context_for_nil(self.class.outputs, origin: 'output')
    end

    private

    def check_context_for_nil(definitions, origin:)
      definitions.each do |key, options|
        options = deprecated_required_option(options, name: key, origin: origin)

        next unless @context[key].nil?
        next unless options.key?(:allow_nil)
        next if options[:allow_nil]

        raise ArgumentError,
              "The #{origin} \"#{key}\" on #{self.class} does not allow nil " \
              'values.'
      end
    end

    def deprecated_required_option(options, name:, origin:)
      return options unless options.key?(:required)

      warn 'DEPRECATED: The "required" option is deprecated. Replace ' \
           "`#{origin} :#{name}, required: #{options[:required]}` by " \
           "`#{origin} :#{name}, allow_nil: #{!options[:required]}` in " \
           "#{self.class}."

      options.merge(allow_nil: !options[:required])
    end
  end
end
