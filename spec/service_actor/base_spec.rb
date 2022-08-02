# frozen_string_literal: true

RSpec.describe ServiceActor::Base do
  it "can be used to build your own actor" do
    actor = InheritFromCustomBase.call(value: 41)

    expect(actor.value).to eq(42)
  end
end
