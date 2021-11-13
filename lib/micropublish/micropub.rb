module Micropublish
  class Micropub

    def initialize(micropub, token)
      @micropub = micropub
      @token = token
    end

    def query(params)
      begin
        response = HTTParty.get(@micropub, query: params, headers: headers)
        JSON.parse(response.body)
      rescue
      end
    end

    def config
      data = cache_get('config')
      unless data
        data = query({ q: 'config' })
        cache_set('config', data)
      end
      data
    end

    def channels
      data = cache_get('channel')
      unless data
        data = query({ q: 'channel' }) || config
        cache_set('channel', data)
      end
      data['channels'] if data.is_a?(Hash) && data.key?('channels')
    end

    def syndicate_to(subtype = nil)
      params = { q: 'syndicate-to' }
      params['post-type'] = subtype if subtype
      data = cache_get(params.to_s)
      unless data
        data = query(params) || config
        cache_set(params.to_s, data)
      end
      data['syndicate-to'] if data.is_a?(Hash) && data.key?('syndicate-to')
    end

    def source_all(url)
      body = get_source(url)
      Post.new(body['type'], body['properties'])
    end

    def source_properties(url, properties)
      body = get_source(url, properties)
      # assume h-entry
      Post.new(['h-entry'], body['properties'])
    end

    def get_source(url, properties=nil)
      validate_url!(url)
      query = { q: 'source', url: url }
      query['properties[]'] = properties if properties
      uri = URI(@micropub)
      uri.query = (uri.query.nil? ? "" : uri.query + "&") + URI.encode_www_form(query)
      response = HTTParty.get(uri.to_s, headers: headers)
      begin
        body = JSON.parse(response.body)
      rescue JSON::ParserError
        raise MicropubError.new("There was an error retrieving the source " +
          "for \"#{url}\" from your endpoint. Please ensure you enter the " +
          "URL for a valid MF2 post.")
      end
      if body.key?('error_description')
        raise MicropubError.new("Micropub server returned an error: " +
          "\"#{body['error_description']}\".")
      elsif body.key?('error')
        raise MicropubError.new("Micropub server returned an unspecified " +
          "error. Please check your server's logs for details.")
      end
      body
    end

    def validate_url!(url)
      unless Auth.valid_uri?(url)
        raise MicropubError.new("\"#{url}\" is not a valid URL.")
      end
    end

    def headers
      {
        'Authorization' => "Bearer #{@token}",
        'Content-Type' => 'application/json; charset=utf-8',
        'Accept' => 'application/json'
      }
    end

    def key(k)
      @micropub + '_' + k
    end

    def cache_get(k)
      return unless $redis
      data = $redis.get(key(k))
      return unless data
      JSON.parse(data)
    end

    def cache_set(k, v)
      return unless $redis
      json = v.to_json
      expiry_seconds = 60 * 60 * 24 # 1 day
      $redis.set(key(k), json, ex: expiry_seconds)
    end

    def cache_clear
      return unless $redis
      keys = $redis.keys("#{@micropub}*")
      $redis.del(*keys) unless keys.empty?
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
