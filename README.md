# Guard::Puma
[![Build Status](https://secure.travis-ci.org/jc00ke/guard-puma.png)](http://travis-ci.org/jc00ke/guard-puma)
[![Dependency Status](https://gemnasium.com/jc00ke/guard-puma.png?travis)](https://gemnasium.com/jc00ke/guard-puma)

Restart Puma when some files change

## Installation

Add this line to your application's Gemfile:

    gem 'guard-puma'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install guard-puma

## Usage

`guard init puma` or add the following manually to your `Guardfile`

```ruby
guard 'puma', :port => 4000 do
  watch('Gemfile.lock')
  watch(%r{^config|lib/.*})
end
```

## Options

* `:port` is the port number to run on (default `4000`)
* `:environment` is the environment to use (default `development`)
* `:start_on_start` will start the server when starting Guard (default `true`)
* `:force_run` kills any process that's holding open the listen port before attempting to (re)start Puma (default `false`).
* `:daemon` runs the server as a daemon, without any output to the terminal that ran `guard` (default `false`).
* `:quiet` runs the server in quiet mode, suppressing output (default `true`).
* `:debugger` runs the server with the debugger enabled (default `false`). Required ruby-debug gem.
* `:timeout` waits this number of seconds when restarting the Puma server before reporting there's a problem (default `20`).
* `:config` is the path to the Puma config file (optional)
* `:bind` is URI to bind to (tcp:// and unix:// only) (optional)
* `:control_token` is the token to use as authentication for the control server(optional)
* `:control_port` is the port to use for the control server(optional)
* `:threads` is the min:max number of threads to use. Defaults to 0:16 (optional)

## Contributing

1. Fork it
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Leave the version alone!
1. Add what you changed to CHANGES.md
1. Commit your changes (`git commit -am 'Added some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create new Pull Request
