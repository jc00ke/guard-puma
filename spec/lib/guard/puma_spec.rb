require 'spec_helper'
require 'guard/puma'
require 'guard/compat/test/helper'

describe Guard::Puma do
  let(:guard) { Guard::Puma.new(options) }
  let(:options) { {} }

  describe '#initialize' do
    it "initializes with options" do
      guard

      expect(guard.runner.options[:port]).to eq(4000)
    end

    context "when config is set" do
      let(:options) { { :config => 'config.rb' } }

      it "initializes with config option" do
        expect(guard.runner.options[:config]).to eq('config.rb')
      end

      it "initializes without port option" do
        expect(guard.runner.options[:port]).to be_nil
      end
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
    context "start on start" do
      it "runs startup" do
        expect(guard.runner).to receive(:start).once
        expect(Guard::Compat::UI).to receive(:info).with(/Puma starting/)
        guard.start
      end
    end

    context "no start on start" do
      let(:options) { { start_on_start: false } }

      it "doesn't show the message and not run startup" do
        expect(guard.runner).not_to receive(:start)
        expect(Guard::Compat::UI).not_to receive(:info).with(/Puma starting/)
        guard.start
      end
    end

    describe "UI message" do
      before do
        allow(guard.runner).to receive(:start)
      end

      context "when no config option set" do
        it "contains port" do
          expect(Guard::Compat::UI).to receive(:info)
            .with(/starting on port 4000/)
          guard.start
        end
      end

      context "when config option set" do
        let(:options) { { config: 'config.rb' } }

        it "doesn't contain port" do
          expect(Guard::Compat::UI).to receive(:info).with(/starting/)
          guard.start
        end
      end
    end
  end

  describe "#reload" do
    let(:zero_restart_timeout) { { restart_timeout: 0 } }
    let(:options) { zero_restart_timeout }

    before do
      allow(guard.runner).to receive(:restart).and_return(true)
      allow_any_instance_of(Guard::PumaRunner).to receive(:halt)
    end

    context "with default options" do
      it "restarts and show the message" do
        expect(Guard::Compat::UI).to receive(:info).with('Restarting Puma...')
        expect(Guard::Compat::UI).to receive(:info).with('Puma restarted')

        expect(Guard::Compat::UI).to receive(:notify).with(
          /restarting on port 4000/,
          hash_including(title: "Restarting Puma...", image: :pending)
        )

        expect(Guard::Compat::UI).to receive(:notify).with(
          "Puma restarted on port 4000.",
          hash_including(title: "Puma restarted!", image: :success)
        )

        guard.reload
      end
    end

    context "with config option set" do
      let(:options) { { config: "config.rb" }.merge!(zero_restart_timeout) }

      it "restarts and show the message" do
        expect(Guard::Compat::UI).to receive(:info).with('Restarting Puma...')
        expect(Guard::Compat::UI).to receive(:info).with('Puma restarted')

        expect(Guard::Compat::UI).to receive(:notify).with(
          /restarting/,
          hash_including(title: "Restarting Puma...", image: :pending)
        )

        expect(Guard::Compat::UI).to receive(:notify).with(
          "Puma restarted.",
          hash_including(title: "Puma restarted!", image: :success)
        )

        guard.reload
      end
    end

    context "with custom :notifications option" do
      let(:options) do
        { notifications: [:restarted] }.merge!(zero_restart_timeout)
      end

      it "restarts and show the message only about restarted" do
        allow(Guard::Compat::UI).to receive(:info)

        expect(Guard::Compat::UI).not_to receive(:notify).with(/restarting/)
        expect(Guard::Compat::UI).to receive(:notify)
          .with(/restarted/, kind_of(Hash))

        guard.reload
      end
    end

    context "with empty :notifications option" do
      let(:options) { { notifications: [] }.merge!(zero_restart_timeout) }

      it "restarts and doesn't show the message" do
        allow(Guard::Compat::UI).to receive(:info)

        expect(Guard::Compat::UI).not_to receive(:notify)

        guard.reload
      end
    end

    context "with :restart_timeout option" do
      let(:restart_timeout) { 1.0 }
      let(:options) { { restart_timeout: restart_timeout } }

      before { sleep restart_timeout }

      it "doesn't restarts during restart timeout" do
        allow(Guard::Compat::UI).to receive(:info)
        allow(Guard::Compat::UI).to receive(:notify)

        expect(guard.runner).to receive(:restart).twice

        guard.reload
        sleep restart_timeout / 2
        guard.reload
        sleep restart_timeout
        guard.reload
      end
    end
  end

  describe "#stop" do
    context "with default options" do
      it "stops correctly with notification" do
        expect(Guard::Compat::UI).to receive(:notify)
          .with('Until next time...', anything)
        expect(guard.runner).to receive(:halt).once
        guard.stop
      end
    end

    context "with custom :notifications option" do
      let(:options) { { notifications: [] } }

      it "stops correctly without notification" do
        expect(Guard::Compat::UI).not_to receive(:notify)
        expect(guard.runner).to receive(:halt).once
        guard.stop
      end
    end

    context "start on start" do
      it "stops correctly with notification" do
        expect(guard.runner).to receive(:halt).once
        expect(Guard::Compat::UI).to receive(:notify)
          .with('Until next time...', anything)
        guard.stop
      end
    end

    context "no start on start" do
      let(:options) { { start_on_start: false } }

      it "doesn't show the message and doesn't halt" do
        expect(guard.runner).not_to receive(:halt)
        expect(Guard::Compat::UI).not_to receive(:notify)
        guard.stop
      end
    end
  end

  describe "#run_on_changes" do
    it "reloads on change" do
      expect(guard).to receive(:reload).once
      guard.run_on_changes([])
    end
  end
end
