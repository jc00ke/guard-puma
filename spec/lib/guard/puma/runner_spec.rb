require 'spec_helper'
require 'guard/puma/runner'

describe Guard::PumaRunner do
  let(:runner) { Guard::PumaRunner.new(options) }
  let(:environment) { 'development' }
  let(:port) { 4000 }
  
  let(:default_options) { { :environment => environment, :port => port } }
  let(:options) { default_options }

  describe "#initialize" do
    it "sets options" do
      expect(runner.options).to eq(options)
    end
  end
  
  %w(halt restart).each do |cmd|
    describe cmd do
      before do
        allow(runner).to receive(:build_uri).with(cmd).and_return(uri)
      end
      let(:uri) { URI("http://#{runner.control_url}/#{cmd}?token=#{runner.control_token}") }
      it "#{cmd}s" do
        expect(Net::HTTP).to receive(:get).with(uri).once
        runner.send(cmd.intern)
      end
    end
  end
  

  describe '#sleep_time' do
    let(:timeout) { 30 }
    let(:options) { default_options.merge(:timeout => timeout) }

    it "adjusts the sleep time as necessary" do
      expect(runner.sleep_time).to eq(timeout.to_f / Guard::PumaRunner::MAX_WAIT_COUNT.to_f)
    end
  end

  describe "#build_puma_command" do
    let(:runner) { Guard::PumaRunner.new(options) }
    let(:command) { runner.start }

    context "with config" do
      let(:options) {{ :config => path }}
      let(:path) { "/tmp/elephants" }
      it "adds path to command" do
        expect(runner.cmd_opts).to match("--config #{path}")
      end
    end

    context "with bind" do
      let(:options) {{ :bind => uri }}
      let(:uri) { "tcp://foo" }
      it "adds uri option to command" do
        expect(runner.cmd_opts).to match("--bind #{uri}")
      end
    end

    context "with control_token" do
      let(:options) {{ :control_token => token }}
      let(:token) { "imma-token" }
      it "adds token to command" do
        expect(runner.cmd_opts).to match(/--control-token #{token}/)
      end
    end

    context "with threads" do
      let(:options) {{ :threads => threads }}
      let(:threads) { "13:42" }
      it "adds path to command" do
        expect(runner.cmd_opts).to match("--threads #{threads}")
      end
    end
  end
end
