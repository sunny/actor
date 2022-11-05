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

          argument_errors = ServiceActor::Checkers::TypeChecker.for(
            checker_name: checker_name,
            origin: :input,
            input_key: input_key,
            actor: self.class,
            type_definition: checker_conditions,
            given_type: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::MustChecker.for(
            checker_name: checker_name,
            input_key: input_key,
            actor: self.class,
            nested_checkers: checker_conditions,
            value: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::InclusionChecker.for(
            checker_name: checker_name,
            input_key: input_key,
            actor: self.class,
            inclusion: checker_conditions,
            value: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::NilChecker.for(
            origin: :input,
            input_key: input_key,
            input_options: input_options,
            actor: self.class,
            allow_nil: checker_conditions,
            value: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::DefaultChecker.for(
            result: result,
            input_key: input_key,
            input_options: input_options,
            actor: self.class,
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

        input_options.each do |checker_name, checker_conditions|
          # puts
          # puts "type_checkable? => #{type_checkable?(checker_name)}"
          # puts "conditionable? => #{conditionable?(checker_name)}"
          # puts "collectionable? => #{collectionable?(checker_name)}"
          # puts "nil_checkable? => #{nil_checkable?(checker_name, input_options)}" # rubocop:disable Layout/LineLength
          # puts "defaultable? => #{defaultable?(checker_name)}"
          # puts
          # puts

          argument_errors = ServiceActor::Checkers::TypeChecker.for(
            checker_name: checker_name,
            origin: :output,
            input_key: input_key,
            actor: self.class,
            type_definition: checker_conditions,
            given_type: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::NilChecker.for(
            origin: :output,
            input_key: input_key,
            input_options: input_options,
            actor: self.class,
            allow_nil: checker_conditions,
            value: result[input_key],
          )

          add_argument_errors(argument_errors)

          argument_errors = ServiceActor::Checkers::DefaultChecker.for(
            result: result,
            input_key: input_key,
            input_options: input_options,
            actor: self.class,
          )

          add_argument_errors(argument_errors)
        end
      end
    end
  end
end
