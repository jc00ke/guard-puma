# Changes

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
