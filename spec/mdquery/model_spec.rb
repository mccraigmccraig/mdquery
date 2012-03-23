require File.expand_path('../../spec_helper', __FILE__)
require 'mdquery/model'

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

      describe "dimension_values" do
        it "should return a list of DimensionValue objects for each value of get_values(scope)" do
          scope = Object.new

          dsm = create
          mock(dsm).get_values(scope){[1,2,3]}

          dvs = dsm.dimension_values(scope)
          dvs.map(&:segment_key).should == [:foo, :foo, :foo]
          dvs.map(&:value).should == [1,2,3]
          dvs.map(&:label).should == ["1", "2", "3"]
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

      describe "dimension_values" do
        it "should concatenate values from each of the segment_models" do
          scope = Object.new
          sm1 = Object.new
          sm1dv1 = Object.new
          sm1dv2 = Object.new
          mock(sm1).dimension_values(scope){[sm1dv1, sm1dv2]}
          sm2 = Object.new
          sm2dv1 = Object.new
          sm2dv2 = Object.new
          mock(sm2).dimension_values(scope){[sm2dv1,sm2dv2]}

          dm = DimensionModel.new(:key=>:foo, :segment_models=>[sm1, sm2])

          dm.dimension_values(scope).should == [sm1dv1,sm1dv2,sm2dv1,sm2dv2]
        end
      end

      describe "dimension" do
        it "should return a Dataset::Dimension" do
          scope = Object.new
          sm1 = Object.new
          sm1dv1 = MDQuery::Dataset::DimensionValue.new(:s1key, 10, "ten")
          sm1dv2 = MDQuery::Dataset::DimensionValue.new(:s1key, 20, "twenty")
          mock(sm1).dimension_values(scope){[sm1dv1, sm1dv2]}
          sm2 = Object.new
          sm2dv1 = MDQuery::Dataset::DimensionValue.new(:s2key, 1, "one")
          sm2dv2 = MDQuery::Dataset::DimensionValue.new(:s2key, 2, "two")
          mock(sm2).dimension_values(scope){[sm2dv1,sm2dv2]}

          dm = DimensionModel.new(:key=>:foo, :segment_models=>[sm1, sm2], :label=>"FOO")

          d = dm.dimension(scope)
          d.key.should == :foo
          d.label.should == "FOO"
          d.values.should == [sm1dv1,sm1dv2,sm2dv1,sm2dv2]
          d.values_for_segment(:s1key).should == [sm1dv1, sm1dv2]
          d.values_for_segment(:s2key).should == [sm2dv1, sm2dv2]
          d.values_for_segments([:s2key, :s1key]).should == [sm2dv1, sm2dv2, sm1dv1, sm1dv2]
        end
      end
    end

    describe MeasureModel do
      describe "select_string" do
      end

      describe "do_cast" do
      end
    end

    describe DatasetModel do
    end
  end
end
