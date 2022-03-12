$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

env = ENV['RACK_ENV'].to_sym

require "bundler/setup"
Bundler.require(:default, env)

Dotenv.load unless env == :production

# optionally use sentry in production
if env == :production && ENV.key?('SENTRY_DSN')
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.processors -= [Raven::Processor::PostData]
  end
  use Raven::Rack
end

# optionally use redis to cache server config
if ENV.key?('REDIS_URL')
  $redis = Redis.new(
    url: ENV['REDIS_URL'],
    ssl_params: {
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    }
  )
end

# automatically parse json in the body
use Rack::JSONBodyParser

require 'micropublish'
run Micropublish::Server
