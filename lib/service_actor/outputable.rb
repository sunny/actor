# frozen_string_literal: true

# Adds the `output` method to actors. This allows you to call `.output` and get
# back the return value of that actor's `call` method.
#
# In the case of play actors, it will return the value of the final actor's
# `call` method in the chain.
#
#   class MyActor < Actor
#     def call
#       "foo"
#     end
#   end
#
#   > MyActor.output
#   => "foo"
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
