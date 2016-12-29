module Micropublish
  class Auth

    def initialize(me, code, state, redirect_uri, client_id)
      @me = me
      @code = code
      @state = state
      @redirect_uri = redirect_uri
      @client_id = client_id
    end

    def callback
      # validate the parameters
      unless Auth.valid_uri?(@me)
        raise AuthError.new(
          "The \"me\" parameter must be a valid URL: \"#{@me}\".")
      end
      if @code.nil? || @code.empty?
        raise AuthError.new("The \"code\" parameter must not be blank.")
      end

      # find micropub and token endpoints
      endpoints_finder = EndpointsFinder.new(@me)
      endpoints = endpoints_finder.find_links

      # check we've found all the endpoints we want
      endpoints_finder.validate!

      # find out if we're allowed a token to post
      token = get_token(endpoints[:token_endpoint])
      if token.nil? || token.empty?
        raise AuthError.new("No token was returned from the token endpoint.")
      end

      # return hash of endpoints and the token
      endpoints.merge(token: token)
    end

    def get_token(token_endpoint)
      response = HTTParty.post(token_endpoint, body: {
        me: @me,
        code: @code,
        redirect_uri: @redirect_uri,
        client_id: @client_id,
        state: @state,
        scope: 'create update delete undelete'
      })
      if (200...300).include?(response.code)
        response_hash = CGI.parse(response.parsed_response)
        if response_hash.nil? || !response_hash.key?('access_token')
          raise AuthError.new("No access_token returned from token endpoint.")
        end
        response_hash['access_token'].first
      else
        raise AuthError.new("#{response.code} received from token endpoint.")
      end
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