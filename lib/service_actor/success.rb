# frozen_string_literal: true

module ServiceActor
  # Raised when using `succeed!` to halt the progression of an organizer.
  # DEPRECATED in favor of adding conditions to your play.
  class Success < Error; end
end
