describe Micropublish::EndpointsFinder do

  URL = 'https://barryfrost.com'
  LINKS = {
    micropub: 'https://barryfrost.com/micropub',
    authorization_endpoint: 'https://indieauth.com/auth',
    token_endpoint: 'https://tokens.indieauth.com/token'
  }

  before do
    @endpoints_finder = Micropublish::EndpointsFinder.new(URL)
    @response = @endpoints_finder.get_url
  end

  context "given a website url" do

    describe "#get_url" do
      it "should retrieve a successful response from a valid url." do
        expect(@response.code.to_i).to eql(200)
      end
    end

    describe "#find_header_links" do
      it "should return micropub, authorization_endpoint and token_endpoint from header." do
        @endpoints_finder.find_header_links(@response)
        links = @endpoints_finder.links
        expect(links).to eql(LINKS)
      end
    end

    describe "#find_body_links" do
      it "should return micropub, authorization_endpoint and token_endpoint from body." do
        @endpoints_finder.find_body_links(@response)
        links = @endpoints_finder.links
        expect(links).to eql(LINKS)
      end
    end

    describe "#validate" do
      it "should ensure we have the three required endpoints." do
        @endpoints_finder.find_header_links(@response)
        expect { @endpoints_finder.validate! }.to_not raise_error
      end
    end

  end

end