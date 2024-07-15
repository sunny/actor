# frozen_string_literal: true

require "interactor"

class FailWithInteractor
  include Interactor

  def call
    context.fail!(error: "Failed with Interactor")
  end
end
