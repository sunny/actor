# frozen_string_literal: true

RSpec.describe ServiceActor do
  it "does not raise on eager load" do
    Zeitwerk::Loader.eager_load_all
  end
end
