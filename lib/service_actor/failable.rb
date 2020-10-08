# frozen_string_literal: true

module ServiceActor
  # Adds the `fail_on` DSL to actors. This allows you to call `.result` and get
  # back a failed actor instead of raising an exception.
  #
  #   class ApplicationActor < Actor
  #     fail_on ServiceActor::ArgumentError
  #   end
  module Failable
    def self.included(base)
      base.extend(ClassMethods)
      base.prepend(PrependedMethods)
    end

    module ClassMethods
      def inherited(child)
        super

        child.fail_ons.append(*fail_ons)
      end

      def fail_on(*exceptions)
        fail_ons.append(*exceptions)
      end

      def fail_ons
        @fail_ons ||= []
      end
    end

    module PrependedMethods
      def _call
        super
      rescue *self.class.fail_ons => e
        fail!(error: e.message)
      end
    end
  end
end
