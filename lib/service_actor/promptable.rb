# frozen_string_literal: true

module ServiceActor
  # Adds the `prompt_with` DSL to actors. This allows you to set a prompt interface.
  # It is suggested to use the `tty-prompt` gem, but any prompt tool should work.
  # Then you are able to call `.prompt` and manipulate the prompt during a play.
  #
  #   class PromptableActor < Actor
  #     prompt_with TTY::Prompt.new
  #     # or alternatively
  #     def call
  #       super
  #       self.prompt = TTY::Prompt.new
  #     end
  #   end
  module Promptable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def inherited(child)
        super

        child.prompt ||= @prompt
      end

      def prompt_with(prompter)
        @prompt = prompter
      end

      def prompt
        @prompt
      end

      def prompt=(prompter)
        @prompt = prompter
      end
    end

    def prompt
      self.class.prompt
    end

    def prompt=(prompter)
      self.class.prompt = prompter
    end
  end
end
