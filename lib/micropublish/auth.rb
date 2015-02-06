module Micropublish
  module Auth
    module_function

    def callback(me, code, state, redirect_uri)
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
      return unless confirm_auth?(me, code, state, redirect_uri,
                                  endpoints[:authorization_endpoint])

      # find out if we're allowed a token to post
      token = get_token(me, code, state, redirect_uri,
                        endpoints[:token_endpoint])
      return if token.nil?

      # return hash of endpoints and the token
      endpoints.merge(token: token)
    end

    def find_endpoints(me)
      response = HTTParty.get(me)

      if response.code == 200
        endpoints = {}

        # TODO: check http header for endpoints
        #

        # check html head for endpoints
        doc = Nokogiri::HTML(response.body)
        doc.css('link').each do |link|
          if link[:rel].downcase == 'micropub' && !link[:href].empty?
            endpoints[:micropub_endpoint] = link[:href]
          elsif link[:rel].downcase == 'token_endpoint' && !link[:href].empty?
            endpoints[:token_endpoint] = link[:href]
          elsif link[:rel].downcase == 'authorization_endpoint' &&
                !link[:href].empty?
            endpoints[:authorization_endpoint] = link[:href]
          end
        end
        %w(micropub_endpoint token_endpoint authorization_endpoint).each do |e|
          unless endpoints.key?(e.to_sym)
            puts "Could not find #{e} at #{me}."
            return
          end
        end
        endpoints

      else
        puts "Bad response when finding endpoints: #{response.body}."
      end
    end

    def confirm_auth?(me, code, state, redirect_uri, authorization_endpoint)
      response = HTTParty.post(authorization_endpoint, query:
        {
          code: code,
          client_id: 'Micropublish',
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

    def get_token(me, code, state, redirect_uri, token_endpoint)
      response = HTTParty.post(token_endpoint, query:
        {
          me: me,
          code: code,
          redirect_uri: redirect_uri,
          client_id: 'Micropublish',
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
  end
end
