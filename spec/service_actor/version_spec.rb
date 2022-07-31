# frozen_string_literal: true

RSpec.describe ServiceActor::VERSION do
  # rubocop:disable RSpec/DescribedClass
  it { expect(ServiceActor::VERSION).not_to be_nil }
  # rubocop:enable RSpec/DescribedClass
end
