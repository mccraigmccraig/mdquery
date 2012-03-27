require File.expand_path('../../spec_helper', __FILE__)
require 'mdquery/dataset'

module MDQuery::Dataset

  describe DimensionSegment do

    def build
      @model = Object.new
      mock(@model).key{:foo_segment}

      @dimension = Object.new
      @source = Object.new
      mock(@dimension).dataset.mock!.model.mock!.source{@source}

      @values = [:foo, :bar, :baz]
      mock(@model).get_values(@source){@values}
      @labels = {:foo=>"foo", :bar=>"BAR", :baz=>"blah"}
      mock(@model).labels(@values){@labels}

      DimensionSegment.new(@model, @dimension)
    end

    it "should constract a DimensionSegment from a DimensionSegmentModel" do
      ds = build
      ds.dimension.should == @dimension
      ds.key.should == :foo_segment
      ds.dimension_values.map(&:dimension_segment).should == [ds, ds, ds]
      ds.dimension_values.map(&:value).should == [:foo, :bar, :baz]
      ds.dimension_values.map(&:label).should == ["foo", "BAR", "blah"]
      ds.values.should == [:foo, :bar, :baz]
    end

    describe "dimension_value_for" do
      it "should retrieve a DimensionValue from the segment by value" do
        ds = build
        dv0 = ds.dimension_value_for(:foo)
        dv0.dimension_segment.should == ds
        dv0.value.should == :foo
        dv0.label.should == "foo"
      end

      it "should retrieve a DimensionValue from the segment with the deref operator" do
        ds = build
        dv0 = ds[:foo]
        dv0.dimension_segment.should == ds
        dv0.value.should == :foo
        dv0.label.should == "foo"
      end
    end

    describe "label_for" do
      it "should get a label for a value from the segment" do
        ds = build
        ds.label_for(:foo).should == "foo"
        ds.label_for(:bar).should == "BAR"
      end
    end
  end

  describe Dimension do

    def build
      @model = Object.new
      mock(@model).key{:foodim}
      mock(@model).label{"Dimension Foo"}

      @sm0 = Object.new
      @segment0 = Object.new
      stub(@segment0).key{:segment0_key}
      stub(@segment0).values{[:foo, :bar]}
      @s0v0 = Object.new
      stub(@s0v0).label{"Foo"}
      stub(@s0v0).value{:foo}
      @s0v1 = Object.new
      mock(@s0v1).value{:bar}
      stub(@segment0).dimension_values{[@s0v0, @s0v1]}

      mock(DimensionSegment).new(@sm0, anything){@segment0}

      @sm1 = Object.new
      @segment1 = Object.new
      stub(@segment1).key{:segment1_key}
      stub(@segment1).values{[:baz, :waz]}
      @s1v0 = Object.new
      stub(@s1v0).value{:baz}
      @s1v1 = Object.new
      stub(@s1v1).value{:waz}
      stub(@s1v1).label{"WAZ"}
      stub(@segment1).dimension_values{[@s1v0, @s1v1]}

      mock(DimensionSegment).new(@sm1, anything){@segment1}

      mock(@model).segment_models{[@sm0,@sm1]}

      @dataset = Object.new

      Dimension.new(@model, @dataset)
    end

    it "should construct a Dimension from a DimensionModel" do
      d = build
      d.dataset.should == @dataset
      d.key.should == :foodim
      d.label.should == "Dimension Foo"
    end

    describe "segment" do
      it "should retrieve a segment by key" do
        d = build
        d.segment(:segment0_key).should == @segment0
        d.segment(:segment1_key).should == @segment1
      end

      it "should retrieve a segment by key with deref operator" do
        d = build
        d[:segment0_key].should == @segment0
        d[:segment1_key].should == @segment1
      end
    end

    describe "values_for_segments" do
      it "values_for_segment should extract values belonging to a segment" do
        d = build
        d.values_for_segments([:segment1_key, :segment0_key]).should == [:baz, :waz, :foo, :bar]
      end
    end

    describe "dimension_value_for" do
      it "should retrieve the DimensionValue for a segment value" do
        d = build
        d.dimension_value_for(:foo).should == @s0v0
        d.dimension_value_for(:waz).should == @s1v1
      end
    end

    describe "dimension_values_for_segments" do
      it "should extract DimensionValues belonging to a list of segments" do
        d = build
        d.dimension_values_for_segments(nil).should == [@s0v0, @s0v1, @s1v0, @s1v1]
        d.dimension_values_for_segments([:segment1_key]).should == [@s1v0, @s1v1]
        d.dimension_values_for_segments([:segment1_key, :segment0_key]).should == [@s1v0, @s1v1, @s0v0, @s0v1]
      end
    end

    describe "label_for" do
      it "should retrieve the label for a segment value" do
        d = build
        d.label_for(:foo).should == "Foo"
        d.label_for(:waz).should == "WAZ"
        d.label_for(:blah).should == nil
      end
    end
  end

  describe Measure do
    def build
      @dataset = Object.new
      @model = Object.new
      mock(@model).key{:count}
      mock(@model).definition{"count(*)"}

      Measure.new(@model, @dataset)
    end

    it "should construct a Measure from a MeasureModel" do
      m = build
      m.dataset.should == @dataset
      m.key.should == :count
      m.definition.should == "count(*)"
    end
  end

  describe Dataset do
    def build
      @data = [{:foo=>10, :bar=>10, :count=>100, :sum=>200}, {:foo=>5, :bar=>4, :count=>10, :sum=>20}]

      @model = Object.new

      @mm0 = Object.new
      @mm1 = Object.new
      stub(@model).measure_models{[@mm0, @mm1]}

      @m0 = Object.new
      stub(@m0).key{:count}
      @m1 = Object.new
      stub(@m1).key{:sum}
      mock(Measure).new(@mm0, anything){@m0}
      mock(Measure).new(@mm1, anything){@m1}

      @dm0 = Object.new
      @dm1 = Object.new
      stub(@model).dimension_models{[@dm0, @dm1]}

      @d0 = Object.new
      stub(@d0).key{:foo}
      @d1 = Object.new
      stub(@d1).key{:bar}

      mock(Dimension).new(@dm0, anything){@d0}
      mock(Dimension).new(@dm1, anything){@d1}

      Dataset.new(@model, @data)
    end

    it "should construct a Dataset from a DatasetModel" do
      ds = build
      ds.data.should == @data
      ds.dimensions.should == {:foo=>@d0, :bar=>@d1}
      ds.measures.should == {:count=>@m0, :sum=>@m1}
      ds.indexed_data.should == {{:foo=>10, :bar=>10}=>{:count=>100, :sum=>200}, {:foo=>5, :bar=>4}=>{:count=>10, :sum=>20}}
    end

    it "should index the dataset" do
      ds = build
      ds.indexed_data.should == {{:foo=>10, :bar=>10}=>{:count=>100, :sum=>200}, {:foo=>5, :bar=>4}=>{:count=>10, :sum=>20}}
    end

    it "should retrieve datapoints from the index" do
      ds = build
      ds.datapoint({:foo=>10, :bar=>10}, :count).should == 100
      ds.datapoint({:foo=>5, :bar=>4}, :sum).should == 20
    end
  end
end
