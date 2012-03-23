require 'mdquery/dataset'
require 'mdquery/util'

module MDQuery
  module Model

    CASTS = {
      :sym => lambda{|v| v.to_sym},
      :int => lambda{|v| v.to_i},
      :float => lambda{|v| v.to_f},
      :date => lambda{|v| v.to_date},
      :datetime => lambda{|v| v.do_datetime},
      :time => lambda{|v| v.to_time}
    }

    class DimensionSegmentModel
      attr_reader :dimension_model
      attr_reader :key
      attr_reader :fixed_dimension_value
      attr_reader :extract_dimension_query
      attr_reader :narrow_proc
      attr_reader :values_proc
      attr_reader :label_proc
      attr_reader :value_cast
      attr_reader :measure_modifiers

      DEFAULT_LABEL_PROC = Proc.new do |value|
        value.to_s.gsub('_', ' ').split.map(&:capitalize).join(' ')
      end

      def initialize(attrs)
        MDQuery::Util.assign_attributes(self, attrs)
        validate
      end

      def validate
        raise "no dimension_model!" if !dimension_model
        raise "no key!" if !key
        raise "only one of fix_dimension and extract_dimension can be given" if fixed_dimension_value && extract_dimension_query
        raise "one of fix_dimension or extract_dimension must be given" if !fixed_dimension_value && !extract_dimension_query
        measure_modifiers ||= {}
      end

      def inspect
        "#<DimensionSegment: key=#{key.inspect}, fixed_dimension_value=#{fixed_dimension_value.inspect}, extract_dimension_query=#{extract_dimension_query.inspect}, narrow_proc=#{narrow_proc.inspect}, label_proc=#{label_proc.inspect},  value_cast=#{value_cast.inspect}, measure_modifiers=#{measure_modifiers.inspect}>"
      end

      def do_narrow(scope)
        if narrow_proc
          narrow_proc.call(scope)
        else
          scope
        end
      end

      def do_cast(value)
        cast_lambda=CASTS[value_cast] if value_cast
        if cast_lambda
          cast_lambda.call(value)
        else
          value
        end
      end

      def do_modify(measure_key, measure_def)
        if modifier = measure_modifiers[measure_key]
          modifier.call(measure_def)
        else
          measure_def
        end
      end

      def select_string
        if fixed_dimension_value
          "#{ActiveRecord::Base.quote_value(fixed_dimension_value)} as #{dimension_model.key}"
        else
          "#{extract_dimension_query} as #{dimension_model.key}"
        end
      end

      def group_by_column
        dimension_model.key.to_s
      end

      def get_values(scope)
        if fixed_dimension_value
          [fixed_dimension_value.to_s]
        elsif values_proc
          values_proc.call(scope)
        else
          narrowed_scope = do_narrow(scope)
          records = narrowed_scope.select("distinct #{select_string}").all
          records.map{|r| r.send(dimension_model.key)}.map{|v| do_cast(v)}
        end
      end

      # map of values to names
      def labels(values)
        values.reduce({}) do |labels,value|
          labels[value] = (label_proc || DEFAULT_LABEL_PROC).call(value)
          labels
        end
      end

      def dimension_values(scope)
        get_values(scope).map{|v| MDQuery::DimensionValue.new(key,
                                                              v,
                                                              (label_proc || DEFAULT_LABEL_PROC).call(v))}
      end
    end

    class DimensionModel
      attr_reader :key
      attr_reader :label
      attr_reader :segment_models

      def initialize(attrs)
        MDQuery::Util.assign_attributes(self, attrs)
        # validate # don't call validate, it's called by the DSL builder
      end

      def validate
        raise "no key!" if !key
        raise "no segment_models!" if !segment_models || segment_models.empty?
      end

      def inspect
        "#<DimensionDefinition: key=#{key.inspect}, segment_models=#{segment_models.inspect}>"
      end

      def index_list(prefixes=nil)
        (0...segments_models.length).reduce([]){|l, i| l + (prefixes||[[]]).map{|prefix| prefix.clone << i}}
      end

      def dimension_values(scope)
        segment_models.map do |s|
          s.dimension_values(scope)
        end.reduce(&:concat)
      end

      def dimension(scope)
        MDQuery::Dataset::Dimension.new(key, label_str, dimension_values(scope))
      end

    end

    class MeasureModel
      attr_reader :key
      attr_reader :definition
      attr_reader :cast

      def initialize(attrs)
        MDQuery::Util.assign_attributes(self, attrs)
        validate
      end

      def validate
        raise "no key!" if !key
        raise "no definition!" if !definition
        raise "unknown cast: #{cast.inspect}" if cast && !CASTS.keys.include?(cast)
      end

      def inspect
        "#<MeasureDefinition: key=#{key.inspect}, definition=#{definition.inspect}, cast=#{cast.inspect}>"
      end

      def select_string(region_segment_models)
        modified_def = region_segment_models.reduce(definition){|modef,rsm| rsm.do_modify(key, modef)}
        "#{modified_def} as #{key}"
      end

      def do_cast(value)
        cast_lambda=CASTS[cast] if cast
        if cast_lambda
          cast_lambda.call(value)
        else
          value
        end
      end
    end

    class DatasetModel
      attr_reader :source_scope
      attr_reader :dimension_models
      attr_reader :measure_models

      def initialize(attrs)
        MDQuery::Util.assign_attributes(self, attrs)
        validate
      end

      def validate
        raise "no source scope!" if !source_scope
        raise "no dimension_models!" if !dimension_models || dimension_models.empty?
        raise "no measure_models!" if !measure_models || measure_models.empty?
      end

      def inspect
        "#<DatasetDefinition: dimension_models=#{dimension_models.inspect}, measure_models=#{measure_models.inspect}>"
      end

      # a list of tuples of dimension-segment indexes, each tuple specifying
      # one segment for each dimension
      def region_segment_model_indexes
        dimension_models.reduce(nil){|indexes, dimension_model| dimension_model.index_list(indexes)}
      end

      # a list of lists of dimension-segments
      def all_dimension_segment_models
        dimension_models.map(&:segment_models)
      end

      # given a list of dimension-segment indexes, one for each dimension,
      # retrieve a list of dimension-segments, one for each dimension,
      # specifying a region
      def region_segment_models(indexes)
        ds = all_dimension_segment_models
        d_i = (0...indexes.length).zip(indexes)
        d_i.map{|d,i| ds[d][i]}
      end

      # call a block with a list of dimension-segments, one for each dimension
      def with_regions(&proc)
        region_segment_model_indexes.each do |indexes|
          proc.call(region_segment_models(indexes))
        end
      end

      def construct_query(scope, region_segment_models, measure_models)
        narrowed_scope = region_segment_models.reduce(scope){|scope, ds| ds.do_narrow(scope)}

        dimension_select_strings = region_segment_models.map(&:select_string)

        measure_select_strings = measure_models.map{|m| m.select_string(region_segment_models)}

        select_string = (dimension_select_strings + measure_select_strings).join(",")

        group_string = region_segment_models.map(&:group_by_column).join(",")

        narrowed_scope.select(select_string).group(group_string)
      end

      def extract(rows, region_segment_models, measure_models)
        rows.map do |row|
          dimension_values = region_segment_models.map do |ds|
            {ds.dimension.key => ds.do_cast(row.send(ds.dimension.key))}
          end
          measure_values = measure_models.map do |m|
            {m.key => m.do_cast(row.send(m.key))}
          end

          (dimension_values + measure_values).reduce(&:merge)
        end
      end


      def analyse
        data = []

        with_regions do |region_segment_models|
          q = construct_query(source_scope, region_segment_models, measures)
          points = extract(q.all, region_segment_models, measure_models)
          data += points
        end

        ds = dimension_models.reduce({}){|h,dm| h[dm.key] = dm.dimension(source_scope) ; h}

        MDQuery::Dataset::Dataset.new(:definition=>self,
                                      :dimensions=>ds,
                                      :measures=>measure_models.map(&:key),
                                      :data=>data)
      end
    end
  end
end
