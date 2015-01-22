module Pillowfort
  module Concerns::ControllerAuthentication
    extend ActiveSupport::Concern
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    attr_reader :current_user

    included do
      before_filter :authenticate_from_account_token!
    end

    private

    def authenticate_from_account_token!
      authenticate_or_request_with_http_basic do |email, token|
        User.authenticate_securely(email, token) do |user|
          @current_user = user
        end
      end

      allow_client_to_handle_unauthorized_status
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
