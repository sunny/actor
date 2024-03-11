# frozen_string_literal: true

class PayWithProviderAdvanced < Actor
  input :provider,
        inclusion: {
          in: %w[MANGOPAY PayPal Stripe],
          message: (lambda do |value:, **|
            "Payment system \"#{value}\" is not supported"
          end),
        },
        default: "Stripe"

  output :message, type: String

  def call
    self.message = "Money transferred to #{provider}!"
  end
end
