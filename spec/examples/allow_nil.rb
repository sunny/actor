class AllowNil < Actor
  input :message_with_inclusion,
        type: [String, NilClass],
        inclusion: %w[SUPPRESS RESEND],
        allow_nil: true

  input :message_with_must,
        type: [String, NilClass],
        must: {
          be_valid_message_action: {
            is: -> v { v.in?(%w[SUPPRESS]) || v.nil? },
          },
        },
        allow_nil: true
end
