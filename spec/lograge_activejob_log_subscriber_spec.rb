require 'spec_helper'
require 'logger'
require 'active_job'
require 'lograge'

RSpec.describe LogrageActivejob::LogSubscriber do
  class TestJob < ActiveJob::Base; end
  class TestModel
    include GlobalID::Identification

    def id
      'ID1234'
    end
  end

  let(:log_output) { StringIO.new }
  let(:logger) do
    Logger.new(log_output).tap { |logger| logger.formatter = ->(_, _, _, msg) { msg } }
  end

  let(:subscriber) { LogrageActivejob::LogSubscriber.new }

  let(:event) do
    ActiveSupport::Notifications::Event.new(
        'perform.active_job',
        Time.now,
        Time.now + 1.second,
        1,
        adapter: ActiveJob::QueueAdapters::AsyncAdapter.new,
        job: job
    )
  end

  let(:job) { TestJob.new }

  before do
    Lograge.logger = logger
  end

  context 'when perform an action with lograge output' do
    before do
      Lograge.formatter = Lograge::Formatters::KeyValue.new
    end

    it 'includes the job_class' do
      subscriber.perform(event)
      expect(log_output.string).to include('job_class=TestJob ')
    end

    it 'includes the event_name' do
      subscriber.perform(event)
      expect(log_output.string).to include('event_name=perform.active_job ')
    end

    it 'includes the duration' do
      subscriber.perform(event)
      expect(log_output.string).to match(/duration=[\d\.]/)
    end

    it 'includes the job_id' do
      subscriber.perform(event)
      expect(log_output.string).to match(/job_id=[a-z0-9\-]{1,} /)
    end

    it 'includes the adapter_class' do
      subscriber.perform(event)
      expect(log_output.string).to include('adapter_class=AsyncAdapter ')
    end

    it 'includes the queue_name' do
      subscriber.perform(event)
      expect(log_output.string).to include('queue_name=default ')
    end

    it 'includes the args' do
      subscriber.perform(event)
      expect(log_output.string).to match(/args=\[\] /)
    end

    describe 'output args' do
      let(:job) { TestJob.new('test', TestModel.new) }
      let(:expect_args) {
        "\\[\"test\", {\"_aj_globalid\"=>\"gid://LogrageActivejobExampleApp/TestModel/ID1234\"}\\]"
      }

      it {
        subscriber.perform(event)
        expect(log_output.string).to match(/args=#{expect_args} /)
      }
    end
  end

  context 'with custom_options configured for lograge output' do
    before do
      Lograge.formatter = Lograge::Formatters::KeyValue.new
    end


    it 'includes the event_time' do
      LogrageActivejob.custom_options = ->(_event) { { data: 'value' } }
      subscriber.perform(event)
      expect(log_output.string).to include('data=value')
    end
  end
end
