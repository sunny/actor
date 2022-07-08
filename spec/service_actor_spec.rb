# frozen_string_literal: true

RSpec.describe ServiceActor do
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
