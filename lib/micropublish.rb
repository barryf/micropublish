module Micropublish

  class MicropublishError < StandardError
    attr_reader :type, :message, :body
    def initialize(type, message, body=nil)
      @type = type
      @message = message
      @body = body
      super(message)
    end
  end

end

require_relative 'micropublish/version'

require_relative 'micropublish/auth'
require_relative 'micropublish/compare'
require_relative 'micropublish/endpoints_finder'
require_relative 'micropublish/post'
require_relative 'micropublish/request'
require_relative 'micropublish/micropub'
require_relative 'micropublish/helpers'

require_relative 'micropublish/server'
