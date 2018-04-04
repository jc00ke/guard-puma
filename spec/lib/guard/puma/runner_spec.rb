require 'spec_helper'
require 'guard/puma/runner'

describe Guard::PumaRunner do
  let(:runner) { Guard::PumaRunner.new(options) }
  let(:environment) { 'development' }
  let(:port) { 4000 }

  let(:default_options) { { environment: environment, port: port } }
  let(:options) { default_options }

  describe "#initialize" do
    it "sets options" do
      expect(runner.options).to eq(options)
    end
  end

  %w[halt restart].each do |cmd|
    describe cmd do
      context "without pumactl" do
        let(:options) { { pumactl: false } }

        let(:uri) {
          URI(
            "http://#{runner.control_url}/#{cmd}?token=#{runner.control_token}"
          )
        }

        it "#{cmd}s" do
          expect(Net::HTTP).to receive(:get).with(uri).once
          runner.public_send(cmd)
        end
      end

      context "with pumactl" do
        let(:options) { { pumactl: true } }

        before do
          allow(runner).to receive(:in_windows_cmd?).and_return(false)
        end

        let(:command) {
          %(sh -c 'cd #{Dir.pwd} && pumactl #{runner.cmd_opts} #{cmd} ')
        }

        it "#{cmd}s" do
          expect(Kernel).to receive(:system).with(command).once
          runner.public_send(cmd)
        end
      end
    end
  end

  describe "#start" do
    context "when on Windows" do
      before do
        allow(runner).to receive(:in_windows_cmd?).and_return(true)
      end

      it "runs the Windows command" do
        expect(Kernel).to receive(:system).with(%r{cmd /C ".+"})
        runner.start
      end
    end

    context "when on *nix" do
      before do
        allow(runner).to receive(:in_windows_cmd?).and_return(false)
      end

      it "runs the *nix command" do
        expect(Kernel).to receive(:system).with(/sh -c '.+'/)
        runner.start
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
      let(:path) { "/tmp/elephants" }
      let(:environment) { "special_dev" }

      context "without pumactl" do
        let(:options) { { config: path, pumactl: false } }

        it "adds path to command" do
          expect(runner.cmd_opts).to match("--config #{path}")
        end

        context "and additional options" do
          let(:options) {
            {
              config: path, port: "4000",
              quiet: false, environment: environment
            }
          }

          it "assumes options are set in config" do
            expect(runner.cmd_opts).to match("--config #{path}")
            expect(runner.cmd_opts).to match(/--control-token [0-9a-f]{10,}/)
            expect(runner.cmd_opts).to match("--control tcp")
            expect(runner.cmd_opts).to match("--environment #{environment}")
          end
        end
      end

      context "with pumactl" do
        let(:options) { { config: path, pumactl: true } }

        it "adds path to command" do
          expect(runner.cmd_opts).to match("--config-file #{path}")
        end

        context "and additional options" do
          let(:options) {
            {
              pumactl: true,
              config: path, port: "4000",
              quiet: false
            }
          }

          it "assumes options are set in config" do
            expect(runner.cmd_opts).to match("--config-file #{path}")
            expect(runner.cmd_opts).to match(/--control-token [0-9a-f]{10,}/)
            expect(runner.cmd_opts).to match("--control-url tcp")
          end
        end
      end
    end

    context "with bind" do
      let(:uri) { "tcp://foo" }

      context "without pumactl" do
        let(:options) { { pumactl: false, bind: uri } }

        it "adds uri option to command" do
          expect(runner.cmd_opts).to match("--bind #{uri}")
        end
      end

      context "with pumactl" do
        let(:options) { { pumactl: true, bind: uri } }

        it "raises ArgumentError about incompatible options" do
          expect(Guard::Compat::UI).to receive(:warning).with(/bind.+pumactl/)
          runner.cmd_opts
        end
      end
    end

    context "with control_token" do
      let(:token) { "imma-token" }
      let(:options) { { control_token: token } }

      it "adds token to command" do
        expect(runner.cmd_opts).to match(/--control-token #{token}/)
      end
    end

    context "with threads" do
      let(:threads) { "13:42" }

      context "without pumactl" do
        let(:options) { { pumactl: false, threads: threads } }

        it "adds threads option to command" do
          expect(runner.cmd_opts).to match("--threads #{threads}")
        end
      end

      context "with pumactl" do
        let(:options) { { pumactl: true, threads: threads } }

        it "raises ArgumentError about incompatible options" do
          expect(Guard::Compat::UI).to receive(:warning).with(/threads.+pumactl/)
          runner.cmd_opts
        end
      end
    end

    context "with environment" do
      let(:environment) { "development" }

      context "without pumactl" do
        let(:options) { { pumactl: false, environment: environment } }

        it "adds environment option to command" do
          expect(runner.cmd_opts).to match("--environment #{environment}")
        end
      end

      context "with pumactl" do
        let(:options) { { pumactl: true, environment: environment } }

        it "warns about incompatible options" do
          expect(Guard::Compat::UI).to receive(:warning).with(/environment.+pumactl/)
          runner.cmd_opts
        end
      end
    end
  end
end
