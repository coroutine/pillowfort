class AccountsController < ApplicationController
  include Pillowfort::Concerns::ControllerAuthentication
  include Pillowfort::Concerns::ControllerActivation

  skip_filter :authenticate_from_account_token!, only: [:index]
  skip_filter :enforce_account_activation!, only: [:index]

  def index
    head :ok
  end

  def show
    head :ok
  end
end
