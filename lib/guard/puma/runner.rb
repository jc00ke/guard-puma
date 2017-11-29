require 'net/http'
require 'puma/configuration'

module Guard
  class PumaRunner

    MAX_WAIT_COUNT = 20

    attr_reader :options, :control_url, :control_token, :cmd_opts

    def initialize(options)
      @control_token = options.delete(:control_token) { |_| ::Puma::Configuration.random_token }
      @control = "localhost"
      @control_port = (options.delete(:control_port) || '9293')
      @control_url = "#{@control}:#{@control_port}"
      @quiet = options.delete(:quiet) { true }
      @options = options

      puma_options = if options[:config]
        {
          '--config' => options[:config],
          '--control-token' => @control_token,
          '--control' => "tcp://#{@control_url}",
          '--environment' => options[:environment]
        }
      else
        {
          '--port' => options[:port],
          '--control-token' => @control_token,
          '--control' => "tcp://#{@control_url}",
          '--environment' => options[:environment]
        }
      end
      [:bind, :threads].each do |opt|
        puma_options["--#{opt}"] = options[opt] if options[opt]
      end
      puma_options = puma_options.to_a.flatten
      puma_options << '-q' if @quiet
      @cmd_opts = puma_options.join ' '
    end

    def start
      if ENV['SHELL'].nil? && !ENV['COMSPEC'].nil?
        # windows command prompt
        system %{cd "#{Dir.pwd}" && start "" /B cmd /C "puma #{cmd_opts}"}
      else
        system %{sh -c 'cd #{Dir.pwd} && puma #{cmd_opts} &'}
      end
    end

    def halt
      Net::HTTP.get build_uri('halt')
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
