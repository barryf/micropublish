require "bundler/setup"
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

#I18n.enforce_available_locales = false

require_relative 'lib/micropublish'
run Micropublish::Server