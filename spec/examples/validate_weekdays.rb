# frozen_string_literal: true

class ValidateWeekdays < Actor
  DEFAULT_WEEKDAYS = [0, 1, 2, 3, 4].freeze

  input :weekdays,
        type: Array,
        allow_nil: true,
        default: DEFAULT_WEEKDAYS,
        must: {
          be_valid: ->(v) { v.nil? || v.all? { |num| (0..6).include?(num) } }
        }

  def call; end
end
