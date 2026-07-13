# frozen_string_literal: true

RSpec.describe ServiceActor do
  it "does not raise on eager load" do
    expect { Zeitwerk::Loader.eager_load_all }.not_to raise_error
  end

  it "keeps the runtime loader up to date" do
    expect(system("bin/loader", "validate")).to be(true)
  end

  it "loads at runtime without Zeitwerk" do
    script = <<~RUBY
      require "service_actor"
      raise "Zeitwerk was loaded" if defined?(Zeitwerk)
      raise "Version was not loaded" unless defined?(ServiceActor::VERSION)
      Actor.call
    RUBY

    expect(
      system({"RUBYOPT" => nil, "RUBYLIB" => nil}, RbConfig.ruby, "--disable-gems", "-Ilib", "-e", script),
    ).to be(true)
  end
end
