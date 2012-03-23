require File.expand_path('../../spec_helper', __FILE__)
require 'mdquery/dsl'

module MDQuery::DSL
  describe MDQuery::DSL do
    describe DimensionSegmentDSL do

      it "should build a DimensionSegmentModel for a fixed dimension-value" do
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

      it "should build a DimensionSegmentModel for an extracted dimension-value" do
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

      it "should build a DimensionModel with a single segment" do
        dsl = DimensionDSL.new(:foo) do
          label :blah

          segment(:bar) do
            fix_dimension :woot
          end
        end

        dm = dsl.send(:build)
        dm.key.should == :foo
        dm.label.should == :blah
        dm.segment_models.count.should == 1
        dm.segment_models.first.key.should == :bar
      end

      it "should build a DimensionModel with a list of segments" do
        dsl = DimensionDSL.new(:foo) do

          segment(:bar) do
            fix_dimension :woot
          end

          segment(:baz) do
            fix_dimension :bloop
          end
        end

        dm = dsl.send(:build)
        dm.key.should == :foo
        dm.segment_models.count.should == 2
        dm.segment_models[0].key.should == :bar
        dm.segment_models[1].key.should == :baz
      end
    end

    describe MeasureDSL do

      it "should build a MeasureModel without cast" do
        dsl = MeasureDSL.new(:foo, "count(*)")
        mm = dsl.send(:build)
        mm.key.should == :foo
        mm.definition.should == "count(*)"
      end

      it "should build a MeasureModel with cast" do
        dsl = MeasureDSL.new(:foo, "count(*)", :sym)
        mm = dsl.send(:build)
        mm.key.should == :foo
        mm.definition.should == "count(*)"
        mm.cast.should == :sym
      end

    end

    describe DatasetDSL do

      it "should build a DatasetModel with multiple dimensions and measures" do
        source = Object.new

        dsl = DatasetDSL.new do
          source source

          dimension :foo do
            segment :foo_a do
              fix_dimension :foo_a_value
            end
          end

          dimension :bar do
            segment :bar_a do
              fix_dimension :bar_a_value
            end
          end

          measure :count, "count(*)"
          measure :avg, "avg(foo)"
        end

        ds = dsl.send(:build)
        ds.source.should == source
        ds.dimension_models.count.should == 2
        ds.dimension_models[0].key.should == :foo
        ds.dimension_models[1].key.should == :bar
        ds.measure_models.count.should == 2
        ds.measure_models[0].key.should == :count
        ds.measure_models[1].key.should == :avg
      end

    end
  end
end
