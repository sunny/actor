# frozen_string_literal: true

module Defaultable
  def before
    (self.class.inputs || {}).each do |name, input|
      next if !input.key?(:default) || @full_context.key?(name)

      default = input[:default]
      default = default.call if default.respond_to?(:call)
      @full_context.merge!(name => default)
    end

    super
  end
end
