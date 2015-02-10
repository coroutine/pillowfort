class Account < ActiveRecord::Base
  include Pillowfort::Concerns::ModelAuthentication
  include Pillowfort::Concerns::ModelPasswordReset
end
