require 'mdquery/util'

module MDQuery
  module Dataset

    # describes a value on a segment of a dimension
    class DimensionValue
      # DimensionSegment this value belongs to
      attr_reader :dimension_segment

      # the value
      attr_reader :value

      # Optional label for the value
      attr_reader :label

      def initialize(dimension_segment, value, label)
        @dimension_segment = dimension_segment
        @value = value
        @label = label
        validate
      end

      def validate
        raise "no dimension_segment!" if !dimension_segment
        raise "no value!" if !value
      end

      def inspect
        "#<DimensionValue: value=#{value.inspect}, label=#{label.inspect}>"
      end
    end

    # describes a segment of a dimension, a segment being some part of
    # the dimension value line. Dimension values should not be present
    # in more than one segment of a dimension, or results will be
    # unexpected, though it's fine for aggregate values to be present
    # which cover the same range as other values. e.g. having values of
    # "jan", "feb", "march"... in one segment and "q1","q2","q3","q4"
    # in another segment is fine
    class DimensionSegment
      # Dimension this Segment belongs to
      attr_reader :dimension

      # key of segment, unique within Dimension
      attr_reader :key

      # ordered list of DimensionValues in segment
      attr_reader :dimension_values

      # ordered list of all values in segment
      attr_reader :values

      def initialize(model, dimension)
        @dimension = dimension
        @key = model.key

        @values = model.get_values(dimension.dataset.model.source)

        label_index = model.labels(@values)
        @dimension_values = @values.map{|v| DimensionValue.new(self, v, label_index[v]) }
        @dimension_value_index = @dimension_values.reduce({}){|dvi,dv| dvi[dv.value] = dv ; dvi}

        validate
      end

      def validate
        raise "no dimension!" if !dimension
        raise "no key!" if !key
        raise "no values!" if !values
      end

      def inspect
        "#<DimensionSegment: key=#{key.inspect}, dimension_values=#{dimension_values.inspect}>"
      end

      # retrieve a DimensionValue describing the given +value+
      def dimension_value_for(value)
        @dimension_value_index[value]
      end

      # retrieve a DimensionValue describing the given +value+
      def [](value)
        dimension_value_for(value)
      end

      # retrieve a label describing the given +value+
      def label_for(value)
        (dv = dimension_value_for(value)) && dv.label
      end
    end

    # describes a Dimension consisting of one or more segments
    class Dimension
      # Dataset this Dimension belongs to
      attr_reader :dataset

      # key for this Dimension
      attr_reader :key

      # Optional label of the Dimension
      attr_reader :label

      # ordered list of one or more DimensionSegments
      attr_reader :segments

      # an ordered list of values for the dimension. May be static or
      # extracted from the data source, depending on DimensionSegment
      # definitions. It is the concatentation of the +values+ from each
      # DimensionSegment in the Dimension
      attr_reader :values

      def initialize(model, dataset)
        @dataset = dataset
        @key = model.key
        @label = model.label

        @segments = model.segment_models.map{|sm| DimensionSegment.new(sm, self) }
        @segment_index = @segments.reduce({}){|si, s| si[s.key] = s ; si}

        @values = segments.map(&:values).reduce(&:+)
        @dimension_value_index = segments.map(&:dimension_values).reduce(&:+).reduce({}){|dvi,dv| dvi[dv.value] = dv ; dvi}

        validate
      end

      def validate
        raise "no dataset!" if !dataset
        raise "no key!" if !key
        raise "no segments!" if !segments || segments.empty?
      end

      def inspect
        "#<Dimension: key=#{key.inspect}, label=#{label.inspect}, segments=#{segments.inspect}>"
      end

      # lookup a segment by +key+
      def segment(key)
        @segment_index[key]
      end

      # lookup a segment by +key+
      def [](key)
        segment(key)
      end

      # return an ordered list of values for 0 or more segments.
      # * +segment_keys+ a list of segment keys. if empty, methods returns +values+,
      # otherwise returns the concatentation of +values+ for each identified segment
      def values_for_segments(segment_keys)
        if segment_keys && !segment_keys.empty?
          segment_keys.map{|sk| segment(sk)}.map(&:values).reduce(&:+)
        else
          values
        end
      end

      # return an ordered list of DimensionValues for 0 or more segments.
      # * +segment_keys+ a list of segment keys. if empty, methods return all DimensionValues
      # for all segments, otherwise returns the concatenation of DimensionValues for
      # each identified segment
      def dimension_values_for_segments(segment_keys)
        if segment_keys && !segment_keys.empty?
          segment_keys.map{|sk| segment(sk)}.map(&:dimension_values).reduce(&:+)
        else
          dimension_values
        end
      end

      def dimension_values
        segments.map(&:dimension_values).reduce(&:+)
      end

      # the DimensionValue describing +value+ or nil
      def dimension_value_for(value)
        @dimension_value_index[value]
      end

      # the label for the +value+ or nil
      def label_for(value)
        (dv = dimension_value_for(value)) && dv.label
      end
    end

    # describes a Measure computed from the source data over the Dimensions
    class Measure
      # the +dataset+ this Measure belongs to
      attr_reader :dataset

      # the +key+ identifying this Measure
      attr_reader :key

      # the SQL fragment definition of the Measure
      attr_reader :definition

      def initialize(model, dataset)
        @dataset = dataset
        @key = model.key
        @definition = model.definition
        validate
      end

      def validate
        raise "no dataset" if !dataset
        raise "no key!" if !key
        raise "no definition!" if !definition || definition=~/^\s*$/
      end

      def inspect
        "#<Measure: key=#{key.inspect}, definition=#{definition.inspect}>"
      end
    end

    # a Dataset is defined over a number of Dimensions with a number of Measures.
    #
    class Dataset
      # the +Model+ describing how the +Dataset+ is to be assembled
      attr_reader :model

      # a list of points. each point is a Hash with a value for each +Dimension+ and a value for each +Measure+.
      # keys are as given in the +Dimension+ and +Measure+ objects
      attr_reader :data

      # a Hash of +Dimensions+ keyed by their +keys+
      attr_reader :dimensions

      # a Hash of +Measures+ keyed by their +keys+
      attr_reader :measures

      # index of points from +data+, where key is a Hash of all Dimension {key=>value} pairs, and value is all Measure {key=>value} pairs
      attr_reader :indexed_data

      def initialize(model, data)
        @model = model
        @data = data

        @measures = model.measure_models.map{|mm| Measure.new(mm, self) }.reduce({}){|mi,m| mi[m.key] = m ; mi}
        @dimensions = model.dimension_models.map{|dm| Dimension.new(dm, self) }.reduce({}){|di,d| di[d.key] = d ; di}

        validate
        index
      end

      def validate
        raise "no model!" if !model
        raise "no data!" if !data
        raise "no dimensions!" if !dimensions || dimensions.empty?
        raise "no measures!" if !measures || measures.empty?
      end

      def inspect
        "#<Dataset: dimensions=#{dimensions.inspect}, measures=#{measures.inspect}, data=#{data.inspect}>"
      end

      # retrieve a datapoint given a hash of {dimension_key=>dimension_values}
      def datapoint(dimension_values, measure)
        d = @indexed_data[dimension_values]
        d[measure] if d
      end

      private

      def index_key(point)
        Hash[dimensions.keys.map{|k| [k, point[k]]}]
      end

      def index_data(point)
        pc = point.clone
        dks = dimensions.keys
        pc.delete_if{|k,v| dks.include?(k)}
        pc
      end

      def index
        @indexed_data = {}
        data.each do |point|
          @indexed_data[index_key(point)] = index_data(point)
        end
        @indexed_data
      end
    end
  end
end
