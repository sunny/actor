# frozen_string_literal: true

module ServiceActor::Checkable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      checks_for(:input)
      super
      checks_for(:output)
    end

    private

    def checks_for(origin) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      self.class.send("#{origin}s").each do |input_key, input_options| # rubocop:disable Metrics/BlockLength
        input_options.each do |check_name, check_conditions| # rubocop:disable Metrics/BlockLength
          checks = %w[
            TypeCheck
            MustCheck
            InclusionCheck
            NilCheck
            DefaultCheck
          ]

          checks.each do |check_class_name|
            check_class =
              Object.const_get("ServiceActor::Checks::#{check_class_name}")

            argument_errors = check_class.for(
              check_name: check_name,
              origin: origin.to_sym,
              input_key: input_key,
              actor: self.class,
              value: result[input_key],

              # TypeCheck
              type_definition: check_conditions,
              given_type: result[input_key],

              # MustCheck
              nested_checks: check_conditions,

              # InclusionCheck
              inclusion: check_conditions,

              # NilCheck
              allow_nil: check_conditions,

              # DefaultCheck
              result: result,

              # NilCheck + DefaultCheck
              input_options: input_options,
            )

            add_argument_errors(argument_errors)
          end
        end
      end
    end
  end
end
