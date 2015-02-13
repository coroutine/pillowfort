class Account < ActiveRecord::Base
  include Pillowfort::Concerns::ModelAuthentication
  include Pillowfort::Concerns::ModelPasswordReset
  include Pillowfort::Concerns::ModelActivation
end
