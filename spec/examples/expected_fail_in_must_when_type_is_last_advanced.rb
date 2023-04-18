# frozen_string_literal: true

class ExpectedFailInMustWhenTypeIsLastAdvanced < Actor
  input :per_page,
        must: {
          be_in_range: {
            is: -> per_page { per_page >= 3 && per_page <= 9 },
            message: -> value:, ** { "Wrong range (3-9): #{value}" },
          },
        },
        type: Integer

  def call; end
end
