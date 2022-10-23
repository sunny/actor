# frozen_string_literal: true

module ServiceActor::Checkable
  def self.included(base)
    base.prepend(PrependedMethods)
  end

  module PrependedMethods # rubocop:disable Metrics/ModuleLength
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

          argument_errors =
            if type_checkable?(checker_name)
              ServiceActor::Checkers::TypeChecker.for(
                origin: :input,
                input_key: input_key,
                actor: self.class,
                type_definition: checker_conditions,
                given_type: result[input_key],
              )
            elsif conditionable?(checker_name)
              ServiceActor::Checkers::MustChecker.for(
                input_key: input_key,
                actor: self.class,
                nested_checkers: checker_conditions,
                value: result[input_key],
              )
            elsif collectionable?(checker_name)
              ServiceActor::Checkers::InclusionChecker.for(
                input_key: input_key,
                actor: self.class,
                inclusion: checker_conditions,
                value: result[input_key],
              )
            end

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

        input_options.each do |checker_name, checker_conditions| # rubocop:disable Metrics/BlockLength
          # puts
          # puts "type_checkable? => #{type_checkable?(checker_name)}"
          # puts "conditionable? => #{conditionable?(checker_name)}"
          # puts "collectionable? => #{collectionable?(checker_name)}"
          # puts "nil_checkable? => #{nil_checkable?(checker_name, input_options)}" # rubocop:disable Layout/LineLength
          # puts "defaultable? => #{defaultable?(checker_name)}"
          # puts
          # puts

          argument_errors =
            if type_checkable?(checker_name)
              ServiceActor::Checkers::TypeChecker.for(
                origin: :output,
                input_key: input_key,
                actor: self.class,
                type_definition: checker_conditions,
                given_type: result[input_key],
              )
            end

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

    def type_checkable?(checker_name)
      checker_name == :type
    end

    def conditionable?(checker_name)
      checker_name == :must
    end

    def collectionable?(checker_name)
      # DEPRECATED: `in` is deprecated in favor of `inclusion`.
      %i[inclusion in].include?(checker_name)
    end

    def nil_checkable?(checker_name, input_options)
      checker_name == :allow_nil || !input_options.key?(:default)
    end

    def defaultable?(_checker_name)
      # checker_name == :default
      true
    end
  end
end
