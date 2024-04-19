# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cron, type: :service do
  fixtures :all

  let(:cron) { described_class.new }

  def time_at(hour)
    Time.utc(2018, 1, 3, hour, 10, 12)
  end

  it "queues RemoteUpdateSchedulerJob every hour" do
    expect(RemoteUpdateSchedulerJob).to receive(:perform_async)
    cron.run time: time_at(rand(24))
  end

  it "queues CatalogImportJob every hour" do
    expect(CatalogImportJob).to receive(:perform_async)
    cron.run time: time_at(rand(24))
  end

  it "queues RubygemDownloadsPersistenceJob every hour" do
    expect(RubygemDownloadsPersistenceJob).to receive(:perform_async)
    cron.run time: time_at(rand(24))
  end

  it "invokes GithubIgnore.expire every hour" do
    expect(GithubIgnore).to receive(:expire!)
    cron.run time: time_at(rand(24))
  end

  it "enqueues RubygemsSyncJob at 0 am" do
    expect(RubygemsSyncJob).to receive(:perform_async)
    cron.run time: time_at(0)
  end

  it "does not enqueue RubygemsSyncJob at 1 am" do
    expect(RubygemsSyncJob).not_to receive(:perform_async)
    cron.run time: time_at(1)
  end

  describe "Database::StoreSelectiveExportJob" do
    let(:allowed_hours) { 0.upto(23).select { (_1 % 4).zero? } }
    let(:other_hours) { 0.upto(23).to_a - allowed_hours }

    it "is queued every 4th hour" do
      expect(Database::StoreSelectiveExportJob).to receive(:perform_async)
      cron.run time: time_at(allowed_hours.sample)
    end

    it "is not queued on other hours" do
      expect(Database::StoreSelectiveExportJob).not_to receive(:perform_async)
      cron.run time: time_at(other_hours.sample)
    end
  end

  describe "on exceptions" do
    let(:err) { StandardError.new("Foobar") }

    before do
      allow(RubygemsSyncJob).to receive(:perform_async).and_raise(err)
    end

    it "forwards exceptions to Appsignal" do
      expect(Appsignal).to receive(:set_error).with(err).and_call_original
      cron.run time: time_at(0)
    rescue StandardError
      "The exception can bubble"
    end

    it "bubbles exceptions" do
      expect { cron.run time: time_at(0) }.to raise_error(err)
    end
  end
end
