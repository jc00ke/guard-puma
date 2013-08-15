require 'net/http'

module Guard
  class PumaRunner

    MAX_WAIT_COUNT = 20

    attr_reader :options, :control_url, :control_token, :cmd_opts

    def initialize(options)
      @control_token = (options.delete(:control_token) || 'pumarules')
      @control = "0.0.0.0"
      @control_port = (options.delete(:control_port) || '9293')
      @control_url = "#{@control}:#{@control_port}"
      @quiet = options.delete(:quiet) { true }
      @options = options

      puma_options = {
        '--port' => options[:port],
        '--control-token' => @control_token,
        '--control' => "tcp://#{@control_url}",
        '--environment' => options[:environment]
      }
      [:config, :bind, :threads].each do |opt|
        puma_options["--#{opt}"] = options[opt] if options[opt]
      end
      puma_options = puma_options.to_a.flatten
      puma_options << '-q' if @quiet
      @cmd_opts = puma_options.join ' '
    end

    def start
      system %{sh -c 'cd #{Dir.pwd} && puma #{cmd_opts} &'}
    end

    def halt
      run_puma_command!("halt")
    end

    def restart
      run_puma_command!("restart")
    end

    def sleep_time
      options[:timeout].to_f / MAX_WAIT_COUNT.to_f
    end

    private
    
    def run_puma_command!(cmd)
      Net::HTTP.get build_uri(cmd)
      return true
    rescue Errno::ECONNREFUSED => e
      # server may not have been started correctly.
      false
    end

    def build_uri(cmd)
      URI "http://#{control_url}/#{cmd}?token=#{control_token}"
    end

  end
end

