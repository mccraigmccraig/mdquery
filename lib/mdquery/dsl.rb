require 'mdquery/model'

module MDQuery
  module DSL

    # DSL for describing a DimensionSegment
    class DimensionSegmentDSL

      # fix the Dimension value for this segment. exclusive of +extract_dimension+
      # * +v+ the Dimension value for this segment
      def fix_dimension(v)
        @fixed_dimension_value=v
      end

      # extract DimensionValues from data for this segment. exclusive of +fix_dimension+
      # * +q+ SQL select string fragment for the dimension value
      def extract_dimension(q)
        @extract_dimension_query=q
      end

      # Narrow the datasource to extract this segment. Optional
      # * +proc+ a Proc of a single parameter, an ActiveRecord Scope to be narrowed
      def narrow(&proc)
        raise "no block!" if !proc
        @narrow_proc = proc
      end

      # Define an ordered list of all possible Dimension Values for the segment. Optional
      # * +proc+ a Proc of a single parameter, an ActiveRecord Scope which can be used
      # to query for the values
      def values(&proc)
        raise "no block!" if !proc
        @values_proc = proc
      end

      # set a Proc to be used to convert Dimension values into labels. Optional
      # * +proc+ a Proc of a single parameter which will be called to convert Dimension values
      # into labels
      def label(&proc)
        raise "no block!" if !proc
        @label_proc = proc
      end

      # define a cast to convert values into the desired datatype
      # * +c+ a keyword key for the casts in MDQuery::Model::Casts
      def cast(c)
        raise "unknown cast: #{c.inspect}" if !MDQuery::Model::CASTS.keys.include?(c)
        @value_cast = c
      end

      # set a Proc to be used to modify the measure-value in any query using this segment
      # * +measure+ a keyword describing the Measure
      # * +proc+ a Proc of a single parameter which will be used to transform the measure value
      def modify(measure, &proc)
        raise "no block!" if !proc
        @measure_modifiers[measure] = proc
      end

      private

      def initialize(key,&proc)
        @key = key
        @measure_modifiers = {}
        self.instance_eval(&proc)
      end

      def build(dimension)
        MDQuery::Model::DimensionSegmentModel.new(:dimension_model=>dimension,
                                                  :key=>@key,
                                                  :fixed_dimension_value=>@fixed_dimension_value,
                                                  :extract_dimension_query=>@extract_dimension_query,
                                                  :narrow_proc=>@narrow_proc,
                                                  :values_proc=>@values_proc,
                                                  :label_proc=>@label_proc,
                                                  :value_cast=>@value_cast,
                                                  :measure_modifiers=>@measure_modifiers)
      end
    end

    # DSL for describing a Dimension consisting of an ordered list of segments
    class DimensionDSL
      # define a segment
      # * +key+ the segment key, should be unique in the Dimension
      # * +proc+ the DimensionSegmentDSL Proc
      def segment(key, &proc)
        raise "no block!" if !proc
        @segments << DimensionSegmentDSL.new(key, &proc)
      end

      # set the Label for the segment
      # * +label+ a label for the segment
      def label(l)
        @label = l
      end

      private

      def initialize(key, &proc)
        raise "no block!" if !proc
        @key = key
        @segments = []
        self.instance_eval(&proc)
      end

      def build
        dd = MDQuery::Model::DimensionModel.new(:key=>@key, :label=>@label)
        ss = @segments.map{|dsdsl| dsdsl.send(:build, dd)}
        dd.instance_eval{@segment_models = ss}
        dd.validate
        dd
      end
    end

    # DSL for defining Measures
    class MeasureDSL
      private

      def initialize(key, definition, cast=nil)
        @key = key
        @definition = definition
        @cast = cast
      end

      def build
        MDQuery::Model::MeasureModel.new(:key=>@key,
                                         :definition=>@definition,
                                         :cast=>@cast)
      end
    end

    # DSL for defining a Dataset with a number of Measures over a number of Dimensions
    # where each Dimension consists of a number of Segments
    class DatasetDSL

      # define the datasource for the Dataset
      # * +scope+ an ActiveRecord scope, used as the basis for all region queries
      def source(scope)
        raise "source already set" if @source
        @source = scope
      end

      # define a Dimension
      # * +key+ the key identifying the Dimension in the Dataset
      # * +proc+ a DimensionDSL Proc
      def dimension(key, &proc)
        @dimensions << DimensionDSL.new(key, &proc)
      end

      # define a Measure
      # * +key+ the key identifying the Measure in the Dataset
      # * +definition+ the SQL fragment defining the measure
      # * +cast+ a symbol identifying a case from MDQuery::Model::CASTS. Optional
      def measure(key, definition, cast=nil)
        @measures << MeasureDSL.new(key, definition, cast)
      end

      private

      def initialize(&proc)
        raise "no block!" if !proc
        @dimensions=[]
        @measures=[]
        self.instance_eval(&proc)
      end

      def build
        ds = @dimensions.map{|d| d.send(:build)}
        ms = @measures.map{|m| m.send(:build)}
        MDQuery::Model::DatasetModel.new(:source=>@source,
                                         :dimension_models=>ds,
                                         :measure_models=>ms)
      end
    end

  end
end
