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
        puma_options_key(:config) => options.fetch(:config, "-"),
        puma_options_key(:control_token) => @control_token,
        puma_options_key(:control_url) => "tcp://#{@control_url}"
      }
      if options[:config]
        puma_options['--config'] = options[:config]
      elsif default_config_file_exists?
        puma_options['--config'] = DEFAULT_CONFIG_FILE_PATH
      else
        puma_options['--port'] = options[:port]
      end
      %i[bind threads environment]
        .select { |opt| options[opt] }
        .each do |opt|
          if pumactl
            Compat::UI.warning(
              "`#{opt}` option is not compatible with `pumactl` option"
            )
          else
            puma_options["--#{opt}"] = options[opt]
          end
        end
      puma_options = puma_options.to_a.flatten
      puma_options << '--quiet' if @quiet
      @cmd_opts = puma_options.join ' '
    end

    def start
      Kernel.system build_command('start')
    end

    def halt
      run_puma_command!('halt')
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

    DEFAULT_CONFIG_FILE_PATH = "config/puma.rb".freeze

    PUMA_OPTIONS_KEYS_BY_PUMACTL = {
      true => {
        config:      '--config-file',
        control_url: '--control-url'
      }.freeze,
      false => {
        config:      '--config',
        control_url: '--control'
      }.freeze
    }.freeze

    private_constant :PUMA_OPTIONS_KEYS_BY_PUMACTL

    def default_config_file_exists?
      File.exist?(DEFAULT_CONFIG_FILE_PATH)
    end

    def puma_options_key(key)
      keys = PUMA_OPTIONS_KEYS_BY_PUMACTL[@pumactl]
      keys.fetch(key) { |k| "--#{k.to_s.tr('_', '-')}" }
    end

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
