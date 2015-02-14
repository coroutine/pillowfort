module AuthenticationHelper
  def authenticate_with(account)
    return unless account

    email = account.email
    token = account.auth_token

    request.env['HTTP_AUTHORIZATION'] =
    ActionController::HttpAuthentication::Basic.encode_credentials(email, token)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, :type => :controller
end
