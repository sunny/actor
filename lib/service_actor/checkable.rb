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

    def inputs # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      self.class.inputs.each do |input_key, input_options| # rubocop:disable Metrics/BlockLength
        # puts
        # puts
        # puts
        # puts
        # puts
        # puts
        # puts input_key.inspect

        input_options.each do |checker_name, checker_conditions| # rubocop:disable Metrics/BlockLength
          # puts
          # puts "type_checkable? => #{type_checkable?(checker_name)}"
          # puts "conditionable? => #{conditionable?(checker_name)}"
          # puts "collectionable? => #{collectionable?(checker_name)}"
          # puts "nil_checkable? => #{nil_checkable?(checker_name, input_options)}" # rubocop:disable Layout/LineLength
          # puts "defaultable? => #{defaultable?(checker_name)}"
          # puts
          # puts

          common_attributes = {
            checker_name: checker_name,
            input_key: input_key,
            actor: self.class
          }

          argument_errors = ServiceActor::Checkers::TypeChecker.for(
            **common_attributes,
            origin: :input,
            type_definition: checker_conditions,
            given_type: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::MustChecker.for(
            **common_attributes,
            nested_checkers: checker_conditions,
            value: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::InclusionChecker.for(
            **common_attributes,
            inclusion: checker_conditions,
            value: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::NilChecker.for(
            **common_attributes,
            origin: :input,
            input_options: input_options,
            allow_nil: checker_conditions,
            value: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::DefaultChecker.for(
            **common_attributes,
            result: result,
            input_options: input_options,
          )

          add_argument_errors(argument_errors)
        end
      end
    end

    def outputs # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      self.class.outputs.each do |input_key, input_options| # rubocop:disable Metrics/BlockLength
        # puts
        # puts
        # puts
        # puts
        # puts
        # puts
        # puts input_key.inspect

        input_options.each do |checker_name, checker_conditions| # rubocop:disable Metrics/BlockLength
          # puts
          # puts "type_checkable? => #{type_checkable?(checker_name)}"
          # puts "conditionable? => #{conditionable?(checker_name)}"
          # puts "collectionable? => #{collectionable?(checker_name)}"
          # puts "nil_checkable? => #{nil_checkable?(checker_name, input_options)}" # rubocop:disable Layout/LineLength
          # puts "defaultable? => #{defaultable?(checker_name)}"
          # puts
          # puts

          common_attributes = {
            checker_name: checker_name,
            input_key: input_key,
            actor: self.class
          }

          argument_errors = ServiceActor::Checkers::TypeChecker.for(
            **common_attributes,
            origin: :output,
            type_definition: checker_conditions,
            given_type: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::NilChecker.for(
            **common_attributes,
            origin: :output,
            input_options: input_options,
            allow_nil: checker_conditions,
            value: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::DefaultChecker.for(
            **common_attributes,
            result: result,
            input_options: input_options,
          )

          add_argument_errors(argument_errors)
        end
      end
    end
  end
end
