# frozen_string_literal: true

class ValidateWeekdays < Actor
  DEFAULT_WEEKDAYS = [0, 1, 2, 3, 4].freeze

  input :weekdays,
        type: Array,
        allow_nil: true,
        default: DEFAULT_WEEKDAYS,
        must: {
          be_valid: -> numbers do
            numbers.nil? || numbers.all? { |number| (0..6).cover?(number) }
          end,
        }

  def call; end
end
