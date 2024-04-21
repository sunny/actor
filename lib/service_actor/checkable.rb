# frozen_string_literal: true

module ServiceActor::Checkable
  class << self
    def included(base)
      base.prepend(PrependedMethods)
    end
  end

  module PrependedMethods
    CHECK_CLASSES = [
      ServiceActor::Checks::TypeCheck,
      ServiceActor::Checks::MustCheck,
      ServiceActor::Checks::InclusionCheck,
      ServiceActor::Checks::NilCheck,
    ].freeze
    private_constant :CHECK_CLASSES

    def _call
      self.service_actor_argument_errors = []

      service_actor_checks_for(:input)
      return_val = super
      service_actor_checks_for(:output)
      return_val
    end

    private

    attr_accessor :service_actor_argument_errors

    # rubocop:disable Metrics/MethodLength
    def service_actor_checks_for(origin)
      check_classes = CHECK_CLASSES.select { _1.applicable_to_origin?(origin) }
      self.class.public_send(:"#{origin}s").each do |input_key, input_options|
        input_options.each do |check_name, check_conditions|
          check_classes.each do |check_class|
            argument_errors = check_class.check(
              check_name: check_name,
              origin: origin,
              input_key: input_key,
              actor: self.class,
              conditions: check_conditions,
              result: result,
              input_options: input_options,
            )

            service_actor_argument_errors.push(*argument_errors)
          end
        end

        raise_actor_argument_errors
      end
    end
    # rubocop:enable Metrics/MethodLength

    def raise_actor_argument_errors
      return if service_actor_argument_errors.empty?

      raise self.class.argument_error_class,
            service_actor_argument_errors.first
    end
  end
end
