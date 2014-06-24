require File.expand_path('../../spec_helper', __FILE__)
require 'mdquery/model'
require 'set'

module MDQuery
  module Model
    describe CASTS do
      it "sym cast should cast a string to a symbol" do
        CASTS[:sym].call("blah").should == :blah
      end
      it "int cast should cast a string to a symbol" do
        cv = CASTS[:int].call("100")
        cv.should == 100
        cv.class.should == 100.class
      end
      it "float cast should cast a string to a float" do
        cv = CASTS[:float].call("3.5")
        cv.should == 3.5
        cv.class.should == 3.5.class
      end
      it "date cast should cast a string to a date" do
        cv = CASTS[:date].call("2011-03-25")
        cv.should == Date.parse("2011-03-25")
        cv.class.should == Date
      end
      it "datetime cast should cast a string to a datetime" do
        cv = CASTS[:datetime].call("2011-03-25 08:47:23")
        cv.should == DateTime.parse("2011-03-25 08:47:23")
        cv.class.should == DateTime
      end
      it "time cast should cast a string to a time" do
        cv = CASTS[:time].call("08:47:23")
        cv.should == Time.parse("08:47:23")
        cv.class.should == Time
      end

    end

    describe DimensionSegmentModel do
      def create(attrs={})
        dimension_model = Object.new
        stub(dimension_model).key{:foodim}
        DimensionSegmentModel.new({ :key=>:foo,
                                    :dimension_model=>dimension_model,
                                    :fixed_dimension_value=>:foofoo}.merge(attrs))
      end

      it "should assign attributes on initialization" do
        dimension_model = Object.new
        key = Object.new
        fixed_dimension_value = Object.new
        extract_dimension_query = Object.new
        narrow_proc = Object.new
        values_proc = Object.new
        label_proc = Object.new
        value_cast = Object.new
        measure_modifiers = Object.new

        dsm = DimensionSegmentModel.new(:dimension_model=>dimension_model,
                                        :key=>key,
                                        :fixed_dimension_value=>fixed_dimension_value,
                                        :narrow_proc=>narrow_proc,
                                        :values_proc=>values_proc,
                                        :label_proc=>label_proc,
                                        :value_cast=>value_cast,
                                        :measure_modifiers=>measure_modifiers)
        dsm.dimension_model.should == dimension_model
        dsm.key.should == key
        dsm.fixed_dimension_value.should == fixed_dimension_value
        dsm.narrow_proc.should == narrow_proc
        dsm.values_proc.should == values_proc
        dsm.label_proc.should == label_proc
        dsm.value_cast.should == value_cast
        dsm.measure_modifiers.should == measure_modifiers

        dsm = DimensionSegmentModel.new(:dimension_model=>dimension_model,
                                        :key=>key,
                                        :extract_dimension_query=>extract_dimension_query,
                                        :narrow_proc=>narrow_proc,
                                        :values_proc=>values_proc,
                                        :label_proc=>label_proc,
                                        :value_cast=>value_cast,
                                        :measure_modifiers=>measure_modifiers)
        dsm.dimension_model.should == dimension_model
        dsm.key.should == key
        dsm.extract_dimension_query.should == extract_dimension_query
        dsm.narrow_proc.should == narrow_proc
        dsm.values_proc.should == values_proc
        dsm.label_proc.should == label_proc
        dsm.value_cast.should == value_cast
        dsm.measure_modifiers.should == measure_modifiers
      end

      describe "do_narrow" do
        it "should narrow the scope with the narrow_proc" do
          narrow_proc = Object.new
          dsm = create(:narrow_proc=>narrow_proc)

          scope = Object.new
          narrowed_scope = Object.new
          mock(narrow_proc).call(scope){narrowed_scope}

          dsm.do_narrow(scope).should == narrowed_scope
        end

        it "should return the scope unchaged if no narrow_proc" do
          dsm = create
          scope = Object.new
          dsm.do_narrow(scope).should == scope
        end
      end

      describe "do_cast" do
        it "should cast the value with the referenced Proc if value_cast is given" do
          dsm = create(:value_cast=>:int)
          dsm.do_cast("100").should == 100
        end

        it "should return the value unchanged if no value_cast is given" do
          dsm = create
          dsm.do_cast("100").should == "100"
        end
      end

      describe "do_modify" do
        it "should modify the measure_def with the modifier_proc" do
          dsm = create(:measure_modifiers => {:foo=>Proc.new{|mdef| "#{mdef}/12"}})
          dsm.do_modify(:foo, "count(*)").should == "count(*)/12"
        end

        it "should return the measure_def unchanged if no modifier_proc is given" do
          dsm = create
          dsm.do_modify(:foo, "count(*)").should == "count(*)"
        end
      end

      describe "select_string" do
        it "should return a quoted aliased fixed_dimension_value if given" do
          mock(ActiveRecord::Base).quote_value(:foofoo){"foofoo"}
          dsm = create
          dsm.select_string.should == "foofoo as foodim"
        end

        it "should return an aliased version of the extract_dimension_query if given" do
          dsm = create(:fixed_dimension_value=>nil, :extract_dimension_query=>"foocol")
          dsm.select_string.should == "foocol as foodim"
        end
      end

      describe "group_by_column" do
        it "should return the stringified dimension key" do
          dsm = create
          dsm.group_by_column.should == "foodim"
        end
      end

      describe "get_values" do
        it "should return a stringified fixed_dimension_value if given" do
          dsm = create
          dsm.get_values(Object.new).should == ["foofoo"]
        end

        it "should narrow the scope and return distinct values if extract_dimension_query" do
          dsm = create(:fixed_dimension_value=>nil, :extract_dimension_query=>"foocol")

          r1 = Object.new
          mock(r1).foodim{10}
          r2 = Object.new
          mock(r2).foodim{20}

          scope = Object.new
          mock(scope).select("distinct foocol as foodim").mock!.all{[r1,r2]}

          dsm.get_values(scope).should == [10,20]
        end
      end

      describe "labels" do
        it "should return capitalized stringified keys if no label_proc is given" do
          dsm = create
          dsm.labels([:foo, :foo_bar, "foo_bar_baz"]).should == {:foo=>"Foo", :foo_bar=>"Foo Bar", "foo_bar_baz"=>"Foo Bar Baz"}
        end

        it "should call label_proc for each value if label_proc is given" do
          dsm = create(:label_proc=>lambda{|v| v.to_s.upcase})
          dsm.labels([:foo]).should == {:foo=>"FOO"}
        end
      end
    end

    describe DimensionModel do
      describe "index_list" do
        it "should return a list of lists each with a segment_model index when given a nil prefix" do
          dm = DimensionModel.new(:key=>:foo, :segment_models=>[Object.new, Object.new])
          dm.index_list(nil).should == [[0],[1]]
        end

        it "should suffix each segment_model index to each prefix when given a non-nil prefix" do
          dm = DimensionModel.new(:key=>:foo, :segment_models=>[Object.new, Object.new])
          dm.index_list([[0],[1]]).should == [[0,0],[1,0],[0,1],[1,1]]
        end
      end
    end

    describe MeasureModel do
      describe "select_string" do
        it "should return an aliased definition if no region_segment_models modify the definition" do
          mm = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          sm1 = Object.new
          mock(sm1).do_modify(:count, "count(*)"){"count(*)"}
          sm2 = Object.new
          mock(sm2).do_modify(:count, "count(*)"){"count(*)"}

          mm.select_string([sm1, sm2]).should == "count(*) as count"
        end

        it "should allow the region_segment_models to modify the definition" do
          mm = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          sm1 = Object.new
          mock(sm1).do_modify(:count, anything){|key,mdef| "#{mdef}/12"}
          sm2 = Object.new
          mock(sm2).do_modify(:count, anything){|key,mdef| mdef}

          mm.select_string([sm1, sm2]).should == "count(*)/12 as count"
        end
      end

      describe "do_cast" do
        it "should return the value unchanged if no cast is specified" do
          mm = MeasureModel.new(:key=>:count, :definition=>"count(*)")
          mm.do_cast("100").should == "100"
          mm.do_cast("100").class.should == "100".class
        end

        it "should cast the value according to the cast specified" do
          mm = MeasureModel.new(:key=>:count, :definition=>"count(*)", :cast=>:int)
          mm.do_cast("100").should == 100
          mm.do_cast("100").class.should == 100.class
        end
      end
    end

    describe DatasetModel do
      describe "region_segment_model_indexes" do

        it "should produce the cross-producton of dimension segment indexes for one dimension" do
          dim1 = DimensionModel.new(:key=>:foo, :segment_models=>[Object.new, Object.new])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim1],
                                :measure_models=>[mm1])

          dm.region_segment_model_indexes.to_set.should == [[0],[1]].to_set
        end

        it "should produce the cross-product of dimension segment indexes for two dimensions" do
          dim1 = DimensionModel.new(:key=>:foo, :segment_models=>[Object.new, Object.new])
          dim2 = DimensionModel.new(:key=>:foo, :segment_models=>[Object.new, Object.new, Object.new])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim1, dim2],
                                :measure_models=>[mm1])

          dm.region_segment_model_indexes.to_set.should == [[0,0],[0,1],[0,2],[1,0],[1,1],[1,2]].to_set
        end

        it "should produce the cross-product of dimension segment indexes for 3 dimensions" do
          dim1 = DimensionModel.new(:key=>:foo, :segment_models=>[Object.new, Object.new])
          dim2 = DimensionModel.new(:key=>:foo, :segment_models=>[Object.new, Object.new, Object.new])
          dim3 = DimensionModel.new(:key=>:foo, :segment_models=>[Object.new, Object.new])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim1, dim2, dim3],
                                :measure_models=>[mm1])

          dm.region_segment_model_indexes.to_set.should == [[0,0,0],[0,0,1],[0,1,0],[0,1,1],[0,2,0],[0,2,1],[1,0,0],[1,0,1],[1,1,0],[1,1,1],[1,2,0],[1,2,1]].to_set
        end
      end

      describe "all_dimension_segment_models" do
        it "should return a list lists of dimension segments" do
          dim1sm1 = Object.new
          dim1sm2 = Object.new
          dim1 = DimensionModel.new(:key=>:foo, :segment_models=>[dim1sm1, dim1sm2])
          dim2sm1 = Object.new
          dim2sm2 = Object.new
          dim2sm3 = Object.new
          dim2 = DimensionModel.new(:key=>:foo, :segment_models=>[dim2sm1, dim2sm2, dim2sm3])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim1, dim2],
                                :measure_models=>[mm1])
          dm.all_dimension_segment_models.should == [[dim1sm1, dim1sm2], [dim2sm1, dim2sm2, dim2sm3]]
        end
      end

      describe "region_segment_models" do
        it "should produce a list of dimension segment models corresponding to the supplied indexes" do
          dim0sm0 = Object.new
          dim0sm1 = Object.new
          dim0 = DimensionModel.new(:key=>:foo, :segment_models=>[dim0sm0, dim0sm1])
          dim1sm0 = Object.new
          dim1sm1 = Object.new
          dim1sm2 = Object.new
          dim1 = DimensionModel.new(:key=>:foo, :segment_models=>[dim1sm0, dim1sm1, dim1sm2])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim0, dim1],
                                :measure_models=>[mm1])
          dm.region_segment_models([0,1]).should == [dim0sm0, dim1sm1]
          dm.region_segment_models([1,2]).should == [dim0sm1, dim1sm2]
        end
      end

      describe "with_regions" do
        it "should iterate of all regions calling the proc with the region segment models" do
          dim0sm0 = Object.new
          dim0sm1 = Object.new
          dim0 = DimensionModel.new(:key=>:foo, :segment_models=>[dim0sm0, dim0sm1])
          dim1sm0 = Object.new
          dim1sm1 = Object.new
          dim1sm2 = Object.new
          dim1 = DimensionModel.new(:key=>:foo, :segment_models=>[dim1sm0, dim1sm1, dim1sm2])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim0, dim1],
                                :measure_models=>[mm1])

          all_region_segment_models = [[dim0sm0,dim1sm0],[dim0sm0,dim1sm1],[dim0sm0,dim1sm2],[dim0sm1,dim1sm0],[dim0sm1,dim1sm1],[dim0sm1,dim1sm2]].to_set
          dm.with_regions do |region_segment_models|
            all_region_segment_models.delete(region_segment_models)
          end
          all_region_segment_models.empty?.should == true
        end
      end

      describe "construct_query" do
        it "should narrow the scope according to each segment in the region, select dimension and measure values, and group by dimensions" do
          dim0sm0 = Object.new
          dim0 = DimensionModel.new(:key=>:foo, :segment_models=>[dim0sm0])
          dim1sm0 = Object.new
          dim1 = DimensionModel.new(:key=>:bar, :segment_models=>[dim1sm0])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)")

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim0, dim1],
                                :measure_models=>[mm1])

          scope = Object.new
          region_segment_models = [dim0sm0, dim1sm0]
          measure_models = [mm1]

          # the narrowing
          scope_n1 = Object.new
          mock(dim0sm0).do_narrow(scope){scope_n1}
          scope_n2 = Object.new
          mock(dim1sm0).do_narrow(scope_n1){scope_n2}

          # dimension_select_strings
          mock(dim0sm0).select_string{"foofoo as foo"}
          mock(dim1sm0).select_string{"barbar as bar"}


          # measure_select_strings
          mock(mm1).select_string([dim0sm0, dim1sm0]){"count(*) as count"}

          select_string = "foofoo as foo,barbar as bar,count(*) as count"

          # group_string
          # mock(dim0sm0).group_by_column{"foo"}
          # mock(dim1sm0).group_by_column{"bar"}
          group_string = "1,2"

          scope_n3 = Object.new
          query = Object.new
          mock(scope_n2).select(select_string){scope_n3}.mock!.group(group_string){query}

          dm.construct_query(scope, region_segment_models, measure_models).should == query
        end
      end

      describe "extract" do
        it "should extract row records into hashes keyed by dimension-values and measure-keys" do
          dim0sm0 = Object.new
          dim0 = DimensionModel.new(:key=>:foo, :segment_models=>[dim0sm0])
          dim1sm0 = Object.new
          dim1 = DimensionModel.new(:key=>:bar, :segment_models=>[dim1sm0])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)", :cast=>:int)

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim0, dim1],
                                :measure_models=>[mm1])

          stub(dim0sm0).dimension_model{dim0}
          stub(dim0sm0).do_cast(anything){|value| value}
          stub(dim1sm0).dimension_model{dim1}
          stub(dim1sm0).do_cast(anything){|value| value}

          # ActiveRecord methods are called on row instances
          row1 = Object.new
          mock(row1).foo{"foo1"}
          mock(row1).bar{"bar1"}
          mock(row1).count{"10"}
          row2 = Object.new
          mock(row2).foo{"foo2"}
          mock(row2).bar{"bar2"}
          mock(row2).count{"20"}

          dm.extract([row1,row2], [dim0sm0, dim1sm0], [mm1]).should == [{:foo=>"foo1", :bar=>"bar1", :count=>10},
                                                                        {:foo=>"foo2", :bar=>"bar2", :count=>20}]
        end
      end


      describe "do_queries" do
        it "should do a query for each region and put the results in a dataset" do
          dim0sm0 = Object.new
          dim0 = DimensionModel.new(:key=>:foo, :segment_models=>[dim0sm0])
          dim1sm0 = Object.new
          dim1 = DimensionModel.new(:key=>:bar, :segment_models=>[dim1sm0])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)", :cast=>:int)

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim0, dim1],
                                :measure_models=>[mm1])

          mock(dm).with_regions do |proc|
            proc.call([dim0sm0,dim1sm0])
          end

          query = Object.new
          mock(dm).construct_query(dm.source, [dim0sm0, dim1sm0], [mm1]){query}
          records = Object.new
          mock(query).all{records}
          mock(dm).extract(records, [dim0sm0, dim1sm0], [mm1]){[{:foo=>"foo1", :bar=>"bar1", :count=>10},
                                                                {:foo=>"foo2", :bar=>"bar2", :count=>20}]}

          data = dm.do_queries
          data.should == [{:foo=>"foo1", :bar=>"bar1", :count=>10},
                          {:foo=>"foo2", :bar=>"bar2", :count=>20}]
        end
      end

      describe "collect" do
        it "should do_queries and use the result to constract a Dataset" do
          dim0sm0 = Object.new
          dim0 = DimensionModel.new(:key=>:foo, :segment_models=>[dim0sm0])
          mm1 = MeasureModel.new(:key=>:count, :definition=>"count(*)", :cast=>:int)

          dm = DatasetModel.new(:source=>Object.new,
                                :dimension_models=>[dim0],
                                :measure_models => [mm1])

          dataset = Object.new
          mock(dm).do_queries{dataset}

          mock(MDQuery::Dataset::Dataset).new(dm, dataset)

          dm.collect

        end
      end
    end
  end
end
