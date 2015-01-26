module Pillowfort::ModelContext
  mattr_accessor :model_class

  def self.resource_reader_name
    "current_#{model_class.name.underscore}"
  end
end
