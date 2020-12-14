describe Micropublish::Auth do

  before do
    # from https://tools.ietf.org/html/rfc7636#appendix-A
    @code_verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
    @expected_code_challenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
  end

  context "given a random string as a code verifier" do
    describe "#generate_code_challenge" do
      it "should generate a code challenge in the expected format" do
        code_challenge = Micropublish::Auth.generate_code_challenge(@code_verifier)
        expect(code_challenge).to eql(@expected_code_challenge)
      end
    end
  end

end