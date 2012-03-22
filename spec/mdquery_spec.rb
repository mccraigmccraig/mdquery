require File.expand_path('../spec_helper', __FILE__)
require 'mdquery'

describe "MDQuery" do
  it "should use the DSL to define a Dataset" do
    source_scope = Object.new

    ds = MDQuery.dataset do
      source source_scope

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

    ds.source_scope.should == source_scope
    ds.dimension_models.count.should == 2
    ds.dimension_models[0].key.should == :foo
    ds.dimension_models[1].key.should == :bar
    ds.measure_models.count.should == 2
    ds.measure_models[0].key.should == :count
    ds.measure_models[1].key.should == :avg
  end
end
