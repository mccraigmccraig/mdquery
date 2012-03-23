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

    it "should raise an exception if an unknown attribute is passed" do
      attrs = {:foo=>100, :bar=>"hi"}
      instance = Object.new

      lambda {
        MDQuery::Util.assign_attributes(instance, attrs, [:foo])
      }.should raise_error(/unknown keys: \["bar"\]/)
    end
  end
end
