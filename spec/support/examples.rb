# frozen_string_literal: true

# Autoload examples
loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path("../examples", __dir__))
loader.setup
