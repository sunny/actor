# frozen_string_literal: true

RSpec.describe ServiceActor do
  describe "eager loading" do
    it "does not raise" do
      Zeitwerk::Loader.eager_load_all
    end
  end

  describe "::VERSION" do
    it { expect(ServiceActor::VERSION).not_to be_nil }
  end

  describe "::Base" do
    it "can be used to build your own actor" do
      actor = InheritFromCustomBase.call(value: 41)

      expect(actor.value).to eq(42)
    end
  end
end
