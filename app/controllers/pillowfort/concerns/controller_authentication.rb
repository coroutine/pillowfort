require 'pillowfort/model_context'

module Pillowfort
  module Concerns::ControllerAuthentication
    extend ActiveSupport::Concern
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    included do
      before_filter :authenticate_from_account_token!
    end

    private

    def authenticate_from_account_token!
      context         = Pillowfort::ModelContext
      resource_class  = context.model_class

      ensure_resource_reader(context)

      authenticate_or_request_with_http_basic do |email, token|
        resource_class.authenticate_securely(email, token) do |resource|
          @authentication_resource = resource
        end
      end

      allow_client_to_handle_unauthorized_status
    end

    def ensure_resource_reader(context)
      reader_name = context.resource_reader_name
      return if respond_to? reader_name

      self.class.send :define_method, reader_name do
        @authentication_resource
      end
    end

    # This is necessary, as it allows Cordova to properly delegate 401 response
    # handling to our application.  If we keep this header, Cordova will defer
    # handling to iOS, and we'll never see the 401 status in the app... it'll just
    # do nothing.
    def allow_client_to_handle_unauthorized_status
      headers.delete('WWW-Authenticate')
    end
  end
end
