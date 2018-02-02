require 'guard/compat/plugin'
require_relative 'puma/runner'
require_relative 'puma/version'

module Guard
  class Puma < Plugin
    attr_reader :options, :runner

    def self.default_env
      ENV.fetch('RACK_ENV', 'development')
    end

    DEFAULT_OPTIONS = {
      :port => 4000,
      :environment => default_env,
      :start_on_start => true,
      :force_run => false,
      :timeout => 20,
      :debugger => false,
      :notifications => %i[restarting restarted not_restarted stopped]
    }

    def initialize(options = {})
      super
      @options = DEFAULT_OPTIONS.merge(options)
      @options[:port] = nil if @options.key?(:config)
      @runner = ::Guard::PumaRunner.new(@options)
    end

    def start
      server = options[:server] ? "#{options[:server]} and " : ""
      Compat::UI.info(
        "Puma starting#{port_text} in #{server}#{options[:environment]} environment."
      )
      runner.start if options[:start_on_start]
    end

    def reload
      Compat::UI.info "Restarting Puma..."
      if options[:notifications].include?(:restarting)
        Compat::UI.notify(
          "Puma restarting#{port_text} in #{options[:environment]} environment...",
          title: "Restarting Puma...", image: :pending
        )
      end
      if runner.restart
        Compat::UI.info "Puma restarted"
        if options[:notifications].include?(:restarted)
          Compat::UI.notify(
            "Puma restarted#{port_text}.",
            title: "Puma restarted!", image: :success
          )
        end
      else
        Compat::UI.info "Puma NOT restarted, check your log files."
        if options[:notifications].include?(:not_restarted)
          Compat::UI.notify(
            "Puma NOT restarted, check your log files.",
            title: "Puma NOT restarted!", image: :failed
          )
        end
      end
    end

    def stop
      if options[:notifications].include?(:stopped)
        Compat::UI.notify(
          "Until next time...",
          title: "Puma shutting down.", image: :pending
        )
      end
      runner.halt
    end

    def run_on_changes(paths)
      reload
    end

    private

    def port_text
      " on port #{options[:port]}" if options[:port]
    end
  end
end
