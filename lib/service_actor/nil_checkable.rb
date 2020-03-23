# frozen_string_literal: true

module ServiceActor
  # Ensure your inputs and outputs are not nil by adding `allow_nil: false`.
  #
  # Example:
  #
  #   class CreateUser < Actor
  #     input :name, allow_nil: false
  #     output :user, allow_nil: false
  #   end
  module NilCheckable
    def self.included(base)
      base.prepend(PrependedMethods)
    end

    module PrependedMethods
      def _call
        check_context_for_nil(self.class.inputs, origin: 'input')

        super

        check_context_for_nil(self.class.outputs, origin: 'output')
      end

      private

      def check_context_for_nil(definitions, origin:)
        definitions.each do |name, options|
          warn_of_deprecated_required_option(options, name, origin)

          next if !result[name].nil? || allow_nil?(options)

          raise ArgumentError,
                "The #{origin} \"#{name}\" on #{self.class} does not allow " \
                'nil values.'
        end
      end

      def warn_of_deprecated_required_option(options, name, origin)
        return unless options.key?(:required)

        warn 'DEPRECATED: The "required" option is deprecated. Replace ' \
            "`#{origin} :#{name}, required: #{options[:required]}` by " \
            "`#{origin} :#{name}, allow_nil: #{!options[:required]}` in " \
            "#{self.class}."
      end

      def allow_nil?(options)
        if options.key?(:allow_nil)
          options[:allow_nil]
        elsif options.key?(:required)
          !options[:required]
        elsif options.key?(:default) && options[:default].nil?
          true
        elsif options[:type]
          false
        else
          true
        end
      end
    end
  end
end
