# frozen_string_literal: true

module ServiceActor
  # Raised when using `succeed!` to halt the progression of an organizer.
  class Success < Error; end
end
