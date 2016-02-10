#----------------------------------------------------------
# Dependencies
#----------------------------------------------------------

require 'scrypt'


#----------------------------------------------------------
# Autoloads
#----------------------------------------------------------

module Pillowfort

  # errors
  class NotActivatedError     < StandardError; end
  class NotAuthenticatedError < StandardError; end
  class TokenStateError       < StandardError; end

  # concerns
  module Concerns
    module Controllers
      autoload :Base,             'pillowfort/concerns/controllers/base'
    end
    module Models
      module Resource
        autoload :Base,           'pillowfort/concerns/models/resource/base'
        autoload :Activation,     'pillowfort/concerns/models/resource/activation'
        autoload :PasswordReset,  'pillowfort/concerns/models/resource/password_reset'
      end
      module Token
        autoload :Base,           'pillowfort/concerns/models/token/base'
      end
    end
  end

  # helpers
  module Helpers
    autoload :ErrorHelper,        'pillowfort/helpers/error_helper'
  end

end


#----------------------------------------------------------
# Requires
#----------------------------------------------------------

require "pillowfort/config"
require "pillowfort/engine"
