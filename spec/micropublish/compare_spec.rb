describe Micropublish::Compare do

  before do
    @compare = Micropublish::Compare.new(
      {
        'content' => ['Existing content.'],
        'category' => ['indieweb','micropub']
      },
      {
        'content' => ['New content.'],
        'name' => ['New name.'],
        'category' => ['indieweb','new']
      },
      [
        "in-reply-to",
        "repost-of",
        "like-of",
        "bookmark-of",
        "rsvp",
        "name",
        "content",
        "summary",
        "published",
        "category",
        "mp-syndicate-to",
        "syndication",
        "mp-slug"
    	]
    )
  end

  context "given existing and submitted hashes containing properties" do

    describe "#diff_removed!" do
      it "should show that properties have been removed." do
        diff = { replace: {}, add: {}, delete: {} }
        @compare.diff_removed!(diff)
        expect(diff[:delete]).to eql({ 'category' => ['micropub'] })
      end
    end

    describe "#diff_added!" do
      it "should show that properties have been added." do
        diff = { add: {} }
        @compare.diff_added!(diff)
        expect(diff[:add]).to eql({
          'name' => ['New name.'],
          'category' => ['new']
        })
      end
    end

    describe "#diff_replaced!" do
      it "should show that properties have been replaced." do
        diff = { replace: {}, add: {}, delete: {} }
        @compare.diff_replaced!(diff)
        expect(diff[:replace]).to eql({ 'content' => ['New content.'] })
      end
    end

    describe "#diff_properties" do
      it "should combine diffs from each of the three methods." do
        diff = @compare.diff_properties
        expect(diff).to eql({
          delete: { 'category' => ['micropub'] },
          add: { 'name' => ['New name.'], 'category' => ['new'] },
          replace: { 'content' => ['New content.'] }
        })
      end
    end

  end

end