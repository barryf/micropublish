$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

ENV['RACK_ENV'] = 'test'

require "bundler/setup"
Bundler.require(:default, :test)

require 'rack/test'
require 'rspec'
require 'webmock/rspec'
require 'micropublish'

module RSpecMixin
  include Rack::Test::Methods
  def app
    Micropublish::Server
  end
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end
end
