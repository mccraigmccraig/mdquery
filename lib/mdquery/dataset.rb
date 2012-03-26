require 'mdquery/util'

module MDQuery
  module Dataset

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
    end

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

      def dimension_value_for(value)
        @dimension_value_index[value]
      end

      def label_for(value)
        (dv = dimension_value_for(value)) && dv.label
      end
    end

    class Dimension
      attr_reader :dataset

      attr_reader :key
      attr_reader :label

      attr_reader :segments

      # an ordered list of values for the dimension
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

      # lookup a segment by +key+
      def segment(key)
        @segment_index[key]
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

      # the DimensionValue describing +value+ or nil
      def dimension_value_for(value)
        @dimension_value_index[value]
      end

      # the label for the +value+ or nil
      def label_for(value)
        (dv = dimension_value_for(value)) && dv.label
      end
    end

    class Measure
      attr_reader :dataset
      attr_reader :key
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
    end

    class Dataset
      attr_reader :model

      attr_reader :data
      attr_reader :dimensions
      attr_reader :measures
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
