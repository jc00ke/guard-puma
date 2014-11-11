require 'spec_helper'
require 'guard/puma'

describe Guard::Puma do
  let(:guard) { Guard::Puma.new(options) }
  let(:options) { {} }

  describe '#initialize' do
    it "initializes with options" do
      guard

      guard.runner.options[:port].should == 4000
    end
  end

  describe "#default_env" do
    context "when RACK_ENV is set" do
      before do
        @rack_env = ENV['RACK_ENV']
      end

      it "uses the value of RACK_ENV" do
        ENV['RACK_ENV'] = 'production'
        Guard::Puma.default_env.should == 'production'
      end

      after do
        ENV['RACK_ENV'] = @rack_env
      end
    end

    context "when RACK_ENV is not set" do
      it "defaults to development" do
        Guard::Puma.default_env.should == 'development'
      end
    end
  end

  describe '#start' do

    context 'start on start' do
      it "runs startup" do
        guard.should_receive(:start).once
        guard.start
      end
    end

    context 'no start on start' do
      let(:options) { { :start_on_start => false } }

      it "shows the right message and not run startup" do
        guard.runner.should_receive(:start).never
        guard.start
      end
    end
  end

  describe '#reload' do

    before do
      Guard::UI.should_receive(:info).with('Restarting Puma...')
      Guard::Notifier.should_receive(:notify).with(/Puma restarting/, hash_including(:image => :pending))
      guard.runner.stub(:restart).and_return(true)
    end

    let(:runner_stub) { Guard::PumaRunner.any_instance.stub(:halt) }

    it "restarts and show the message" do
      Guard::UI.should_receive(:info)
      Guard::Notifier.should_receive(:notify).with(/Puma restarted/, hash_including(:image => :success))

      guard.reload
    end

  end

  describe '#stop' do
    it "stops correctly" do
      Guard::Notifier.should_receive(:notify).with('Until next time...', anything)
      guard.runner.should_receive(:halt).once
      guard.stop
    end
  end

  describe '#run_on_change' do
    it "reloads on change" do
      guard.should_receive(:reload).once
      guard.run_on_change([])
    end
  end
end

