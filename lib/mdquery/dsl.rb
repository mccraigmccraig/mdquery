require 'mdquery/model'

module MDQuery
  module DSL

    class DimensionSegmentDSL
      attr_reader :dimension
      attr_reader :key
      attr_reader :fixed_dimension_value
      attr_reader :extract_dimension_query
      attr_reader :narrow_proc
      attr_reader :value_proc
      attr_reader :label_proc
      attr_reader :value_cast
      attr_reader :measure_modifiers

      def fix_dimension(v)
        @fixed_dimension_value=v
      end

      def extract_dimension(q)
        @extract_dimension_query=q
      end

      def narrow(&proc)
        raise "no block!" if !proc
        @narrow_proc = proc
      end

      def values(&proc)
        raise "no block!" if !proc
        @value_proc = proc
      end

      def label(&proc)
        raise "no block!" if !proc
        @label_proc = proc
      end

      def cast(c)
        raise "unknown cast: #{c.inspect}" if !MDQuery::Model::CASTS.keys.include?(c)
        @value_cast = c
      end

      def modify(measure, &proc)
        raise "no block!" if !proc
        measure_modifiers[measure] = proc
      end

      private

      def initialize(key,&proc)
        @key = key
        @measure_modifiers = {}
        self.instance_eval(&proc)
        validate
      end

      def build(dimension)
        MDQuery::Model::DimensionSegmentModel.new(:dimension=>dimension,
                                                  :key=>key,
                                                  :fixed_dimension_value=>fixed_dimension_value,
                                                  :extract_dimension_query=>extract_dimension_query,
                                                  :narrow_proc=>narrow_proc,
                                                  :value_proc=>value_proc,
                                                  :label_proc=>label_proc,
                                                  :value_cast=>value_cast,
                                                  :measure_modifiers=>measure_modifiers)
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
