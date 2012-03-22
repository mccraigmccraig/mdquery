module MDQuery
  module Util

    module_function
    def assign_attributes(obj, attrs)
      attrs.each do |attr,val|
        obj.instance_variable_set("@#{attr}", val)
      end
    end

  end
end
