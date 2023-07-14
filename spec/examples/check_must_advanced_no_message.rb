# frozen_string_literal: true

class CheckMustAdvancedNoMessage < Actor
  input :num,
        must: {
          be_smaller: {
            is: -> name { name < 5 }
          }
        }
end
