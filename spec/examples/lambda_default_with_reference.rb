# frozen_string_literal: true

class LambdaDefaultWithReference < Actor
  input :old_project_id, type: Integer
  input :project_id,
        default: -> context { "#{context.old_project_id}.0" },
        type: String
  output :properties, type: Hash

  def call
    self.properties = {project_id: project_id}
  end
end
