require "guard"
require "guard/plugin"
require "guard/puma/runner"
require "rbconfig"
require "guard/puma/version"

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
      :debugger => false
    }

    def initialize(options = {})
      super
      @options = DEFAULT_OPTIONS.merge(options)
      @runner = ::Guard::PumaRunner.new(@options)
    end

    def start
      server = options[:server] ? "#{options[:server]} and " : ""
      UI.info "Guard::Puma will now start your app on port #{options[:port]} using #{server}#{options[:environment]} environment."
      runner.start if options[:start_on_start]
    end

    def reload
      UI.info "Restarting Puma..."
      Notifier.notify("Puma restarting on port #{options[:port]} in #{options[:environment]} environment...", :title => "Restarting Puma...", :image => :pending)
      if runner.restart
        UI.info "Puma restarted"
        Notifier.notify("Puma restarted on port #{options[:port]}.", :title => "Puma restarted!", :image => :success)
      else
        UI.info "Puma NOT restarted, check your log files."
        Notifier.notify("Puma NOT restarted, check your log files.", :title => "Puma NOT restarted!", :image => :failed)
      end
    end

    def stop
      Notifier.notify("Until next time...", :title => "Puma shutting down.", :image => :pending)
      runner.halt
    end

    def run_on_change(paths)
      reload
    end
  end
end
