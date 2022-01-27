module Micropublish
  class Request

    def initialize(micropub, token, is_json=false)
      @micropub = micropub
      @token = token
      @is_json = is_json
    end

    def create(post)
      body = if @is_json
          { type: post.type, properties: post.properties }
        else
          # flatten single value arrays
          { h: post.h_type }.merge(
            Hash[post.properties.map { |k,v| [k, v.size == 1 ? v[0] : v] }]
          )
        end
      response = send(body)
      case response.code.to_i
      when 201, 202
        response.headers['location']
      else
        handle_error(response.body)
      end
    end

    def update(url, diff, mp_commands)
      body = { action: 'update', url: url }.merge(diff).merge(mp_commands)
      response = send(body, true)
      case response.code.to_i
      when 201
        response.headers['location']
      when 200, 204
        url
      else
        handle_error(response.body)
      end
    end

    def delete(url)
      body = { action: 'delete', url: url }
      response = send(body)
      case response.code.to_i
      when 200, 204
        url
      else
        handle_error(response.body)
      end
    end

    def undelete(url)
      body = { action: 'undelete', url: url }
      response = send(body)
      case response.code.to_i
      when 201
        response.headers['location']
      when 200, 204
        url
      else
        handle_error(response.body)
      end
    end

    def upload(file)
      response = HTTParty.post(
        @micropub,
        body: {
          file: file
        },
        headers: { 'Authorization' => "Bearer #{@token}" }
      )

      case response.code.to_i
      when 201
        response.headers['location']
      else
        handle_error(response.body)
      end
    end

    private

    def send(body, is_json=@is_json)
      headers = { 'Authorization' => "Bearer #{@token}" }
      if is_json
        body = body.to_json
        headers['Content-Type'] = 'application/json; charset=utf-8'
      end
      HTTParty.post(
        @micropub,
        body: body,
        headers: headers
      )
    end

    def handle_error(response_body)
      raise MicropublishError.new('request',
        "There was an error making a request to your Micropub endpoint. " +
        "The error received was: #{response_body}")
    end

  end
end