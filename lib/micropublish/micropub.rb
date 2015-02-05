module Micropublish
  module Micropub
    module_function

    def post(url, params, token)
      body = Micropub.body_from_params(params)
      headers = { 'Authorization' => "Bearer #{token}" }
      response = HTTParty.post(url, :query => body, :headers => headers)
      puts "micropub response=#{response.inspect}"
      return if response.code != 201 # created
      return response.headers['location'] if response.headers.key?('location')
    end

    def body_from_params(params)
      entry = {}
      entry['h'] = 'entry'
      entry['category'] = params['category'].split(' ').join(',') unless params['category'].empty?
      %w(name content bookmark in_reply_to repost_of like_of syndicate_to).each do |field|
        entry[field.gsub('_','-')] = params[field] unless params[field].nil? || params[field].empty?
      end
      puts "entry=#{entry.inspect}"
      entry
    end

    def syndicate_to(url, token)
      headers = { 'Authorization' => "Bearer #{token}" }
      query = { q: 'syndicate-to' }
      response = HTTParty.get(url, :query => query, :headers => headers)
      puts "syndicate-to response=#{response.inspect}"
      return unless response.code == 200
      response_hash = CGI::parse(response.parsed_response)
      return unless response_hash.key?('syndicate-to')
      response_hash['syndicate-to'].first.split(',')
    end

    def syndication_label(syndication)
      return syndication unless Auth.valid_uri?(syndication)
      uri = URI.parse(syndication)
      uri.host.gsub('www.','').split('.').first.capitalize
    end

  end
end
