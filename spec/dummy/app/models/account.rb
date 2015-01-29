class Account < ActiveRecord::Base
  include Pillowfort::Concerns::ModelAuthentication
end
