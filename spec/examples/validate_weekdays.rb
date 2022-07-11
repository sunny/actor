# frozen_string_literal: true

class ValidateWeekdays < Actor
  DEFAULT_WEEKDAYS = [0, 1, 2, 3, 4].freeze

  input :weekdays,
        type: Array,
        allow_nil: true,
        default: DEFAULT_WEEKDAYS,
        must: {
          be_valid: lambda do |numbers|
            numbers.nil? || numbers.all? { |number| (0..6).include?(number) }
          end
        }

  def call; end
end
