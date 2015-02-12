module Pillowfort
  module ControllerMethods
    def ensure_resource_reader(context)
      reader_name = context.resource_reader_name
      return if respond_to? reader_name

      self.class.send :define_method, reader_name do
        @authentication_resource
      end
    end
  end
end
