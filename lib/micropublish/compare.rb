module Micropublish
  class Compare

    def initialize(existing, submitted, known)
      @existing = existing
      @submitted = submitted
      @known = known
      sanitize
    end

    def sanitize
      # remove unknown properties: these should be unchanged
      @existing.each { |k,v| @existing.delete(k) unless @known.include?(k) }

      # remove properties starting with _ or mp- (used internally)
      @submitted.each { |k,v| @submitted.delete(k) if k.start_with?('_','mp-') }
    end

    def diff_properties
      diff = {
        replace: {},
        add: {},
        delete: []
      }
      diff_removed!(diff)
      diff_added!(diff)
      diff_replaced!(diff)
      diff
    end

    def diff_removed!(diff)
      @existing.each do |prop,v|
        if !@submitted.key?(prop) || @submitted[prop].empty?
          diff[:delete] << prop
        end
      end
      diff.delete(:delete) if diff[:delete].empty?
    end

    def diff_added!(diff)
      @submitted.each do |prop,v|
        if !@existing.key?(prop)
          diff[:add][prop] = @submitted[prop].is_a?(Array) ? @submitted[prop] :
            [@submitted[prop]]
        end
      end
      diff.delete(:add) if diff[:add].empty?
    end

    def diff_replaced!(diff)
      @submitted.each do |prop,v|
        if @existing.key?(prop) && @existing[prop] != @submitted[prop]
          diff[:replace][prop] = @submitted[prop].is_a?(Array) ?
            @submitted[prop] : [@submitted[prop]]
        end
      end
      diff.delete(:replace) if diff[:replace].empty?
    end

  end
end