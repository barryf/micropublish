module Micropublish
  class Micropub
    attr_reader :token

    def initialize(micropub, token)
      @micropub = micropub
      @token = token
    end

    def config
      query('config', { q: 'config' })
    end

    def channels
      data = query('channel', { q: 'channel' }) || config
      data['channels'] if data.is_a?(Hash) && data.key?('channels')
    end

    def syndicate_to(subtype = nil)
      params = { q: 'syndicate-to' }
      params['post-type'] = subtype if subtype
      data = query(params.to_s, params) || config
      data['syndicate-to'] if data.is_a?(Hash) && data.key?('syndicate-to')
    end

    def media_endpoint
      config['media-endpoint'] if config
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
        body['properties'] = convert_content_images_to_trix(body['properties'])
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

    def convert_content_images_to_trix(properties)
      return properties unless properties.has_key?("content") && properties["content"]&.first["html"]

      doc = Nokogiri::HTML5.fragment(properties["content"]&.first["html"])

      doc.css('img').each do |image|
        image_src = image['src']
        image_alt = image['alt']

        attachment = CGI.escapeHTML({
          "contentType": "image",
          "href": "#{image_src}?content-disposition=attachment",
          "url": image_src
        }.to_json)

        attributes = CGI.escapeHTML({
          caption: image_alt,
          presentation: "gallery"
        }.to_json)

        figure = %Q(
          <figure
            data-trix-attachment=\"#{attachment}\"
            data-trix-attributes=\"#{attributes}\"
            class=\"attachment attachment--preview\"><img
              src=\"#{image_src}\">
            <figcaption class=\"attachment__caption attachment__caption--edited\">#{image_alt}</figcaption>
          </figure>
        )

        image.replace(figure)
      end

      properties["content"]&.first["html"] = doc.to_html
      properties
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

    def query(suffix, params)
      key = @micropub + '_' + suffix
      data = cache_get(key)
      unless data
        data = begin
                 response = HTTParty.get(
                   @micropub,
                   query: params,
                   headers: headers
                 )
                 JSON.parse(response.body)
               rescue
               end
        cache_set(key, data)
      end
      data
    end

    def cache_get(key)
      return unless $redis
      data = $redis.get(key)
      return unless data
      JSON.parse(data)
    end

    def cache_set(key, value)
      return unless $redis
      json = value.to_json
      expiry_seconds = 60 * 60 * 24 # 1 day
      $redis.set(key, json, ex: expiry_seconds)
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
