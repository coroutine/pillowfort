class AccountsController < ApplicationController
  include Pillowfort::Concerns::ControllerAuthentication

  skip_filter :authenticate_from_account_token!, only: [:index]

  def index
    head :ok
  end

  def show
    head :ok
  end
end
