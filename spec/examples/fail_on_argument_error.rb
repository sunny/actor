# frozen_string_literal: true

class FailOnArgumentError < Actor
  fail_on ServiceActor::ArgumentError

  input :name, type: String, allow_nil: false

  def call; end
end
