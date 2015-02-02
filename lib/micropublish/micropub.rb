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
      %w(name content bookmark in_reply_to repost_of like_of).each do |field|
        entry[field.gsub('_','-')] = params[field] unless params[field].nil? || params[field].empty?
      end
      puts "entry=#{entry.inspect}"
      entry
    end
  
  end
end