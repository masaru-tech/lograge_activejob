require 'lograge_activejob/version'
require 'lograge_activejob/log_subscriber'

module LogrageActivejob
  module_function

  mattr_writer :custom_options
  self.custom_options = nil

  def custom_options(event)
    if @@custom_options.respond_to?(:call)
      @@custom_options.call(event)
    else
      @@custom_options
    end
  end

  def setup(app)
    LogrageActivejob.custom_options = app.config.lograge_activejob.custom_options
    LogrageActivejob::LogSubscriber.attach_to :active_job
  end
end

require 'lograge_activejob/railtie' if defined?(Rails)
