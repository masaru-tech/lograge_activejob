require 'rails/railtie'

module LogrageActivejob
  Config = Struct.new(:custom_options)

  class Railtie < Rails::Railtie
    config.lograge_activejob = Config.new

    config.after_initialize do |app|
      LogrageActivejob.setup(app) if app.config.lograge.enabled
    end
  end
end
