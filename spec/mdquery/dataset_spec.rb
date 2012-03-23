require File.expand_path('../../spec_helper', __FILE__)
require 'mdquery/dataset'

module MDQuery::Dataset
  describe Dimension do
    it "label_for should lookup labels for values" do
      d = Dimension.new(:key=>:foo, :label=>:foo_label,
                        :values=>[DimensionValue.new(:segment_key=>:bar, :value=>:barbar, :label=>"BARBAR"),
                         DimensionValue.new(:segment_key=>:bar, :value=>:barbarbar, :label=>"BARBARBAR"),
                         DimensionValue.new(:segment_key=>:baz, :value=>:bazbaz, :label=>"BAZBAZ")])

      d.label_for(:barbar).should == "BARBAR"
      d.label_for(:barbarbar).should == "BARBARBAR"
      d.label_for(:bazbaz).should == "BAZBAZ"
    end

    it "values_for_segment should extract values belonging to a segment" do
      vs = [DimensionValue.new(:segment_key=>:bar, :value=>:barbar, :label=>"BARBAR"),
            DimensionValue.new(:segment_key=>:bar, :value=>:barbarbar, :label=>"BARBARBAR"),
            DimensionValue.new(:segment_key=>:baz, :value=>:bazbaz, :label=>"BAZBAZ")]

      d = Dimension.new(:key=>:foo, :label=>:foo_label, :values=>vs)
      d.values_for_segment(:bar).should == vs[0..1]
    end

    it "values_for_segments should extract values for given segments in given order" do
      vs = [DimensionValue.new(:segment_key=>:bar, :value=>:barbar, :label=>"BARBAR"),
            DimensionValue.new(:segment_key=>:bar, :value=>:barbarbar, :label=>"BARBARBAR"),
            DimensionValue.new(:segment_key=>:baz, :value=>:bazbaz, :label=>"BAZBAZ"),
            DimensionValue.new(:segment_key=>:foo, :value=>:foofoo, :label=>"FOOFOO"),
            DimensionValue.new(:segment_key=>:foo, :value=>:foofoofoo, :label=>"FOOFOOFOO")]

      d = Dimension.new(:key=>:woot, :label=>:woot_label, :values=>vs)
      d.values_for_segments([:foo, :bar]).should == vs[3..4] + vs[0..1]

    end
  end

  describe Dataset do
    it "should index the dataset" do
      model = Object.new
      foo_dim = Object.new
      bar_dim = Object.new
      dimensions = {:foo=>foo_dim, :bar=>bar_dim}
      count_measure = Object.new

      ds = Dataset.new(:model => model,
                       :dimensions => dimensions,
                       :measures => [count_measure],
                       :data => [{:foo=>10, :bar=>10, :count=>100}, {:foo=>5, :bar=>4, :count=>10}])

      ds.model.should == model
      ds.dimensions.should == dimensions
      ds.measures.should == [count_measure]

      ds.indexed_data.should == {{:foo=>10, :bar=>10}=>{:count=>100}, {:foo=>5, :bar=>4}=>{:count=>10}}
    end

    it "should retrieve datapoints from the index" do
      ds = Dataset.new(:model => Object.new,
                       :dimensions => {:foo=>Object.new, :bar=>Object.new},
                       :measures => [Object.new],
                       :data => [{:foo=>10, :bar=>10, :count=>100}, {:foo=>5, :bar=>4, :count=>10}])

      ds.datapoint({:foo=>10, :bar=>10}, :count).should == 100
      ds.datapoint({:foo=>5, :bar=>4}, :count).should == 10
    end
  end
end
