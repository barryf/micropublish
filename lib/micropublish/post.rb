module Micropublish
  class Post

    attr_reader :type, :properties

    def initialize(type, properties)
      @type = type
      @properties = properties
    end

    def self.properties_from_params(params)
      props = {}
      params.keys.each do |param|
        next if params[param].empty? || params[param] == [""]
        if param.start_with?('_')
          next
        elsif param == 'mp-syndicate-to'
          props[param] = params[param]
        elsif param == 'category'
          props['category'] = params['category'].is_a?(Array) ?
            params['category'] : params['category'].split(/,\s?/)
        elsif param == 'content'
          props['content'] = Array(params[param])
        else
          props[param] = if params[param].is_a?(Array)
              params[param][0].split(/\s+/)
            else
              Array(params[param])
            end
        end
      end
      props
    end

    def validate_properties!(required=[])
      # ensure url arrays only contain urls
      %w( in-reply-to repost-of like-of bookmark-of syndication ).each do
          |url_property|
        if @properties.key?(url_property)
          @properties[url_property].each do |url|
            unless Auth.valid_uri?(url)
              raise MicropublishError.new('post',
                "\"#{url}\" is not a valid URL. <code>#{url_property}</code> " +
                "accepts only one or more URLs separated by whitespace.")
            end
          end
        end
      end
      # check all required properties have been provided
      required.each do |property|
        next if property == 'content-html'
        unless @properties.key?(property)
          raise MicropublishError.new('post',
            "<code>#{property}</code> is required for the form to be " +
            "submitted. Please enter a value for this property.")
        end
      end
    end

    def h_type
      @type[0].gsub(/^h\-/,'')
    end

    def to_form_encoded
      puts "props=#{@properties}"
      props = Hash[@properties.map { |k,v| v.size > 1 ? ["#{k}[]", v] : [k,v] }]
      query = { h: h_type }.merge(props)
      URI.encode_www_form(query)
    end

    def to_json(pretty=false)
      hash = { type: @type, properties: @properties }
      pretty ? JSON.pretty_generate(hash) : hash.to_json
    end

    def diff_properties(submitted)
      diff = {
        replace: {},
        add: {},
        delete: []
      }
      diff_removed!(diff, submitted)
      diff_added!(diff, submitted)
      diff_replaced!(diff, submitted)
      diff
    end

    def diff_removed!(diff, submitted)
      @properties.keys.each do |prop|
        if !submitted.key?(prop) || submitted[prop].empty?
          diff[:delete] << prop
        end
      end
      diff.delete(:delete) if diff[:delete].empty?
    end

    def diff_added!(diff, submitted)
      submitted.keys.each do |prop|
        if !@properties.key?(prop)
          diff[:add][prop] = submitted[prop].is_a?(Array) ? submitted[prop] :
            [submitted[prop]]
        end
      end
      diff.delete(:add) if diff[:add].empty?
    end

    def diff_replaced!(diff, submitted)
      submitted.keys.each do |prop|
        if @properties.key?(prop) && @properties[prop] != submitted[prop]
          diff[:replace][prop] = submitted[prop].is_a?(Array) ? submitted[prop] :
            [submitted[prop]]
        end
      end
      diff.delete(:replace) if diff[:replace].empty?
    end

  end
end