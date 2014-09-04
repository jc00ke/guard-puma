require 'puma/configuration'
require 'puma/control_cli'

module Guard
  class PumaRunner < Puma::ControlCLI
    OUR_KEYS = [:start_on_start, :force_run, :timeout, :port, :host]
    DEFAULT_HOST = ::Puma::Configuration::DefaultTCPHost
    DEFAULT_PORT = ::Puma::Configuration::DefaultTCPPort
    DEFAULT_BIND = "tcp://%s:%s" % [DEFAULT_HOST, DEFAULT_PORT]

    def initialize(options)
      # add a bind if host or port were set by convenience parameter
      binds = []
      if options[:host] or options[:port]
        binds << "tcp://%s:%s" % [options[:host] || DEFAULT_HOST, options[:port] || DEFAULT_PORT]
        options.delete_if { |k| k == :host or k == :port }
      end
      @args = options.clone
      @args ||= {}
      @args[:binds] ||= []
      @args[:binds].concat(binds)
      @args[:puma_args] ||= []
      @args[:puma_args] = [@args[:puma_args]] if not options[:puma_args].respond_to?(:join)

      # drop options used only for guard
      @options = options.clone.reject { |key| OUR_KEYS.include?(key)}
      @options ||= {}
      @options[:binds] ||= []
      @options[:binds].concat(binds)

      ::Puma::Configuration.new(@options).load
    end

    # override the usual start method otherwise puma gets launched inside guard
    def start
      unless puma_running?
        @options[:pid] = spawn(['puma'].concat(puma_args).join(' '), chdir: Dir.pwd)
        Process.detach(@options[:pid])
      end
      true
    end

    def halt
      run('halt')
      prepare_configuration
      send_signal('halt') unless @message == "Command halt sent success"
    end

    def restart
      if puma_running?
        run('phased-restart')
      else
        start
      end
    end


    def run(command)
      begin
        prepare_configuration

        if is_windows?
          send_request(command)
        else
          @options.has_key?(:control_url) ? send_request(command) : send_signal(command)
        end
      rescue => e
        @message = e.message
      end
      @message
    end

    def message(msg)
      @message = msg
    end

    def send_request(command)
      orig_command = @options[:command]
      @options[:command] = command
      super()
      @options[:command] = orig_command
    end

    def send_signal(command)
      orig_command = @options[:command]
      @options[:command] = command
      super()
      @options[:command] = orig_command
    end

    # since we are only interested in non-defaults, wipe out defaults set by Puma::Configuration
    private
    def delete_default_options
      @options[:binds].delete_if { |v| v == DEFAULT_BIND }
      @options.delete_if { |k,v| v == [] or (k == :mode and v = :http) }
    end

    # this is a nasty hack :(
    private
    def puma_running?
      run('status')
      return ["Puma is running","Puma is started"].include?(@message)
    end

    private
    def have_config_file?
      @options[:config_file]
    end

    # from https://github.com/puma/puma/blob/master/lib/puma/cli.rb
    private
    def puma_args
      if have_config_file?
        puma_arg_list(@args.reject { |k,v| (@options[k] == v and k != :config_file) or OUR_KEYS.include?(k) or v == [] })
      else
        puma_arg_list(@options)
      end
    end

    private
    def puma_arg_list(options)
      options.map do |name,value|
        value = value.to_s unless value.respond_to?(:index)
        case name
        when :binds
          value.map { |v| ["--bind", v] }
        when :config_file
          ['--config', File.expand_path(value)]
        when :control_url
          ['--control', value]
        when :control_token
          ['--control-token', value]
        when :daemon
          ['--daemon']
        when :debug
          ['--debug']
        when :directory
          ['--directory', value]
        when :environment
          ['--environment', value]
        when :pidfile
          ['--pidfile', value]
        when :preload_app
          ['--preload']
        when :quiet
          ['--quiet']
        when :restart_cmd
          ['--restart_cmd', value]
        when :state
          ['--state', value]
        when :min_threads
          # puma defaults to 0:16
          ['--threads', [value || 0, options[:max_threads] || 16].join(':')]
        when :max_threads
          ['--threads', [0, options[:max_threads]].join(':')] unless options[:min_threads]
        when :mode
          ['--tcp-mode'] if value == :tcp
        when :workers
          ['--workers', value]
        else
          nil
        end
      end.flatten.compact.concat(@args[:puma_args])
    end
  end
end
