module MDQuery
  class DimensionValue
    attr_reader :segment_key
    attr_reader :value
    attr_reader :label

    def initialize(segment_key, value, label)
      @segment_key = segment_key
      @value = value
      @label = label
    end
  end

  class Dimension
    attr_reader :key
    attr_reader :label
    attr_reader :values
    attr_reader :label_index
    attr_reader :value_list

    def initialize(key, label, values)
      @key = key
      @label = label
      @values = values
      @value_list = values.map(&:value)
      @label_index = values.reduce({}){|li,dv| li[dv.value] = dv.label ; li}
    end

    def label_for(key)
      label_index[key]
    end

    def values_for_segment(segment_key)
      values.select{|v| v.segment_key == segment_key}
    end

    def values_for_segments(segment_keys)
      if segment_keys && !segment_keys.empty?
        segment_keys.map{|sk| values_for_segment(sk)}.reduce(&:concat)
      else
        values
      end
    end
  end

  class Dataset
    attr_reader :definition
    attr_reader :dimensions
    attr_reader :measures
    attr_reader :data
    attr_reader :indexed_data

    def initialize(attrs)
      MDQuery::Util.assign_attributes(self, attrs)
      validate
      index
    end

    # retrieve a datapoint given a hash of {dimension_key=>dimension_values}
    def datapoint(dimension_values, measure)
      d = @indexed_data[dimension_values]
      d[measure] if d
    end

    private

    def validate
      raise "no definition!" if !definition
      raise "no dimensions!" if !dimensions
      raise "no measures!" if !measures
      raise "no data!" if !data
    end

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
