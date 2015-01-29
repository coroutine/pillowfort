require "pillowfort/pillow_fight"

module Pillowfort::ModelContext
  mattr_accessor :model_class

  def self.resource_reader_name
    begin
      "current_#{model_class.name.underscore}"
    rescue NoMethodError => nme
      Pillowfort::PillowFight.error_message <<-EOF
      It seems no `model_class` can be found.  The likely culprit is:

      1.) You forgot to include Pillowfort::Concerns::ModelAuthentication into
      the model of your choosing.
      2.) You forgot to set `config.eager_load` to `true`, in your environment
      config (e.g. development.rb)

      If neither of the aforementioned options are the issue, you've likely
      found a bug.  Please report it at:

      https://github.com/coroutine/pillowfort/issues

      Cheers!
      Coroutine

      EOF

      # rethrow
      raise nme
    end
  end
end
