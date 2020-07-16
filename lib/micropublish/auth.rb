require 'cgi'

module Micropublish
  class Auth

    def initialize(me, code, state, scope, redirect_uri, client_id)
      @me = me
      @code = code
      @state = state
      @scope = scope
      @redirect_uri = redirect_uri
      @client_id = client_id
    end

    def callback
      # validate the parameters
      unless Auth.valid_uri?(@me)
        raise AuthError.new(
          "Missing or invalid value for \"me\": \"#{@me}\".")
      end
      if @code.nil? || @code.empty?
        raise AuthError.new("The \"code\" parameter must not be blank.")
      end

      # find micropub and token endpoints
      endpoints_finder = EndpointsFinder.new(@me)
      endpoints = endpoints_finder.find_links

      # check we've found all the endpoints we want
      endpoints_finder.validate!

      # find out if we're allowed a token to post and what "me" to use
      token, me = get_token_and_me(endpoints[:token_endpoint])

      # return hash of endpoints and the token with the "me"
      endpoints.merge(token: token, me: me)
    end

    def get_token_and_me(token_endpoint)
      response = HTTParty.post(token_endpoint, body: {
        me: @me,
        code: @code,
        redirect_uri: @redirect_uri,
        client_id: @client_id,
        state: @state,
        scope: @scope,
        grant_type: 'authorization_code'
      })
      unless (200...300).include?(response.code)
        raise AuthError.new("#{response.code} received from token endpoint.")
      end
      # try json first
      begin
        response_hash = JSON.parse(response.body)
        access_token = response_hash.key?('access_token') ?
          response_hash['access_token'] : nil
        me = response_hash.key?('me') ? response_hash['me'] : nil
      rescue JSON::ParserError => e
        # assume form-encoded
        response_hash = CGI.parse(response.parsed_response)
        access_token = response_hash.key?('access_token') ?
          response_hash['access_token'].first : nil
        me = response_hash.key?('me') ? response_hash['me'].first : nil
      end
      unless access_token
        raise AuthError.new("No 'access_token' returned from token endpoint.")
      end
      unless me
        raise AuthError.new("No 'me' param returned from token endpoint.")
      end
      [access_token, me]
    end

    def self.valid_uri?(u)
      begin
        uri = URI.parse(u)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
      end
    end

  end

  class AuthError < MicropublishError
    def initialize(message)
      super("auth", message)
    end
  end

end