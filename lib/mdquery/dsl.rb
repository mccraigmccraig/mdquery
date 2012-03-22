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

    class DimensionDSL
      attr_reader :key
      attr_reader :label
      attr_reader :segments

      def segment(key, &proc)
        raise "no block!" if !proc
        @segments << DimensionSegmentDSL.new(self, key)
      end

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
        dd = MDQuery::Model::DimensionModel.new(:key=>key, :label=>label)
        ss = segments.map{|dsdsl| dsdsl.send(:build, dd)}
        dd.instance_eval{@segments = ss}
        dd.validate
        dd
      end
    end

    class MeasureDSL
      attr_reader :key
      attr_reader :definition
      attr_reader :cast

      private

      def initialize(key, definition, cast=nil)
        @key = key
        @definition = definition
        raise "unknown cast: #{cast.inspect}" if !CASTS.keys.include?(cast)
        @cast = cast
      end

      def build
        MDQuery::Model::MeasureModel.new(key, definition, cast)
      end
    end

    class DatasetDSL
      attr_reader :source_scope
      attr_reader :dimensions
      attr_reader :measures

      def source(scope)
        raise "source already set" if @source_scope
        @source_scope = scope
      end

      def dimension(k, &proc)
        @dimensions << DimensionDSL.new(k, &proc)
      end

      def measure(k,d,c=nil)
        @measures << MeasureDSL.new(k,d,c)
      end

      private

      def initialize(&proc)
        raise "no block!" if !proc
        @dimensions=[]
        @measures=[]
        self.instance_eval(&proc)
      end

      def build
        ds = dimensions.map(&:build)
        ms = measures.map(&:build)
        MDQuery::Model::DatasetModel.new(:source_scope=>source_scope,
                                         :dimension_models=>ds,
                                         :measure_models=>ms)
      end
    end

  end
end
