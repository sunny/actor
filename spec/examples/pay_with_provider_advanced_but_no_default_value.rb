# frozen_string_literal: true

class PayWithProviderAdvancedButNoDefaultValue < Actor
  input :provider,
        inclusion: {
          in: %w[MANGOPAY PayPal Stripe],
          message: (-> value:, ** do
            "Payment system \"#{value}\" is not supported"
          end),
        },
        default: {
          # value: "Stripe",
          message: (-> input_key:, ** do
            "Input `#{input_key}` is required"
          end),
        }

  output :message, type: String

  def call
    self.message = "Money transferred to #{provider}!"
  end
end
