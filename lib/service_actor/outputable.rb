# frozen_string_literal: true

# Adds the `fail_on` DSL to actors. This allows you to call `.result` and get
# back a failed actor instead of raising an exception.
#
#   class ApplicationActor < Actor
#     fail_on ServiceActor::ArgumentError
#   end
module ServiceActor::Outputable
  class << self
    def included(base)
      base.extend(ClassMethods)
      base.prepend(PrependedMethods)
    end
  end

  module ClassMethods
    def output_of(result = nil, **arguments)
      call(result, **arguments)[:_default_output]
    end
  end

  module PrependedMethods
    def _call
      result[:_default_output] = super
    end
  end
end
