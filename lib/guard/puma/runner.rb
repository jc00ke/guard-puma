require 'net/http'

module Guard
  class PumaRunner

    MAX_WAIT_COUNT = 20

    attr_reader :options, :control_url, :control_token

    def initialize(options)
      @control_token = (options.delete(:control_token) || 'pumarules')
      @control = "0.0.0.0"
      @control_port = (options.delete(:control_port) || '9293')
      @control_url = "#{@control}:#{@control_port}"
      @options = options
    end

    def start
      puma_options = {
        '--port' => options[:port],
        '--control-token' => @control_token,
        '--control' => "tcp://#{@control_url}"
      }
      [:config, :bind, :threads].each do |opt|
        puma_options["--#{opt}"] = options[opt] if options[opt]
      end
      opts = puma_options.to_a.flatten << '-q'

      %{sh -c 'cd #{Dir.pwd} && puma #{opts.join(' ')} &'}
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
      Net::HTTP.get((build_uri(cmd)))
    end

    def build_uri(cmd)
      URI("http://#{control_url}/#{cmd}?token=#{control_token}")
    end

  end
end

