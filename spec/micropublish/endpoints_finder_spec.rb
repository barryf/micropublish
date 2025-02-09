describe Micropublish::EndpointsFinder do

  LINKS = {
    micropub: 'https://api.barryfrost.com/micropub',
    authorization_endpoint: 'https://indieauth.com/auth',
    token_endpoint: 'https://tokens.indieauth.com/token'
  }

  before do
    stub_request(:get, 'https://example-metadata-body.com/').to_return(status: 200,
      body: '
        <link rel="indieauth-metadata" href="https://barryfrost.com/indieauth-metadata">
      ',
      headers: {}
    )
    stub_request(:get, 'https://example-metadata-headers.com/').to_return(status: 200,
      body: '',
      headers: {
        "Link" => '<https://barryfrost.com/indieauth-metadata>; rel="indieauth-metadata"'
      }
    )
    stub_request(:get, 'https://example-headers.com/').to_return(status: 200,
      body: '',
      headers: {
        "Link" => '<https://api.barryfrost.com/micropub>; rel="micropub", <https://indieauth.com/auth>; rel="authorization_endpoint", <https://tokens.indieauth.com/token>; rel="token_endpoint"'
      }
    )
    stub_request(:get, 'https://example-body.com/').to_return(status: 200,
      body: '
        <link rel="micropub" href="https://api.barryfrost.com/micropub">
        <link rel="authorization_endpoint" href="https://indieauth.com/auth">
        <link rel="token_endpoint" href="https://tokens.indieauth.com/token">
      ',
      headers: {}
    )
    stub_request(:get, 'https://barryfrost.com/indieauth-metadata').to_return(
      status: 200,
      body: {
        authorization_endpoint: 'https://indieauth.com/auth',
        token_endpoint: 'https://tokens.indieauth.com/token'
      }.to_json
    )
  end

  context "given a website url" do

    describe "#get_url" do
      it "should retrieve a successful response from a valid url" do
        url = 'https://example-body.com/'
        endpoints_finder = Micropublish::EndpointsFinder.new(url)
        response = endpoints_finder.get_url(url)
        expect(response.code.to_i).to eql(200)
      end
    end

    describe "#find_metadata_links" do
      it "should return authorization_endpoint and token_endpoint from metadata link in body)" do
        url = 'https://example-metadata-body.com/'
        indieauth_links = LINKS.dup
        indieauth_links.delete(:micropub)
        endpoints_finder = Micropublish::EndpointsFinder.new(url)
        response = endpoints_finder.get_url(url)
        endpoints_finder.find_metadata_links(response)
        expect(endpoints_finder.links).to eql(indieauth_links)
      end
      it "should return authorization_endpoint and token_endpoint from metadata link in headers" do
        url = 'https://example-metadata-headers.com/'
        indieauth_links = LINKS.dup
        indieauth_links.delete(:micropub)
        endpoints_finder = Micropublish::EndpointsFinder.new(url)
        response = endpoints_finder.get_url(url)
        endpoints_finder.find_metadata_links(response)
        expect(endpoints_finder.links).to eql(indieauth_links)
      end
    end

    describe "#find_header_links" do
      it "should return micropub, authorization_endpoint and token_endpoint from header" do
        url = 'https://example-headers.com/'
        endpoints_finder = Micropublish::EndpointsFinder.new(url)
        response = endpoints_finder.get_url(url)
        endpoints_finder.find_header_links(response)
        expect(endpoints_finder.links).to eql(LINKS)
      end
    end

    describe "#find_body_links" do
      it "should return micropub, authorization_endpoint and token_endpoint from body" do
        url = 'https://example-body.com/'
        endpoints_finder = Micropublish::EndpointsFinder.new(url)
        response = endpoints_finder.get_url(url)
        endpoints_finder.find_body_links(response)
        expect(endpoints_finder.links).to eql(LINKS)
      end
    end

    describe "#validate" do
      it "should ensure we have the three required endpoints" do
        url = 'https://example-body.com/'
        endpoints_finder = Micropublish::EndpointsFinder.new(url)
        endpoints_finder.find_links
        expect { endpoints_finder.validate! }.to_not raise_error
      end
    end

  end

end