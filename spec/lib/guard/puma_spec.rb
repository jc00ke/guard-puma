require 'spec_helper'
require 'guard/puma'

describe Guard::Puma do
  let(:guard) { Guard::Puma.new(watchers, options) }
  let(:watchers) { [] }
  let(:options) { {} }

  describe '#initialize' do
    it "initializes with options" do
      guard

      guard.runner.options[:port].should == 4000
    end
  end

  describe '#start' do
    let(:ui_expectation) { Guard::UI.should_receive(:info).with(/#{Guard::Puma::DEFAULT_OPTIONS[:port]}/) }

    context 'start on start' do
      it "shows the right message and run startup" do
        guard.should_receive(:reload).once
        ui_expectation
        guard.start
      end
    end

    context 'no start on start' do
      let(:options) { { :start_on_start => false } }

      it "shows the right message and not run startup" do
        guard.should_receive(:reload).never
        ui_expectation
        guard.start
      end
    end
  end

  describe '#reload' do
    let(:pid) { '12345' }

    before do
      Guard::UI.should_receive(:info).with('Restarting Puma...')
      Guard::Notifier.should_receive(:notify).with(/Puma restarting/, hash_including(:image => :pending))
      Guard::PumaRunner.any_instance.stub(:pid).and_return(pid)
    end

    let(:runner_stub) { Guard::PumaRunner.any_instance.stub(:restart) }

    context 'with pid file' do
      before do
        runner_stub.and_return(true)
      end

      it "restarts and show the pid file" do
        Guard::UI.should_receive(:info).with(/#{pid}/)
        Guard::Notifier.should_receive(:notify).with(/Puma restarted/, hash_including(:image => :success))

        guard.reload
      end
    end

    context 'no pid file' do
      before do
        runner_stub.and_return(false)
      end

      it "restarts and show the pid file" do
        Guard::UI.should_receive(:info).with(/#{pid}/).never
        Guard::UI.should_receive(:info).with((/Puma NOT restarted/))
        Guard::Notifier.should_receive(:notify).with(/Puma NOT restarted/, hash_including(:image => :failed))

        guard.reload
      end
    end
  end

  describe '#stop' do
    it "stops correctly" do
      Guard::Notifier.should_receive(:notify).with('Until next time...', anything)
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

