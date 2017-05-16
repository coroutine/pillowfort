module Pillowfort
  module Concerns
    module Controllers

      # This module is designed to be included in whichever controller acts
      # as the base class for your project. In most Rails projects, this will
      # be the ApplicationController.
      #
      module Base
        extend ActiveSupport::Concern

        #--------------------------------------------------
        # Configuration
        #--------------------------------------------------

        included do

          # callbacks
          before_action :remove_response_headers!
          before_action :authenticate_from_resource_secret!

          # mixins
          include ActionController::HttpAuthentication::Basic::ControllerMethods

          # errors
          rescue_from Pillowfort::NotActivatedError,      with: :render_pillowfort_activation_error
          rescue_from Pillowfort::NotAuthenticatedError,  with: :render_pillowfort_authentication_error
          rescue_from Pillowfort::TokenStateError,        with: :render_pillowfort_token_state_error

          # helpers
          helper_method :pillowfort_realm
          helper_method :pillowfort_resource
          helper_method :pillowfort_session_token

        end


        #--------------------------------------------------
        # Private Methods
        #--------------------------------------------------
        private

        #========== AUTHENTICATION ========================

        # This method reads the email, secret, and realm from
        # the request headers, determines the authenticable class,
        # and defers lookup to the authenticable class itself.
        #
        # If you wish to support multiple sessions per client
        # application, your client can provide a identifying value
        # in a custom http header named `X-Realm`.  If no such
        # header is provided, Pillowfort will use the default Rails
        # realm of `Application`.
        #
        def authenticate_from_resource_secret!
          klass = Pillowfort.config.resource_class.to_s.classify.constantize

          authenticate_with_http_basic do |email, secret|
            klass.authenticate_securely(email, secret, pillowfort_realm) do |resource|
              @pillowfort_resource = resource
            end
          end
        end

        # DEPRECATED: This method should be removed in the next
        # major release of the library.
        #
        def authenticate_from_resource_token!
          Pillowfort::Helpers::DeprecationHelper.warn(self, :authenticate_from_resource_token!, :authenticate_from_resource_secret!)
          authenticate_from_resource_secret!
        end


        #========== CURRENT ===============================

        # This method returns the specified realm for this
        # request.
        #
        def pillowfort_realm
          @pillowfort_realm ||= begin
            (request.headers['HTTP_X_REALM'] || 'Application').to_s.underscore.strip
          end
        end

        # This method returns the current instance of the
        # authenticable resource.
        #
        def pillowfort_resource
          @pillowfort_resource
        end

        # This method returns the current session token of the
        # authenticable resource for the current realm.
        #
        def pillowfort_session_token
          pillowfort_resource &&
            pillowfort_resource.session_tokens.where(realm: pillowfort_realm).first
        end


        #========== HEADERS =================================

        # This is necessary, as it allows Cordova to properly delegate
        # 401 response handling to our application.  If we keep this header,
        # Cordova will defer handling to iOS, and we'll never see the 401
        # status in the app... it'll just do nothing.
        #
        def remove_response_headers!
          headers.delete('WWW-Authenticate')
        end


        #========== RENDERING ===============================

        # This method renders a standard response for resources
        # that are not activated.
        #
        def render_pillowfort_activation_error
          head :unauthorized
        end

        # This method renders a standard response for resources
        # that are not authenticated.
        #
        def render_pillowfort_authentication_error
          head :unauthorized
        end

        # This method renders a standard response for resources
        # that attempt to modify tokens in illegal ways.
        #
        def render_pillowfort_token_state_error
          head :unauthorized
        end

      end

    end
  end
end
