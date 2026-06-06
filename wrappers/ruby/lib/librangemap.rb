# frozen_string_literal: true

require "fiddle"
require "fiddle/import"
require "json"

module LibrangeMap
  module Native
    extend Fiddle::Importer

    DLL_PATH = File.expand_path(
      File.join(__dir__, "..", "..", "..", "librangemap", "native", "librangemap_core.dll")
    )

    dlload DLL_PATH

    extern "int lrm_integer_range_mapper_init(void*, long long, long long, double, double, int);"
    extern "int lrm_integer_range_mapper_map_value(const void*, long long, double*);"
    extern "int lrm_integer_range_mapper_get_spec(const void*, void*);"
  end

  class IntegerRangeMapper
    SPEC_VERSION = "1.0-alpha"

    LRM_ERROR_INVALID_RANGE = 1
    LRM_ERROR_INVALID_VALUE = 2
    LRM_ERROR_OUT_OF_RANGE = 3
    LRM_ERROR_NULL_POINTER = 4

    def initialize(input_min, input_max, output_min = -1.0, output_max = 1.0, clip = false)
      @mapper = Fiddle::Pointer.malloc(mapper_struct_size)
      status = Native.lrm_integer_range_mapper_init(
        @mapper,
        input_min.to_i,
        input_max.to_i,
        output_min.to_f,
        output_max.to_f,
        clip ? 1 : 0
      )
      raise_native_error("init", status) unless status.zero?
    end

    def map_value(value)
      mapped = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DOUBLE)
      status = Native.lrm_integer_range_mapper_map_value(@mapper, value.to_i, mapped)
      raise_native_error("map_value", status) unless status.zero?
      mapped[0, Fiddle::SIZEOF_DOUBLE].unpack1("E")
    end

    alias map map_value

    def spec
      raw_spec = Fiddle::Pointer.malloc(spec_struct_size)
      status = Native.lrm_integer_range_mapper_get_spec(@mapper, raw_spec)
      raise_native_error("get_spec", status) unless status.zero?

      spec_major = raw_spec[0, 4].unpack1("l<")
      spec_minor = raw_spec[4, 4].unpack1("l<")
      input_min = raw_spec[8, 8].unpack1("q<")
      input_max = raw_spec[16, 8].unpack1("q<")
      output_min = raw_spec[24, 8].unpack1("E")
      output_max = raw_spec[32, 8].unpack1("E")
      clip = raw_spec[40, 4].unpack1("l<") != 0

      {
        "spec_version" => "#{spec_major}.#{spec_minor}",
        "mapper_type" => "integer_range",
        "input_range" => [input_min, input_max],
        "output_range" => [output_min, output_max],
        "clip" => clip
      }
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    def self.from_json(json_text)
      data = JSON.parse(json_text)
      from_spec(data)
    end

    def self.from_spec(data)
      raise ArgumentError, "unsupported spec_version #{data["spec_version"]}" unless data["spec_version"] == SPEC_VERSION
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "integer_range"

      input_range = data.fetch("input_range")
      output_range = data.fetch("output_range")
      raise ArgumentError, "input_range must contain exactly two values" unless input_range.is_a?(Array) && input_range.length == 2
      raise ArgumentError, "output_range must contain exactly two values" unless output_range.is_a?(Array) && output_range.length == 2

      new(
        input_range[0],
        input_range[1],
        output_range[0],
        output_range[1],
        data.fetch("clip", false)
      )
    end

    private

    def raise_native_error(operation, status)
      case status
      when LRM_ERROR_INVALID_RANGE
        raise ArgumentError, "librangemap #{operation} failed: invalid range"
      when LRM_ERROR_INVALID_VALUE
        raise RuntimeError, "librangemap #{operation} failed: invalid value"
      when LRM_ERROR_OUT_OF_RANGE
        raise RangeError, "librangemap #{operation} failed: out of range"
      when LRM_ERROR_NULL_POINTER
        raise RuntimeError, "librangemap #{operation} failed: null pointer"
      else
        raise RuntimeError, "librangemap #{operation} failed with status #{status}"
      end
    end

    def mapper_struct_size
      40
    end

    def spec_struct_size
      48
    end
  end
end
