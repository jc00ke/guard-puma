require 'net/http'
require 'puma/configuration'

module Guard
  class PumaRunner

    MAX_WAIT_COUNT = 20

    attr_reader :options, :control_url, :control_token, :cmd_opts, :pumactl

    def initialize(options)
      @control_token = options.delete(:control_token) { |_| ::Puma::Configuration.random_token }
      @control_port = (options.delete(:control_port) || '9293')
      @control_url = "localhost:#{@control_port}"
      @quiet = options.delete(:quiet) { true }
      @pumactl = options.delete(:pumactl) { false }
      @options = options

      puma_options = {
        (pumactl ? '--config-file' : '--config') => options[:config],
        '--control-token' => @control_token,
        (pumactl ? '--control-url' : '--control') => "tcp://#{@control_url}"
      }
      if options[:config]
        puma_options['--config'] = options[:config]
      else
        puma_options['--port'] = options[:port]
      end
      %i[bind threads environment].each do |opt|
        next unless options[opt]
        if pumactl
          next Compat::UI.warning(
            "`#{opt}` option is not compatible with `pumactl` option"
          )
        end
        puma_options["--#{opt}"] = options[opt]
      end
      puma_options = puma_options.to_a.flatten
      puma_options << '--quiet' if @quiet
      @cmd_opts = puma_options.join ' '
    end

    def start
      Kernel.system build_command('start')
    end

    def halt
      if pumactl
        Kernel.system build_command('halt')
      else
        Net::HTTP.get build_uri('halt')
      end
      # server may not have been stopped correctly, but we are halting so who cares.
      return true
    end

    def restart
      if run_puma_command!('restart')
        return true
      else
        # server may not have been started correctly, or crashed. Let's try to start it.
        return start
      end
    end

    def sleep_time
      options[:timeout].to_f / MAX_WAIT_COUNT.to_f
    end

    private

    def run_puma_command!(cmd)
      if pumactl
        Kernel.system build_command(cmd)
      else
        Net::HTTP.get build_uri(cmd)
      end
      return true
    rescue Errno::ECONNREFUSED => e
      # server may not have been started correctly.
      false
    end

    def build_uri(cmd)
      URI "http://#{control_url}/#{cmd}?token=#{control_token}"
    end

    def build_command(cmd)
      puma_cmd = "#{pumactl ? 'pumactl' : 'puma'} #{cmd_opts} #{cmd if pumactl}"
      background = cmd == 'start'
      if in_windows_cmd?
        windows_cmd(puma_cmd, background)
      else
        nix_cmd(puma_cmd, background)
      end
    end

    def nix_cmd(puma_cmd, background = false)
      %(sh -c 'cd #{Dir.pwd} && #{puma_cmd} #{'&' if background}')
    end

    def windows_cmd(puma_cmd, background = false)
      %(cd "#{Dir.pwd}" && #{'start "" /B' if background} cmd /C "#{puma_cmd}")
    end

    def in_windows_cmd?
      ENV['SHELL'].nil? && !ENV['COMSPEC'].nil?
    end

  end
end
