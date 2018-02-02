# Changes

## master

* Improve `guard-compat` using (https://github.com/guard/guard-compat#migrating-your-api-calls)
* Remove unused `pry` dependency
* Update versions of dependencies

## 0.4.1

* Improve notifications. Via #30

## 0.4.0

* Support Windows with custom start command. Via #29

## 0.3.6

* Use a secure random token by default for the control token. Fixes #23

## 0.3.5

* If puma crashed don't fail when trying to restart. Fixes #22

## 0.3.4

* Respect the environment when using a config file. Fixes #21

## 0.3.3

* Update deps
* Kill testing Ruby < 2.2.5
* Fix control when using `--config`

## 0.3.2

* Update Guardfile to support new options
* Let --config take precedence over default options

## 0.3.1

* Update RSpec to 3.1.0+
* Fix Travis CI builds on Rubinius

## 0.3.0

* Depend on rake 10.2+
* Update Guard::Puma initialize method to accept only options hash
* Depend on Guard 2.8+
* Get environment from  RACK_ENV by default

## 0.2.5

* Change rb-inotify and libnotify to be development dependencies
* Update test Rubies

## 0.2.4

* Fix bug where runner not respecting environment set in Guard options

## 0.2.3

* Add quiet flag to suppress output

## 0.2.2

* Remove unused dependency on RestClient.

## 0.2.1

* Fix restarting & halting inside the runner.

## 0.2.0

* Switched to puma's control server. pid file was too messy.

## 0.1.0

* Fixed pid file path. Ready for general consumption.

## 0.0.x

* Added all CLI options for Puma
* Ported over [guard-rack](https://github.com/dblock/guard-rack)
