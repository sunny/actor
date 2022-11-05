# frozen_string_literal: true

module ServiceActor::Checkable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods
    def _call
      inputs
      super
      outputs
    end

    private

    def inputs # rubocop:disable Metrics/MethodLength
      self.class.inputs.each do |input_key, input_options| # rubocop:disable Metrics/BlockLength
        input_options.each do |checker_name, checker_conditions| # rubocop:disable Metrics/BlockLength
          checkers = %w[
            TypeChecker
            MustChecker
            InclusionChecker
            NilChecker
            DefaultChecker
          ]

          checkers.each do |checker_class_name|
            checker_class =
              Object.const_get("ServiceActor::Checkers::#{checker_class_name}")

            argument_errors = checker_class.for(
              checker_name: checker_name,
              origin: :input,
              input_key: input_key,
              actor: self.class,
              value: result[input_key],

              # TypeChecker
              type_definition: checker_conditions,
              given_type: result[input_key],

              # MustChecker
              nested_checkers: checker_conditions,

              # InclusionChecker
              inclusion: checker_conditions,

              # NilChecker
              allow_nil: checker_conditions,

              # DefaultChecker
              result: result,

              # NilChecker + DefaultChecker
              input_options: input_options,
            )

            add_argument_errors(argument_errors)
          end
        end
      end

      # self.class.inputs.each do |input_key, input_options|
      #   input_options.each do |checker_name, checker_conditions|
      #     common_attributes = {
      #       checker_name: checker_name,
      #       input_key: input_key,
      #       actor: self.class
      #     }

      #     argument_errors = ServiceActor::Checkers::TypeChecker.for(
      #       **common_attributes,
      #       origin: :input,
      #       type_definition: checker_conditions,
      #       given_type: result[input_key],
      #     )

      #     add_argument_errors(argument_errors)

      #     argument_errors = ServiceActor::Checkers::MustChecker.for(
      #       **common_attributes,
      #       nested_checkers: checker_conditions,
      #       value: result[input_key],
      #     )

      #     add_argument_errors(argument_errors)

      #     argument_errors = ServiceActor::Checkers::InclusionChecker.for(
      #       **common_attributes,
      #       inclusion: checker_conditions,
      #       value: result[input_key],
      #     )

      #     add_argument_errors(argument_errors)

      #     argument_errors = ServiceActor::Checkers::NilChecker.for(
      #       **common_attributes,
      #       origin: :input,
      #       input_options: input_options,
      #       allow_nil: checker_conditions,
      #       value: result[input_key],
      #     )

      #     add_argument_errors(argument_errors)

      #     argument_errors = ServiceActor::Checkers::DefaultChecker.for(
      #       **common_attributes,
      #       result: result,
      #       input_options: input_options,
      #     )

      #     add_argument_errors(argument_errors)
      #   end
      # end
    end

    def outputs # rubocop:disable Metrics/MethodLength
      self.class.outputs.each do |input_key, input_options|
        input_options.each do |checker_name, checker_conditions|
          checkers = %w[
            TypeChecker
            NilChecker
            DefaultChecker
          ]

          checkers.each do |checker_class_name|
            checker_class =
              Object.const_get("ServiceActor::Checkers::#{checker_class_name}")

            argument_errors = checker_class.for(
              checker_name: checker_name,
              origin: :output,
              input_key: input_key,
              actor: self.class,
              value: result[input_key],

              # TypeChecker
              type_definition: checker_conditions,
              given_type: result[input_key],

              # NilChecker
              allow_nil: checker_conditions,

              # DefaultChecker
              result: result,

              # NilChecker + DefaultChecker
              input_options: input_options,
            )

            add_argument_errors(argument_errors)
          end
        end

        # input_options.each do |checker_name, checker_conditions|
        #   common_attributes = {
        #     checker_name: checker_name,
        #     input_key: input_key,
        #     actor: self.class
        #   }

        #   argument_errors = ServiceActor::Checkers::TypeChecker.for(
        #     **common_attributes,
        #     origin: :output,
        #     type_definition: checker_conditions,
        #     given_type: result[input_key],
        #   )

        #   add_argument_errors(argument_errors)

        #   argument_errors = ServiceActor::Checkers::NilChecker.for(
        #     **common_attributes,
        #     origin: :output,
        #     input_options: input_options,
        #     allow_nil: checker_conditions,
        #     value: result[input_key],
        #   )

        #   add_argument_errors(argument_errors)

        #   argument_errors = ServiceActor::Checkers::DefaultChecker.for(
        #     **common_attributes,
        #     result: result,
        #     input_options: input_options,
        #   )

        #   add_argument_errors(argument_errors)
        # end
      end
    end
  end
end
