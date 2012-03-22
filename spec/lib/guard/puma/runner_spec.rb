require 'spec_helper'
require 'guard/puma/runner'
require 'fakefs/spec_helpers'

describe Guard::PumaRunner do
  let(:runner) { Guard::PumaRunner.new(options) }
  let(:environment) { 'development' }
  let(:port) { 4000 }
  
  let(:default_options) { { :environment => environment, :port => port } }
  let(:options) { default_options }
  
  describe '#pid' do
    include FakeFS::SpecHelpers

    context 'pid file exists' do
      let(:pid) { 12345 }

      before do
        FileUtils.mkdir_p File.split(runner.pid_file).first
        File.open(runner.pid_file, 'w') { |fh| fh.print pid }
      end

      it "reads the pid" do
        runner.pid.should == pid
      end
    end

    context 'pid file does not exist' do
      it "returns nil" do
        if defined?(Rubinius)
          runner.pid.should == nil
        else
          runner.pid.should be_nil
        end
      end
    end
  end

  describe '#start' do
    let(:kill_expectation) { runner.expects(:kill_unmanaged_pid!) }
    let(:pid_stub) { runner.stubs(:has_pid?) }

    before do
      runner.expects(:run_puma_command!).once
    end

    context 'do not force run' do
      before do
        pid_stub.returns(true)
        kill_expectation.never
        runner.expects(:wait_for_pid_action).never
      end

      it "acts properly" do
        runner.start.should be_true
      end
    end

    context 'force run' do
      let(:options) { default_options.merge(:force_run => true) }

      before do
        pid_stub.returns(true)
        kill_expectation.once
        runner.expects(:wait_for_pid_action).never
      end

      it "acts properly" do
        runner.start.should be_true
      end
    end

    context "don't write the pid" do
      before do
        pid_stub.returns(false)
        kill_expectation.never
        runner.expects(:wait_for_pid_action).times(Guard::PumaRunner::MAX_WAIT_COUNT)
      end

      it "acts properly" do
        runner.start.should be_false
      end
    end
  end

  describe '#sleep_time' do
    let(:timeout) { 30 }
    let(:options) { default_options.merge(:timeout => timeout) }

    it "adjusts the sleep time as necessary" do
      runner.sleep_time.should == (timeout.to_f / Guard::PumaRunner::MAX_WAIT_COUNT.to_f)
    end
  end

  describe "#build_puma_command" do
    let(:command) {
      Guard::PumaRunner.new(options).build_puma_command
    }
    context "with config" do
      let(:options) {{ :config => path }}
      let(:path) { "/tmp/elephants" }
      it "adds path to command" do
        command.should match("--config #{path}")
      end
    end

    context "with bind" do
      let(:options) {{ :bind => uri }}
      let(:uri) { "tcp://foo" }
      it "adds uri option to command" do
        command.should match("--bind #{uri}")
      end
    end

    context "with state" do
      let(:options) {{ :state => path }}
      let(:path) { "/tmp/zebras" }
      it "adds path to command" do
        command.should match("--state #{path}")
      end
    end

    context "with control" do
      let(:options) {{ :control => uri }}
      let(:uri) { "http://foo" }
      it "adds path to command" do
        command.should match("--control #{uri}")
      end
    end

    context "with control_token" do
      let(:options) {{ :control_token => token }}
      let(:token) { "IMMA_TOKEN" }
      it "adds path to command" do
        command.should match("--control-token #{token}")
      end
    end

    context "with threads" do
      let(:options) {{ :threads => threads }}
      let(:threads) { "13:42" }
      it "adds path to command" do
        command.should match("--threads #{threads}")
      end
    end
  end
end
