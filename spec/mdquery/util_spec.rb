require File.expand_path('../../spec_helper', __FILE__)
require 'mdquery/util'

describe MDQuery::Util do
  describe "assign_attributes" do
    it "should assign attributes" do
      attrs = {:foo=>100, :bar=>"hi"}
      instance = Object.new

      mock(instance).instance_variable_set("@foo",100)
      mock(instance).instance_variable_set("@bar", "hi")

      MDQuery::Util.assign_attributes(instance, attrs)
    end
  end
end
