# frozen_string_literal: true

module ServiceActor::Checkable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      service_actor_checks_for(:input)
      super
      service_actor_checks_for(:output)
    end

    private

    def service_actor_checks_for(origin) # rubocop:disable Metrics/MethodLength
      self.class.public_send("#{origin}s").each do |input_key, input_options|
        input_options.each do |check_name, check_conditions|
          checks_class.each do |check_class|
            argument_errors = check_class.check(
              check_name: check_name,
              origin: origin,
              input_key: input_key,
              actor: self.class,
              conditions: check_conditions,
              result: result,
              input_options: input_options,
            )

            add_argument_errors(argument_errors)
          end
        end
      end
    end

    def checks_class
      [
        ServiceActor::Checks::TypeCheck,
        ServiceActor::Checks::MustCheck,
        ServiceActor::Checks::InclusionCheck,
        ServiceActor::Checks::NilCheck,
        ServiceActor::Checks::DefaultCheck
      ]
    end
  end
end
