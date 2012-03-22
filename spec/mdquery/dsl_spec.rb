require File.expand_path('../../spec_helper', __FILE__)
require 'mdquery/dsl'

module MDQuery::DSL
  describe MDQuery::DSL do
    describe DimensionSegmentDSL do

      it "should create a DimensionSegmentModel for a fixed dimension-value" do
        dimension_model = Object.new
        narrow_proc = lambda{}
        values_proc = lambda{}
        label_proc = lambda{}
        modify_count_proc = lambda{}

        dsl = DimensionSegmentDSL.new(:foo) do
          fix_dimension :blah
          narrow(&narrow_proc)
          values(&values_proc)
          label(&label_proc)
          cast :sym
          modify :count, &modify_count_proc
        end

        dsm = dsl.send(:build, dimension_model)

        dsm.dimension_model.should == dimension_model
        dsm.key.should == :foo
        dsm.fixed_dimension_value.should == :blah
        dsm.narrow_proc.should == narrow_proc
        dsm.values_proc.should == values_proc
        dsm.label_proc.should == label_proc
        dsm.measure_modifiers.should == {:count=>modify_count_proc}
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

    describe DimensionDSL do
    end
  end
end
