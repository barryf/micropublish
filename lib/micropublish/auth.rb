module Micropublish
  module Auth
    module_function

    def callback(me, code, state, redirect_uri, client_id)
      # check that me is a url
      unless valid_uri?(me)
        puts "Param 'me' must be a valid URI."
        return
      end

      # check that code is not blank
      if code.nil? || code.empty?
        puts "Param 'code' must not be blank."
        return
      end

      # find the micropub and token endpoints
      endpoints = find_endpoints(me)
      return if endpoints.nil?

      # confirm the auth with auth endpoint
      return unless confirm_auth?(me, code, state, redirect_uri, client_id,
                                  endpoints[:authorization_endpoint])

      # find out if we're allowed a token to post
      token = get_token(me, code, state, redirect_uri, client_id,
                        endpoints[:token_endpoint])
      return if token.nil?

      # return hash of endpoints and the token
      endpoints.merge(token: token)
    end

    def find_endpoints(me)
      response = HTTParty.get(me)

      if response.code == 200
        endpoints = {}

        # check http header for endpoints
        if response.headers.key?('Link')
          endpoints[:micropub_endpoint] = micropub_endpoint_from_header(response.headers['Link'])
        end

        # check html head for endpoints
        doc = Nokogiri::HTML(response.body)
        doc.css('link').each do |link|
          if link[:rel].downcase == 'micropub' && !link[:href].empty?
            endpoints[:micropub_endpoint] ||= link[:href]
          elsif link[:rel].downcase == 'token_endpoint' && !link[:href].empty?
            endpoints[:token_endpoint] ||= link[:href]
          elsif link[:rel].downcase == 'authorization_endpoint' &&
                !link[:href].empty?
            endpoints[:authorization_endpoint] ||= link[:href]
          end
        end
        %i(micropub_endpoint token_endpoint authorization_endpoint).each do |endpoint|
          unless endpoints.key?(endpoint)
            puts "Could not find #{e} at #{me}."
            return
          end
        end
        endpoints

      else
        puts "Bad response when finding endpoints: #{response.body}."
      end
    end

    def confirm_auth?(me, code, state, redirect_uri, client_id, authorization_endpoint)
      response = HTTParty.post(authorization_endpoint, body:
        {
          code: code,
          client_id: client_id,
          state: state,
          scope: 'post',
          redirect_uri: redirect_uri
        })
      if response.code == 200
        puts "callback=#{response.body}"
        response_hash = CGI.parse(response.parsed_response)
        if response_hash['me'].first == me
          true
        else
          puts "Couldn't match 'me' #{me} when confirming auth."
        end
      else
        puts "Bad response from request to auth endpoint: #{response.body}"
      end
    end

    def get_token(me, code, state, redirect_uri, client_id, token_endpoint)
      response = HTTParty.post(token_endpoint, body:
        {
          me: me,
          code: code,
          redirect_uri: redirect_uri,
          client_id: client_id,
          state: state,
          scope: 'post'
        })
      if response.code == 200
        response_hash = CGI.parse(response.parsed_response)
        puts "token response_hash=#{response_hash.inspect}"
        response_hash['access_token'].first
      else
        puts "Bad response from token endpoint: #{response.body}"
      end
    end

    def generate_state
      Random.new_seed.to_s
    end

    def valid_uri?(u)
      begin
        uri = URI.parse(u)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
      end
    end
    
    # adapted from 
    # https://github.com/indieweb/mention-client-ruby/blob/master/lib/webmention/client.rb#L143
    def micropub_endpoint_from_header(link)
      if matches = link.match(%r{<(https?://[^>]+)>; rel="micropub"})
        matches[1]
      elsif matches = link.match(%r{rel="micropub"; <(https?://[^>]+)>})
        matches[1]
      end
    end

  end
end
