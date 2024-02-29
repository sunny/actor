# frozen_string_literal: true

class FailForDifferentReasons < Actor
  input :month, type: Integer

  output :message, type: String

  def call
    if month < 1 || month > 12
      fail!(reason: :invalid_month)
    elsif month == 12
      self.message = "Come next year!"
      fail!(reason: :holidays)
    else
      self.message = "Welcome!"
    end
  end
end
