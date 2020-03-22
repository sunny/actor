# frozen_string_literal: true

RSpec.describe Actor do
  it 'has a version number' do
    expect(ServiceActor::VERSION).not_to be_nil
  end
end
