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
          checks_class_names.each do |check_class_name|
            check_class = check_class_for(check_class_name)

            argument_errors = check_class.check(
              check_name: check_name,
              origin: origin,
              input_key: input_key,
              actor: self.class,
              conditions: check_conditions,
              result: result,

              # NilCheck + DefaultCheck
              input_options: input_options,
            )

            add_argument_errors(argument_errors)
          end
        end
      end
    end

    def checks_class_names
      %w[
        TypeCheck
        MustCheck
        InclusionCheck
        NilCheck
        DefaultCheck
      ]
    end

    def check_class_for(check_class_name)
      Object.const_get("ServiceActor::Checks::#{check_class_name}")
    end
  end
end
