# frozen_string_literal: true

require "tty/prompt"
require "tty/prompt/test"

class PlayWithPromptForInput < Actor
  prompt_with TTY::Prompt::Test.new
  output :answer, type: String

  play ->(_) { prompt.ok("All is well") },
       ->(result) { result.answer = prompt.ask("Say?", default: "YARR PWPFI") }
end
