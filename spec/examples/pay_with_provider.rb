# frozen_string_literal: true

class PayWithProvider < Actor
  input :provider, in: %w[MANGOPAY PayPal Stripe]
  output :message, type: String

  def call
    self.message = "Money transferred to #{provider}!"
  end
end
