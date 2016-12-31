module Micropublish
  class Micropub

    def initialize(micropub, token)
      @micropub = micropub
      @token = token
    end

    def syndicate_to
      query = { q: 'syndicate-to' }
      begin
        response = HTTParty.get(@micropub, query: query, headers: headers)
      rescue => e
        raise MicropubError.new("Unable to retrieve <em>syndicate-to</em> " +
          "list from Micropub endpoint via <code>?q=syndicate-to</code>. " +
          "Error received: \"#{e.message}\""
        )
      end
      return unless response.code.to_i == 200
      JSON.parse(response.body)['syndicate-to']
    end

    def source(url)
      validate_url!(url)
      query = { q: 'source', url: url }
      response = HTTParty.get(@micropub, query: query, headers: headers)
      body = JSON.parse(response.body)
      Post.new(body['type'], body['properties'])
    end

    def validate_url!(url)
      unless Auth.valid_uri?(url)
        raise MicropubError.new("\"#{url}\" is not a valid URL.")
      end
      #micropub_uri = URI.parse(@micropub)
      #url_uri = URI.parse(url)
      #unless micropub_uri.host == url_uri.host
      #  raise MicropubError.new(
      #    "Post URL \"#{url}\" must be from the same host as your Micropub " +
      #    "endpoint (\"#{@micropub}\").")
      #end
    end

    def headers
      {
        'Authorization' => "Bearer #{@token}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end

    def self.find_commands(params)
      Hash[params.map { |k,v| [k,v] if k.start_with?('mp-') }.compact]
    end

  end

  class MicropubError < MicropublishError
    def initialize(message, body=nil)
      super("micropub", message, body)
    end
  end
end
