# frozen_string_literal: true

class ExampleApplicationActor
  include ServiceActor::Base
end

RSpec.describe ServiceActor::Base do
  let(:actor_class) do
    Class.new(ExampleApplicationActor) do
      input :value, type: Integer
      output :value, type: Integer

      def call
        self.value += 1
      end
    end
  end

  it "can be used to build your own actor" do
    actor = actor_class.call(value: 41)

    expect(actor.value).to eq(42)
  end
end
