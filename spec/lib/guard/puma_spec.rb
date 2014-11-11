require 'spec_helper'
require 'guard/puma'

describe Guard::Puma do
  let(:guard) { Guard::Puma.new(options) }
  let(:options) { {} }

  describe '#initialize' do
    it "initializes with options" do
      guard

      expect(guard.runner.options[:port]).to eq(4000)
    end
  end

  describe "#default_env" do
    before do
      @rack_env = ENV['RACK_ENV']
    end

    context "when RACK_ENV is set" do
      before do
        ENV['RACK_ENV'] = 'IAMGROOT'
      end

      it "uses the value of RACK_ENV" do
        expect(Guard::Puma.default_env).to eq('IAMGROOT')
      end
    end

    context "when RACK_ENV is not set" do
      before do
        ENV.delete('RACK_ENV')
      end

      it "defaults to development" do
        expect(Guard::Puma.default_env).to eq('development')
      end
    end

    after do
      ENV['RACK_ENV'] = @rack_env
    end
  end

  describe '#start' do

    context 'start on start' do
      it "runs startup" do
        expect(guard).to receive(:start).once
        guard.start
      end
    end

    context 'no start on start' do
      let(:options) { { :start_on_start => false } }

      it "shows the right message and not run startup" do
        expect(guard.runner).to receive(:start).never
        guard.start
      end
    end
  end

  describe '#reload' do

    before do
      expect(Guard::UI).to receive(:info).with('Restarting Puma...')
      expect(Guard::Notifier).to receive(:notify).with(/Puma restarting/, hash_including(:image => :pending))
      allow(guard.runner).to receive(:restart).and_return(true)
    end

    let(:runner_stub) { allow_any_instance_of(Guard::PumaRunner).to receive(:halt) }

    it "restarts and show the message" do
      expect(Guard::UI).to receive(:info)
      expect(Guard::Notifier).to receive(:notify).with(/Puma restarted/, hash_including(:image => :success))

      guard.reload
    end

  end

  describe '#stop' do
    it "stops correctly" do
      expect(Guard::Notifier).to receive(:notify).with('Until next time...', anything)
      expect(guard.runner).to receive(:halt).once
      guard.stop
    end
  end

  describe '#run_on_change' do
    it "reloads on change" do
      expect(guard).to receive(:reload).once
      guard.run_on_change([])
    end
  end
end

