require File.expand_path('../../spec_helper', __FILE__)
require 'mdquery/dsl'

module MDQuery::DSL
  describe MDQuery::DSL do
    describe DimensionSegmentDSL do

      it "should create a DimensionSegmentModel for a fixed dimension-value" do
        dimension_model = Object.new

        dsl = DimensionSegmentDSL.new(:foo) do
          fix_dimension :blah
        end

        dsm = dsl.send(:build, dimension_model)

        dsm.dimension_model.should == dimension_model
        dsm.key.should == :foo
        dsm.fixed_dimension_value.should == :blah
      end

      it "should create a DimensionSegmentModel for an extracted dimension-value" do
        dimension_model = Object.new

        dsl = DimensionSegmentDSL.new(:foo) do
          extract_dimension "bar"
        end

        dsm = dsl.send(:build, dimension_model)
        dsm.dimension_model.should == dimension_model
        dsm.key.should == :foo
        dsm.extract_dimension_query.should == "bar"
      end
    end
  end
end
