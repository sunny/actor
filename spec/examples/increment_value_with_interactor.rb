# frozen_string_literal: true

require 'interactor'

class IncrementValueWithInteractor
  include Interactor

  def call
    context.value += 1
  end
end
