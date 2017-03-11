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
      diff_replaced!(diff)
      diff_added!(diff)
      diff_removed!(diff)
      diff.delete(:replace) if diff[:replace].empty?
      diff.delete(:add) if diff[:add].empty?
      diff.delete(:delete) if diff[:delete].empty?
      diff
    end

    def diff_removed!(diff)
      @existing.each do |prop,v|
        if !@submitted.key?(prop) || @submitted[prop].empty?
          diff[:delete] = [] unless diff[:delete].is_a?(Array)
          diff[:delete] << prop
        elsif !(@existing[prop].size == 1 && @submitted[prop].size == 1)
          d = @existing[prop] - @submitted[prop]
          unless d.empty?
            diff[:delete] = {} unless diff[:delete].is_a?(Hash)
            diff[:delete][prop] = d
          end
        end
      end
    end

    def diff_added!(diff)
      @submitted.each do |prop,v|
        if !@existing.key?(prop)
          diff[:add][prop] = @submitted[prop]
        elsif !(@existing[prop].size == 1 && @submitted[prop].size == 1)
          a = @submitted[prop] - @existing[prop]
          unless a.empty?
            diff[:add][prop] = a
          end
        end
      end
    end

    def diff_replaced!(diff)
      @submitted.each do |prop,v|
        if @existing.key?(prop) && @existing[prop] != @submitted[prop] &&
            @existing[prop].size == 1 && @submitted[prop].size == 1
          diff[:replace][prop] = @submitted[prop]
        end
      end
    end

  end
end