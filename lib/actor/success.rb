# frozen_string_literal: true

class Actor
  # Raised when using `succeed!` to halt the progression of an organizer.
  class Success < StandardError; end
end
