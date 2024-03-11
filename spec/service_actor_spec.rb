# frozen_string_literal: true

RSpec.describe ServiceActor do
  it "does not raise on eager load" do
    expect { Zeitwerk::Loader.eager_load_all }.not_to raise_error
  end
end
