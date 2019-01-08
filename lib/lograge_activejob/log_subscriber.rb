require 'active_support/log_subscriber'

module LogrageActivejob
  class LogSubscriber < ActiveSupport::LogSubscriber
    def perform(event)
      data = initial_data(event)
      data.merge!(custom_options(event))
      formatted_message = Lograge.formatter.call(data)
      logger.send(Lograge.log_level, formatted_message)
    end

    private
      def logger
        Lograge.logger.presence || super
      end

      def initial_data(event)
        payload = event.payload
        job = payload[:job]
        ex = payload[:exception_object]

        {
          event_name: event.name,
          job_class: job.class.name,
          job_id: job.job_id,
          adapter_class: event.payload[:adapter].class.name.demodulize,
          queue_name: job.queue_name,
          args: job.arguments.any? ? ActiveJob::Arguments.serialize(job.arguments) : [],
          duration: event.duration.round(2), # ms
          error: ex&.message,
          backtrace: ex&.backtrace,
        }.compact
      end

      def custom_options(event)
        LogrageActivejob.custom_options(event) || {}
      end

      def scheduled_at(job)
        Time.at(job.scheduled_at).utc if job.scheduled_at
      end
  end
end
