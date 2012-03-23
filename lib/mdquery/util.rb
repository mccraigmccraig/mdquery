require 'set'

module MDQuery
  module Util

    # assigns instance variable attributes
    # to an object
    # * +obj+ - the instance
    # * +attrs+ - a map of {attr_name=>attr_value}
    module_function
    def assign_attributes(obj, attrs, permitted_keys = nil)
      unknown_keys = attrs.keys.map(&:to_s).to_set - permitted_keys.map(&:to_s).to_set if permitted_keys
      raise "unknown keys: #{unknown_keys.to_a.inspect}. permitted keys are: #{permitted_keys.inspect}" if unknown_keys && !unknown_keys.empty?

      attrs.each do |attr,val|
        obj.instance_variable_set("@#{attr}", val)
      end
    end

  end
end
