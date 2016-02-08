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
          before_filter :ensure_current_resource_method!
          before_filter :remove_response_headers!
          before_filter :authenticate_from_account_token!

          # mixins
          include ActionController::HttpAuthentication::Basic::ControllerMethods

          # errors
          rescue_from Pillowfort::NotActivatedError,      with: :render_pillowfort_activation_error
          rescue_from Pillowfort::NotAuthenticatedError,  with: :render_pillowfort_authentication_error
          rescue_from Pillowfort::TokenStateError,        with: :render_pillowfort_token_state_error

        end


        #--------------------------------------------------
        # Private Methods
        #--------------------------------------------------
        private

        #========== AUTHENTICATION ========================

        # This method reads the email, token, and realm from
        # the request headers, determines the authenticable class,
        # and defers lookup to the authenticable class itself.
        #
        # If you wish to support multiple sessions per client
        # application, your client can provide a identifying value
        # in a custom http header named `X-Realm`.  If no such
        # header is provided, Pillowfort will use the default Rails
        # realm of `Application`.
        #
        def authenticate_from_account_token!
          klass = Pillowfortconfig.resource_class.to_s.classify.constantize
          realm = headers['HTTP_X_Realm'] || 'Application'

          authenticate_or_request_with_http_basic do |email, token|
            klass.authenticate_securely(email, token, realm) do |resource|
              @pillowfort_resource = resource
            end
          end
        end


        #========== CURRENT ===============================

        # This is the internal method Pillowfort uses to
        # retrieve the current instance of the authenticable
        # resource.
        #
        def pillowfort_resource
          ensure_current_resource_method
          send(current_resource_method_name)
        end

        # This method establishes the name of the method that
        # returns the current instance of the authenticable
        # model. If Pillowfort is improperly configured, it
        # throws a big old hissy fit.
        #
        def pillowfort_resource_reader_name
          begin
            "current_#{ Pillowfort.config.authenticable_class.name.underscore }"
          rescue NoMethodError => nme
            Pillowfort::ErrorHelper.pillow_fight <<-EOF
            It seems no `authenticable_class` can be found.  The likely culprit is:

            1.) You forgot to configure `authenticable_class` to the model your
            projects uses for maintaining emails and passwords.
            2.) You used Pillowfort's default configuration and your project does
            not include a User model.
            3.) You forgot to set `config.eager_load` to `true`, in your environment
            config (e.g. development.rb)

            If none of the aforementioned options are the issue, you've likely
            found a bug.  Please report it at:

            https://github.com/coroutine/pillowfort/issues

            Cheers!
            Coroutine

            EOF

            # rethrow
            raise nme
          end
        end

        # This method ensures that a reader method exists for retrieving
        # the current instance of the authenticable model. If a method of
        # expected name exists, we do nothing; otherwise, we define one to
        # return the authenticated resource.
        #
        def ensure_pillowfort_resource_reader!
          reader_name = pillowfort_resource_reader_name

          unless respond_to? reader_name
            define_method reader_name do
              @pillowfort_resource
            end
          end
        end

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
