module MDQuery
  module Util

    # assigns instance variable attributes
    # to an object
    # * +obj+ - the instance
    # * +attrs+ - a map of {attr_name=>attr_value}
    module_function
    def assign_attributes(obj, attrs)
      attrs.each do |attr,val|
        obj.instance_variable_set("@#{attr}", val)
      end
    end

  end
end
