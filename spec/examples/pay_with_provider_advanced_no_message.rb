# frozen_string_literal: true

class PayWithProviderAdvancedNoMessage < Actor
  input :provider,
        inclusion: {
          in: %w[MANGOPAY PayPal Stripe],
        }
end
