# frozen_string_literal: true

RSpec.describe ServiceActor::Core do
  describe ".instance_methods" do
    let(:expected_methods) { [:_call, :call, :fail!, :result, :rollback] }

    # See also https://github.com/sunny/actor/pull/207
    it "stays small so as not to disallow too many possible input names" do
      expect(described_class.instance_methods)
        .to match_array(expected_methods)
    end
  end
end
