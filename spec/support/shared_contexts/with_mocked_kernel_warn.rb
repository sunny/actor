# frozen_string_literal: true

RSpec.shared_context "with mocked `Kernel.warn` method" do
  before { allow(Kernel).to receive(:warn).with(kind_of(String)) }
end
