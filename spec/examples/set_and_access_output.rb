# frozen_string_literal: true

class SetAndAccessOutput < Actor
  output :nickname
  output :email

  def call
    self.nickname = "jim"
    self.email = "#{nickname}@example.org"
  end
end
