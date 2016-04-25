module Micropublish
  module Micropub
    module_function

    def post(url, params, token)
      body = Micropub.body_from_params(params)
      headers = { 'Authorization' => "Bearer #{token}" }
      response = HTTParty.post(url, body: body, headers: headers)
      puts "micropub response=#{response.inspect}"
      return if response.code != 201 # created
      return response.headers['location'] if response.headers.key?('location')
    end

    def body_from_params(params)
      entry = { 'h' => 'entry' }
      unless params['category'].empty?
        entry['category'] = params['category'].split(' ').join(',')
      end
      unless !params.key?('syndicate_to') || params['syndicate_to'].empty?
        entry['syndicate-to'] = params['syndicate_to'].split(',')
      end
      text_fields.each do |field|
        unless params[field].nil? || params[field].empty?
          entry[field.gsub('_', '-')] = params[field]
        end
      end
      puts "entry=#{entry.inspect}"
      entry
    end

    def syndicate_to(url, token)
      headers = { 
        'Authorization' => "Bearer #{token}", 
        'Content-Type' => 'application/json',
        'Accept' => 'application/json' 
      }
      query = { q: 'syndicate-to' }
      response = HTTParty.get(url, query: query, headers: headers)
      puts "syndicate-to response=#{response.inspect}"
      return unless response.code == 200
      # allow for (preferred) JSON, old-style CSV string or array
      begin
        json = JSON.parse(response.body)
        return json['syndicate-to']
      rescue JSON::ParserError
        # this approach is deprecated and will be removed 
        response_hash = CGI.parse(response.parsed_response)
        if response_hash.key?('syndicate-to')
          syndications_array = response_hash['syndicate-to'].first.split(',')
          return syndications_array.map { |s| { "uid" => s, "name" => Micropub.syndication_label(s)} }
        elsif response_hash.key?('syndicate-to[]')
          syndications_array = response_hash['syndicate-to[]']
          return syndications_array.map { |s| { "uid" => s, "name" => Micropub.syndication_label(s)} }
        end
      end
    end

    def syndication_label(syndication)
      return syndication unless Auth.valid_uri?(syndication)
      uri = URI.parse(syndication)
      uri.host.gsub('www.', '').split('.').first.capitalize
    end

    def text_fields
      %w(name content summary bookmark in_reply_to repost_of like_of)
    end

    def reply_username(url)
      if url.start_with?('https://twitter.com') ||
          url.start_with?('https://mobile.twitter.com')
        url.split('/')[3]
      end
    end

    def post_types
      {
        note:     { label: 'Note', icon: 'comment', fields: %i(content) },
        article:  { label: 'Article', icon: 'file-text',
                    fields: %i(name content) },
        bookmark: { label: 'Bookmark', icon: 'bookmark',
                    fields: %i(bookmark name content) },
        reply:    { label: 'Reply', icon: 'reply',
                    fields: %i(in_reply_to content) },
        repost:   { label: 'Repost', icon: 'retweet', fields: %i(repost_of content) },
        like:     { label: 'Like', icon: 'heart', fields: %i(like_of) }
      }
    end

  end
end
