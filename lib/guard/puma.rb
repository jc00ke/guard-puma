require "guard"
require "guard/plugin"
require "guard/puma/runner"
require "rbconfig"
require "guard/puma/version"
require "guard/compat/plugin"

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
      UI.info "Puma starting#{port_text} in #{server}#{options[:environment]} environment."
      runner.start if options[:start_on_start]
    end

    def reload
      UI.info "Restarting Puma..."
      if options[:notifications].include?(:restarting)
        Notifier.notify("Puma restarting#{port_text} in #{options[:environment]} environment...", :title => "Restarting Puma...", :image => :pending)
      end
      if runner.restart
        UI.info "Puma restarted"
        if options[:notifications].include?(:restarted)
          Notifier.notify("Puma restarted#{port_text}.", :title => "Puma restarted!", :image => :success)
        end
      else
        UI.info "Puma NOT restarted, check your log files."
        if options[:notifications].include?(:not_restarted)
          Notifier.notify("Puma NOT restarted, check your log files.", :title => "Puma NOT restarted!", :image => :failed)
        end
      end
    end

    def stop
      if options[:notifications].include?(:stopped)
        Notifier.notify("Until next time...", :title => "Puma shutting down.", :image => :pending)
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
