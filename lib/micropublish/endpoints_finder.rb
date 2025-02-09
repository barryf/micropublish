module Micropublish
  class EndpointsFinder

    RELS = %w( micropub authorization_endpoint token_endpoint )

    attr_reader :links

    def initialize(url)
      @url = url
      @links = {}
    end

    def get_url(url)
      begin
        response = HTTParty.get(url)
      rescue SocketError => e
        raise AuthError.new("Client could not connect to \"#{url}\".")
      end
      unless (200...300).include?(response.code)
        raise AuthError.new("#{response.code} status returned from \"#{url}\".")
      end
      response
    end

    def find_links
      response = get_url(@url)
      find_metadata_links(response)
      find_header_links(response)
      find_body_links(response)
      @links unless @links.empty?
    end

    def find_metadata_url(response)
      header_links = LinkHeader.parse(response.headers['Link'])
      link = header_links.find_link(['rel', 'indieauth-metadata'])
      if link.respond_to?('href') && !link.href.nil? && !link.href.empty?
        return URI.join(@url, link.href).to_s
      end
      html_links = Nokogiri::HTML(response.body).css('link')
      html_links.each do |link|
        if link[:rel] == 'indieauth-metadata' && !link[:href].empty?
          return URI.join(@url, link[:href]).to_s
        end
      end
      return
    end

    def find_metadata_links(doc_response)
      return unless metadata_url = find_metadata_url(doc_response)
      metadata_response = get_url(metadata_url)
      begin
        body = JSON.parse(metadata_response.body)
      rescue JSON::ParserError
        raise AuthError.new("Could not parse server metadata JSON at #{metadata_url}.")
      end
      RELS.each do |rel|
        if body.key?(rel) && !body[rel].nil? && !body[rel].empty? && !@links.key?(rel.to_sym)
          absolute_url = URI.join(@url, body[rel]).to_s
          @links[rel.to_sym] = absolute_url
        end
      end
    end

    def find_header_links(response)
      links = LinkHeader.parse(response.headers['Link'])
      RELS.each do |rel|
        link = links.find_link(['rel', rel])
        if link.respond_to?('href') && !link.href.nil? && !link.href.empty? && !@links.key?(rel.to_sym)
          absolute_url = URI.join(@url, link.href).to_s
          @links[rel.to_sym] = absolute_url
        end
      end
    end

    def find_body_links(response)
      links = Nokogiri::HTML(response.body).css('link')
      links.each do |link|
        if RELS.include?(link[:rel]) && !@links.key?(link[:rel].to_sym) &&
            !link[:href].nil? && !link[:href].empty?
          absolute_url = URI.join(@url, link[:href]).to_s
          @links[link[:rel].to_sym] = absolute_url
        end
      end
    end

    def validate!
      RELS.each do |link|
        unless @links.key?(link.to_sym)
          raise AuthError.new(
            "Client could not find \"#{link}\" in server metadata, headers or body from \"#{@url}\".")
        end
      end
    end

  end
end