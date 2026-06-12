# frozen_string_literal: true

require "fiddle"
require "fiddle/import"
require "date"
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
        "spec_version" => "#{spec_major}.#{spec_minor}-alpha",
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

  class FloatRangeMapper
    SPEC_VERSION = "1.0-alpha"

    def initialize(input_min, input_max, output_min = -1.0, output_max = 1.0, clip = false, allow_integer = true)
      unless [true, false].include?(clip)
        raise TypeError, "clip must be a boolean."
      end
      unless [true, false].include?(allow_integer)
        raise TypeError, "allow_integer must be a boolean."
      end

      @input_min = require_finite_number(input_min, "input_range[0]").to_f
      @input_max = require_finite_number(input_max, "input_range[1]").to_f
      @output_min = require_finite_number(output_min, "output_range[0]").to_f
      @output_max = require_finite_number(output_max, "output_range[1]").to_f
      validate_range(@input_min, @input_max, "input_range")
      validate_range(@output_min, @output_max, "output_range")
      @clip = clip
      @allow_integer = allow_integer
    end

    def map_value(value)
      numeric = coerce_numeric(value)
      mapped = numeric
      if mapped < @input_min || mapped > @input_max
        if @clip
          mapped = [[mapped, @input_min].max, @input_max].min
        else
          raise RangeError, "value #{value.inspect} is out of range; enable clip to clamp."
        end
      end
      linear_map(mapped, @input_min, @input_max, @output_min, @output_max)
    end

    alias map map_value

    def spec
      {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "float_range",
        "input_range" => [@input_min, @input_max],
        "output_range" => [@output_min, @output_max],
        "clip" => @clip,
        "allow_integer" => @allow_integer
      }
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    def self.from_json(json_text)
      from_spec(JSON.parse(json_text))
    end

    def self.from_spec(data)
      raise ArgumentError, "unsupported spec_version #{data["spec_version"]}" unless data["spec_version"] == SPEC_VERSION
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "float_range"

      input_range = data.fetch("input_range")
      output_range = data.fetch("output_range")
      raise ArgumentError, "input_range must contain exactly two values" unless input_range.is_a?(Array) && input_range.length == 2
      raise ArgumentError, "output_range must contain exactly two values" unless output_range.is_a?(Array) && output_range.length == 2

      new(
        input_range[0],
        input_range[1],
        output_range[0],
        output_range[1],
        data.fetch("clip", false),
        data.fetch("allow_integer", true)
      )
    end

    private

    def require_finite_number(value, label)
      if value.is_a?(Integer)
        value
      elsif value.is_a?(Float) && value.finite?
        value
      else
        raise TypeError, "#{label} must be a finite number."
      end
    end

    def coerce_numeric(value)
      if value.is_a?(Float)
        raise TypeError, "value must be finite." unless value.finite?
        value.to_f
      elsif value.is_a?(Integer)
        raise TypeError, "value must be a Float when allow_integer=false." unless @allow_integer
        value.to_f
      else
        raise TypeError, "value must be a numeric scalar."
      end
    end

    def linear_map(value, in_min, in_max, out_min, out_max)
      out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
    end

    def validate_range(min_value, max_value, label)
      unless max_value > min_value
        raise RangeError, "#{label} must be finite and strictly increasing."
      end
    end
  end

  class BooleanRangeMapper
    SPEC_VERSION = "1.0-alpha"

    def initialize(false_value = -1.0, true_value = 1.0)
      @false_value = require_finite_number(false_value, "false_value").to_f
      @true_value = require_finite_number(true_value, "true_value").to_f
    end

    def map_value(value)
      case value
      when true
        @true_value
      when false
        @false_value
      else
        raise TypeError, "value must be true or false."
      end
    end

    alias map map_value

    def spec
      {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "boolean_range",
        "false_value" => @false_value,
        "true_value" => @true_value
      }
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    def self.from_json(json_text)
      from_spec(JSON.parse(json_text))
    end

    def self.from_spec(data)
      raise ArgumentError, "unsupported spec_version #{data["spec_version"]}" unless data["spec_version"] == SPEC_VERSION
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "boolean_range"

      new(data.fetch("false_value", -1.0), data.fetch("true_value", 1.0))
    end

    private

    def require_finite_number(value, label)
      if value.is_a?(Integer)
        value
      elsif value.is_a?(Float) && value.finite?
        value
      else
        raise TypeError, "#{label} must be a finite number."
      end
    end
  end

  class TextRangeMapper
    SPEC_VERSION = "1.0-alpha"

    def initialize(output_min = -1.0, output_max = 1.0, mode = "codepoint", alphabet = nil, clip = false, allow_empty = false, name = nil)
      unless [true, false].include?(clip)
        raise TypeError, "clip must be a boolean."
      end
      unless [true, false].include?(allow_empty)
        raise TypeError, "allow_empty must be a boolean."
      end
      unless name.nil? || name.is_a?(String)
        raise TypeError, "name must be a string or nil."
      end
      unless mode.is_a?(String)
        raise TypeError, "mode must be a string."
      end
      unless ["codepoint", "alphabet", "byte"].include?(mode)
        raise ArgumentError, "mode must be one of 'codepoint', 'alphabet', or 'byte'."
      end

      @output_min = require_finite_number(output_min, "output_range[0]").to_f
      @output_max = require_finite_number(output_max, "output_range[1]").to_f
      validate_range(@output_min, @output_max, "output_range")
      @mode = mode
      @clip = clip
      @allow_empty = allow_empty
      @name = name

      case @mode
      when "codepoint"
        @input_range = [0, 0x10FFFF]
        @alphabet = nil
        @alphabet_index = nil
      when "alphabet"
        @alphabet = validate_alphabet(alphabet)
        @input_range = [0, @alphabet.length - 1]
        @alphabet_index = {}
        @alphabet.each_char.with_index do |char, index|
          if @alphabet_index.key?(char)
            raise ArgumentError, "alphabet must contain unique characters."
          end
          @alphabet_index[char] = index
        end
      when "byte"
        @input_range = [0, 255]
        @alphabet = nil
        @alphabet_index = nil
      end
    end

    def map_value(value)
      units =
        case @mode
        when "codepoint", "alphabet"
          coerce_string(value)
        when "byte"
          coerce_bytes(value)
        end

      if units.empty? && !@allow_empty
        raise RangeError, "empty text value is invalid by default; set allow_empty=true to map empty text."
      end

      case @mode
      when "codepoint"
        mapped = []
        units.each_codepoint.with_index do |codepoint, index|
          current = validate_codepoint(codepoint, index)
          mapped << linear_map(current, @input_range[0], @input_range[1], @output_min, @output_max)
        end
        mapped
      when "alphabet"
        mapped = []
        units.each_char.with_index do |char, index|
          current = @alphabet_index[char]
          raise KeyError, "unknown character #{char.inspect} for alphabet mode." if current.nil?
          mapped << linear_map(current, @input_range[0], @input_range[1], @output_min, @output_max)
        end
        mapped
      when "byte"
        mapped = []
        units.each_with_index do |byte, index|
          current = validate_byte(byte, index)
          mapped << linear_map(current, @input_range[0], @input_range[1], @output_min, @output_max)
        end
        mapped
      end
    end

    alias map map_value

    def spec
      data = {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "text_range",
        "mode" => @mode,
        "input_range" => @input_range.dup,
        "output_range" => [@output_min, @output_max],
        "clip" => @clip,
        "allow_empty" => @allow_empty
      }
      data["alphabet"] = @alphabet unless @alphabet.nil?
      data["name"] = @name unless @name.nil?
      data
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    def self.from_json(json_text)
      from_spec(JSON.parse(json_text))
    end

    def self.from_spec(data)
      raise ArgumentError, "unsupported spec_version #{data["spec_version"]}" unless data["spec_version"] == SPEC_VERSION
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "text_range"

      mode = data.fetch("mode")
      output_range = data.fetch("output_range")
      alphabet = data["alphabet"]

      raise ArgumentError, "mode must be one of 'codepoint', 'alphabet', or 'byte'" unless ["codepoint", "alphabet", "byte"].include?(mode)
      raise ArgumentError, "output_range must contain exactly two values" unless output_range.is_a?(Array) && output_range.length == 2

      if data.key?("input_range")
        input_range = data.fetch("input_range")
        expected_range =
          case mode
          when "codepoint"
            [0, 0x10FFFF]
          when "alphabet"
            raise ArgumentError, "alphabet is required for alphabet mode" unless alphabet.is_a?(String)
            [0, alphabet.length - 1]
          when "byte"
            [0, 255]
          end
        raise ArgumentError, "unsupported input_range #{input_range.inspect}" unless input_range == expected_range
      end

      new(
        output_range[0],
        output_range[1],
        mode,
        alphabet,
        data.fetch("clip", false),
        data.fetch("allow_empty", false),
        data["name"]
      )
    end

    private

    def require_finite_number(value, label)
      if value.is_a?(Integer)
        value
      elsif value.is_a?(Float) && value.finite?
        value
      else
        raise TypeError, "#{label} must be a finite number."
      end
    end

    def validate_range(min_value, max_value, label)
      unless max_value > min_value
        raise RangeError, "#{label} must be finite and strictly increasing."
      end
    end

    def validate_alphabet(alphabet)
      unless alphabet.is_a?(String)
        raise TypeError, "alphabet must be a non-empty string for alphabet mode."
      end
      if alphabet.empty?
        raise ArgumentError, "alphabet must not be empty."
      end
      if alphabet.each_char.uniq.length < 2
        raise ArgumentError, "alphabet mode requires at least 2 unique characters."
      end
      alphabet
    end

    def coerce_string(value)
      unless value.is_a?(String)
        raise TypeError, "value must be a String."
      end
      value
    end

    def coerce_bytes(value)
      return value.bytes if value.is_a?(String)
      return value if value.is_a?(Array)
      raise TypeError, "value must be a String or Integer array."
    end

    def validate_codepoint(value, index)
      unless value.is_a?(Integer)
        raise TypeError, "codepoints[#{index}] must be an integer."
      end
      if value < @input_range[0] || value > @input_range[1]
        if !@clip
          raise RangeError, "codepoint value #{value} is outside input_range; enable clip to clamp."
        end
        return [[value, @input_range[0]].max, @input_range[1]].min
      end
      value
    end

    def validate_byte(value, index)
      unless value.is_a?(Integer)
        raise TypeError, "bytes[#{index}] must be an integer."
      end
      if value < 0
        if !@clip
          raise RangeError, "byte value #{value} is below input_range lower bound 0; enable clip to clamp."
        end
        return 0
      end
      if value > 255
        if !@clip
          raise RangeError, "byte value #{value} is above input_range upper bound 255; enable clip to clamp."
        end
        return 255
      end
      value
    end

    def linear_map(value, in_min, in_max, out_min, out_max)
      out_min + ((value - in_min).to_f / (in_max - in_min).to_f) * (out_max - out_min)
    end
  end

  class BytesRangeMapper
    SPEC_VERSION = "1.0-alpha"

    def initialize(output_min = -1.0, output_max = 1.0, clip = false, allow_empty = false, name = nil)
      unless [true, false].include?(clip)
        raise TypeError, "clip must be a boolean."
      end
      unless [true, false].include?(allow_empty)
        raise TypeError, "allow_empty must be a boolean."
      end
      if !name.nil? && !name.is_a?(String)
        raise TypeError, "name must be a string or nil."
      end

      output_min = require_finite_number(output_min, "output_range[0]")
      output_max = require_finite_number(output_max, "output_range[1]")
      validate_output_range(output_min, output_max)

      @output_range = [output_min.to_f, output_max.to_f]
      @input_range = [0, 255]
      @clip = clip
      @allow_empty = allow_empty
      @name = name
    end

    def map_value(value)
      bytes = coerce_bytes(value)
      if bytes.empty? && !@allow_empty
        raise TypeError, "empty bytes value is invalid by default; set allow_empty=true to map empty bytes."
      end

      mapped = []
      bytes.each_with_index do |byte, index|
        current = validate_byte(byte, index)
        mapped << linear_map(current, @input_range[0], @input_range[1], @output_range[0], @output_range[1])
      end
      mapped
    end

    alias map map_value

    def spec
      data = {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "bytes_range",
        "input_range" => @input_range.dup,
        "output_range" => @output_range.dup,
        "clip" => @clip,
        "allow_empty" => @allow_empty,
      }
      data["name"] = @name unless @name.nil?
      data
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
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "bytes_range"

      output_range = data.fetch("output_range")
      raise ArgumentError, "output_range must contain exactly two values" unless output_range.is_a?(Array) && output_range.length == 2

      if data.key?("input_range")
        input_range = data.fetch("input_range")
        raise ArgumentError, "unsupported input_range #{input_range.inspect}" unless input_range == [0, 255]
      end

      new(
        output_range[0],
        output_range[1],
        data.fetch("clip", false),
        data.fetch("allow_empty", false),
        data["name"]
      )
    end

    def require_finite_number(value, label)
      raise TypeError, "#{label} must be a finite number." unless value.respond_to?(:finite?) && value.finite?
      value
    end

    private

    def coerce_bytes(value)
      return value.bytes if value.is_a?(String)
      return value if value.is_a?(Array)
      raise TypeError, "value must be a String or Integer array."
    end

    def validate_byte(value, index)
      unless value.is_a?(Integer)
        raise TypeError, "bytes[#{index}] must be an integer."
      end
      if value < 0
        if !@clip
          raise RangeError, "byte value #{value} is below input_range lower bound 0; enable clip to clamp."
        end
        return 0
      end
      if value > 255
        if !@clip
          raise RangeError, "byte value #{value} is above input_range upper bound 255; enable clip to clamp."
        end
        return 255
      end
      value
    end

    def linear_map(value, in_min, in_max, out_min, out_max)
      out_min + ((value - in_min).to_f / (in_max - in_min).to_f) * (out_max - out_min)
    end

    def validate_output_range(output_min, output_max)
      unless output_max > output_min
        raise RangeError, "output_range must be finite and strictly increasing."
      end
    end
  end

  class CategoricalRangeMapper
    SPEC_VERSION = "1.0-alpha"

    def initialize(vocabulary, output_min = -1.0, output_max = 1.0)
      unless vocabulary.is_a?(Array)
        raise TypeError, "vocabulary must be an array of JSON-serializable scalar tokens."
      end

      @vocabulary = vocabulary.map { |token| normalize_token(token) }
      raise ArgumentError, "vocabulary must not be empty." if @vocabulary.empty?

      @output_min = require_finite_number(output_min, "output_range[0]").to_f
      @output_max = require_finite_number(output_max, "output_range[1]").to_f
      validate_range(@output_min, @output_max, "output_range")

      @index_by_token = {}
      @vocabulary.each_with_index do |token, index|
        key = categorical_token_key(token)
        if @index_by_token.key?(key)
          raise ArgumentError, "duplicate vocabulary token #{describe_token(token)}"
        end
        @index_by_token[key] = index
      end
    end

    def map_value(value)
      token = normalize_token(value)
      index = @index_by_token[categorical_token_key(token)]
      raise KeyError, "unknown categorical token #{describe_token(value)}" if index.nil?

      map_index(index)
    end

    alias map map_value

    def spec
      {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "categorical_range",
        "vocabulary" => @vocabulary.map { |token| encode_spec_token(token) },
        "output_range" => [@output_min, @output_max]
      }
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    def self.from_json(json_text)
      from_spec(JSON.parse(json_text))
    end

    def self.from_spec(data)
      raise ArgumentError, "unsupported spec_version #{data["spec_version"]}" unless data["spec_version"] == SPEC_VERSION
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "categorical_range"

      vocabulary = data.fetch("vocabulary")
      output_range = data.fetch("output_range")

      raise ArgumentError, "vocabulary must contain at least one token" unless vocabulary.is_a?(Array) && !vocabulary.empty?
      raise ArgumentError, "output_range must contain exactly two values" unless output_range.is_a?(Array) && output_range.length == 2

      new(
        vocabulary.map { |entry| decode_spec_token(entry) },
        output_range[0],
        output_range[1]
      )
    end

    private

    def require_finite_number(value, label)
      if value.is_a?(Integer)
        value
      elsif value.is_a?(Float) && value.finite?
        value
      else
        raise TypeError, "#{label} must be a finite number."
      end
    end

    def validate_range(min_value, max_value, label)
      unless max_value > min_value
        raise RangeError, "#{label} must be finite and strictly increasing."
      end
    end

    def normalize_token(token)
      case token
      when String
        token
      when Integer
        token
      when Float
        raise TypeError, "categorical tokens must be finite." unless token.finite?
        token
      when true, false, nil
        token
      else
        raise TypeError, "categorical tokens must be JSON-serializable scalar values."
      end
    end

    def categorical_token_key(token)
      case token
      when String
        ["string", token]
      when Integer
        ["integer", token]
      when Float
        ["float", token]
      when true
        ["boolean", true]
      when false
        ["boolean", false]
      when nil
        ["null", nil]
      end
    end

    def encode_spec_token(token)
      case token
      when String
        { "token_type" => "string", "token_value" => token }
      when Integer
        { "token_type" => "integer", "token_value" => token }
      when Float
        { "token_type" => "float", "token_value" => token }
      when true
        { "token_type" => "boolean", "token_value" => true }
      when false
        { "token_type" => "boolean", "token_value" => false }
      when nil
        { "token_type" => "null", "token_value" => nil }
      else
        raise TypeError, "categorical tokens must be JSON-serializable scalar values."
      end
    end

    def decode_spec_token(entry)
      unless entry.is_a?(Hash)
        raise TypeError, "vocabulary entries must be tagged JSON objects."
      end

      token_type = entry.fetch("token_type")
      token_value = entry.fetch("token_value")

      case token_type
      when "string"
        raise TypeError, "string token_value must be a String." unless token_value.is_a?(String)
        token_value
      when "integer"
        raise TypeError, "integer token_value must be an Integer." unless token_value.is_a?(Integer)
        token_value
      when "float"
        raise TypeError, "float token_value must be finite." unless token_value.is_a?(Float) && token_value.finite?
        token_value
      when "boolean"
        raise TypeError, "boolean token_value must be true or false." unless token_value == true || token_value == false
        token_value
      when "null"
        raise TypeError, "null token_value must be nil." unless token_value.nil?
        nil
      else
        raise TypeError, "unsupported categorical token_type #{token_type.inspect}"
      end
    end

    def map_index(index)
      if @vocabulary.length == 1
        return (@output_min + @output_max) / 2.0
      end

      @output_min + (index.to_f / (@vocabulary.length - 1)) * (@output_max - @output_min)
    end

    def describe_token(token)
      token.inspect
    end
  end

  class ObjectRangeMapper
    SPEC_VERSION = "1.0-alpha"
    NO_MISSING_VALUE = Object.new

    def initialize(schema, allow_unknown = false, allow_empty = false, missing_value = NO_MISSING_VALUE, name = nil)
      @schema = normalize_schema(schema)
      unless [true, false].include?(allow_unknown)
        raise TypeError, "allow_unknown must be a boolean."
      end
      unless [true, false].include?(allow_empty)
        raise TypeError, "allow_empty must be a boolean."
      end
      if !name.nil? && !name.is_a?(String)
        raise TypeError, "name must be a string or nil."
      end

      @allow_unknown = allow_unknown
      @allow_empty = allow_empty
      @missing_value = missing_value
      @has_missing_value = !missing_value.equal?(NO_MISSING_VALUE)
      @name = name

      if @schema.empty? && !@allow_empty
        raise TypeError, "schema must contain at least one field unless allow_empty=true."
      end
    end

    def map_value(value)
      unless value.is_a?(Hash)
        raise TypeError, "value must be a hash."
      end

      normalized_input = {}
      value.each do |field_name, field_value|
        field_key = normalize_field_name(field_name)
        if normalized_input.key?(field_key)
          raise TypeError, "object value contains duplicate key #{field_key.inspect} with conflicting types."
        end
        normalized_input[field_key] = field_value
      end

      if normalized_input.empty? && !@allow_empty
        raise RangeError, "empty object input is invalid by default; set allow_empty=true to map empty objects."
      end

      unless @allow_unknown
        normalized_input.each_key do |field_name|
          unless @schema.key?(field_name)
            raise TypeError, "object map has unknown fields; set allow_unknown=true to accept extras."
          end
        end
      end

      mapped = {}
      @schema.each do |field_name, mapper|
        unless normalized_input.key?(field_name)
          if @has_missing_value
            mapped[field_name] = @missing_value
            next
          end
          raise KeyError, "missing required field #{field_name.inspect} in object input."
        end
        mapped[field_name] = mapper.map_value(normalized_input[field_name])
      end
      mapped
    end

    alias map map_value

    def spec
      {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "object_range",
        "schema" => build_schema_spec(@schema),
        "allow_unknown" => @allow_unknown,
        "allow_empty" => @allow_empty
      }.tap do |data|
        if @has_missing_value
          data["has_missing_value"] = true
          data["missing_value"] = parse_json_scalar(@missing_value)
        end
        data["name"] = @name unless @name.nil?
      end
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    def self.from_json(json_text)
      from_spec(JSON.parse(json_text))
    end

    def self.from_spec(data)
      raise ArgumentError, "unsupported spec_version #{data["spec_version"]}" unless data["spec_version"] == SPEC_VERSION
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "object_range"
      raise TypeError, "schema must be a non-empty object mapping field names to mapper specs." unless data["schema"].is_a?(Hash)
      if data["schema"].empty? && !data["allow_empty"]
        raise ArgumentError, "schema must contain at least one field unless allow_empty=true."
      end

        schema = {}
      data["schema"].each do |field_name, entry|
        schema[field_name.to_s] = ObjectRangeMapper.parse_mapper_spec(entry)
      end

      new(
        schema,
        !!data.fetch("allow_unknown", false),
        !!data.fetch("allow_empty", false),
        (data["has_missing_value"] ? data.fetch("missing_value") : NO_MISSING_VALUE),
        data["name"]
      )
    end

    private

    def normalize_schema(schema)
      unless schema.is_a?(Hash)
        raise TypeError, "schema must be a hash."
      end

      normalized = {}
      schema.each do |field_name, mapper|
        key = normalize_field_name(field_name)
        if normalized.key?(key)
          raise TypeError, "schema has duplicate field #{key.inspect}."
        end
        unless mapper.respond_to?(:map_value)
          raise TypeError, "schema value for #{key.inspect} must have map_value()."
        end
        normalized[key] = mapper
      end
      normalized
    end

    def normalize_field_name(value)
      unless value.is_a?(String) || value.is_a?(Symbol)
        raise TypeError, "schema field names must be strings or symbols."
      end

      value.to_s
    end

    def build_schema_spec(schema)
      output = {}
      schema.each do |field_name, mapper|
        output[field_name] = JSON.parse(mapper.to_json)
      end
      output
    end

    def parse_json_scalar(value)
      JSON.generate(value)
      value
    rescue JSON::GeneratorError => error
      raise TypeError, "missing_value must be JSON-serializable: #{error.message}"
    end

    def self.parse_mapper_spec(entry)
      unless entry.is_a?(Hash) && !entry.empty?
        raise TypeError, "schema entry must be a mapper spec object."
      end

      case entry["mapper_type"]
      when "integer_range"
        IntegerRangeMapper.from_spec(entry)
      when "float_range"
        FloatRangeMapper.from_spec(entry)
      when "boolean_range"
        BooleanRangeMapper.from_spec(entry)
      when "text_range"
        TextRangeMapper.from_spec(entry)
      when "bytes_range"
        BytesRangeMapper.from_spec(entry)
      when "categorical_range"
        CategoricalRangeMapper.from_spec(entry)
      when "temporal_range"
        TemporalRangeMapper.from_spec(entry)
      when "object_range"
        ObjectRangeMapper.from_spec(entry)
      else
        raise TypeError, "unsupported mapper_type #{entry["mapper_type"]} in object schema."
      end
    end
  end

  class TemporalRangeMapper
    SPEC_VERSION = "1.0-alpha"

    def initialize(input_min, input_max, output_min = -1.0, output_max = 1.0, clip = false)
      unless [true, false].include?(clip)
        raise TypeError, "clip must be a boolean."
      end

      @input_min = require_finite_number(input_min, "input_range[0]").to_f
      @input_max = require_finite_number(input_max, "input_range[1]").to_f
      @output_min = require_finite_number(output_min, "output_range[0]").to_f
      @output_max = require_finite_number(output_max, "output_range[1]").to_f
      validate_range(@input_min, @input_max, "input_range")
      validate_range(@output_min, @output_max, "output_range")
      @clip = clip
    end

    def map_value(value)
      current = coerce_temporal(value)
      if current < @input_min || current > @input_max
        if @clip
          current = [[current, @input_min].max, @input_max].min
        else
          raise RangeError, "value out of range"
        end
      end
      linear_map(current, @input_min, @input_max, @output_min, @output_max)
    end

    alias map map_value

    def spec
      {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "temporal_range",
        "input_range" => [@input_min, @input_max],
        "output_range" => [@output_min, @output_max],
        "clip" => @clip
      }
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    def self.from_json(json_text)
      from_spec(JSON.parse(json_text))
    end

    def self.from_spec(data)
      raise ArgumentError, "unsupported spec_version #{data["spec_version"]}" unless data["spec_version"] == SPEC_VERSION
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "temporal_range"

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

    def require_finite_number(value, label)
      if value.is_a?(Integer)
        value
      elsif value.is_a?(Float) && value.finite?
        value
      else
        raise TypeError, "#{label} must be a finite number."
      end
    end

    def coerce_temporal(value)
      if value.is_a?(Time)
        value.to_f
      elsif value.is_a?(DateTime)
        value.strftime("%s").to_f + value.sec_fraction.to_r.to_f
      elsif value.is_a?(Integer)
        value.to_f
      elsif value.is_a?(Float)
        raise TypeError, "value must be finite." unless value.finite?
        value
      else
        raise TypeError, "value must be a Time, DateTime, or numeric timestamp."
      end
    end

    def linear_map(value, in_min, in_max, out_min, out_max)
      out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
    end

    def validate_range(min_value, max_value, label)
      unless max_value > min_value
        raise RangeError, "#{label} must be finite and strictly increasing."
      end
    end
  end

  class SequenceRangeMapper
    SPEC_VERSION = "1.0-alpha"

    def initialize(element_mapper, allow_empty = false, name = nil)
      unless element_mapper.respond_to?(:call)
        raise TypeError, "element_mapper must respond to call."
      end
      unless [true, false].include?(allow_empty)
        raise TypeError, "allow_empty must be a boolean."
      end
      if !name.nil? && !name.is_a?(String)
        raise TypeError, "name must be a string or nil."
      end

      @element_mapper = element_mapper
      @allow_empty = allow_empty
      @name = name
    end

    def map_value(values)
      unless values.is_a?(Array)
        raise TypeError, "values must be an array."
      end
      if values.empty? && !@allow_empty
        raise RangeError, "empty sequence input is invalid by default."
      end

      values.map do |value|
        if value.is_a?(Array)
          map_value(value)
        else
          @element_mapper.call(value)
        end
      end
    end

    alias map map_value

    def spec
      {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "sequence_range",
        "allow_empty" => @allow_empty,
      }
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    private

    attr_reader :name
  end

  class ImageRangeMapper
    SPEC_VERSION = "1.0-alpha"

    def initialize(output_min = -1.0, output_max = 1.0, clip = false, allow_empty = false, mode = "auto", name = nil)
      unless [true, false].include?(clip)
        raise TypeError, "clip must be a boolean."
      end
      unless [true, false].include?(allow_empty)
        raise TypeError, "allow_empty must be a boolean."
      end
      if !name.nil? && !name.is_a?(String)
        raise TypeError, "name must be a string or nil."
      end
      unless ["auto", "rgb", "rgba"].include?(mode)
        raise ArgumentError, "mode must be one of \"auto\", \"rgb\", or \"rgba\"."
      end

      @output_min = require_finite_number(output_min, "output_range[0]").to_f
      @output_max = require_finite_number(output_max, "output_range[1]").to_f
      validate_range(@output_min, @output_max, "output_range")
      @clip = clip
      @allow_empty = allow_empty
      @mode = mode
      @input_range = [0, 255]
      @name = name
    end

    def map_value(image)
      unless image.is_a?(Array)
        raise TypeError, "image-like values must be arrays."
      end
      if image.empty? && !@allow_empty
        raise TypeError, "empty image is invalid by default; set allow_empty=true to map empty image inputs."
      end

      map_image(image)
    end

    alias map map_value

    def spec
      {
        "spec_version" => SPEC_VERSION,
        "mapper_type" => "image_range",
        "input_range" => @input_range.dup,
        "output_range" => [@output_min, @output_max],
        "clip" => @clip,
        "allow_empty" => @allow_empty,
        "mode" => @mode
      }.tap do |data|
        data["name"] = @name unless @name.nil?
      end
    end

    def to_json(*_args)
      JSON.generate(spec)
    end

    def self.from_json(json_text)
      from_spec(JSON.parse(json_text))
    end

    def self.from_spec(data)
      raise ArgumentError, "unsupported spec_version #{data["spec_version"]}" unless data["spec_version"] == SPEC_VERSION
      raise ArgumentError, "unsupported mapper_type #{data["mapper_type"]}" unless data["mapper_type"] == "image_range"

      if data.key?("input_range")
        input_range = data.fetch("input_range")
        raise ArgumentError, "unsupported input_range #{input_range.inspect}" unless input_range == [0, 255]
      end

      output_range = data.fetch("output_range")
      unless output_range.is_a?(Array) && output_range.length == 2
        raise ArgumentError, "output_range must contain exactly two values"
      end

      new(
        output_range[0],
        output_range[1],
        data.fetch("clip", false),
        data.fetch("allow_empty", false),
        data.fetch("mode", "auto"),
        data["name"]
      )
    end

    private

    def map_image(value)
      if value.is_a?(Array)
        if value.empty?
          return []
        end
        if mode_is_pixel?(value)
          return value.map { |channel| validate_and_map_channel(channel) }
        end
        return value.map { |entry| map_image(entry) }
      end
      raise TypeError, "image-like values must be arrays of numeric pixels."
    end

    def mode_is_pixel?(values)
      return false unless values.is_a?(Array)
      return false if values.empty?
      return false unless values.all? { |value| value.is_a?(Integer) }
      return false if @mode == "rgb" && values.length != 3
      return false if @mode == "rgba" && values.length != 4
      true
    end

    def validate_and_map_channel(channel)
      unless channel.is_a?(Integer)
        raise TypeError, "image channels must be integer byte values."
      end
      if channel < 0
        if !@clip
          raise TypeError, "image channel #{channel} is below 0; enable clip to clamp."
        end
        return @output_min
      end
      if channel > 255
        if !@clip
          raise TypeError, "image channel #{channel} is above 255; enable clip to clamp."
        end
        return @output_max
      end
      @output_min + ((channel - @input_range[0]).to_f / (@input_range[1] - @input_range[0])) * (@output_max - @output_min)
    end

    def require_finite_number(value, label)
      if value.is_a?(Integer)
        value
      elsif value.is_a?(Float) && value.finite?
        value
      else
        raise TypeError, "#{label} must be a finite number."
      end
    end

    def validate_range(min_value, max_value, label)
      unless max_value > min_value
        raise RangeError, "#{label} must be finite and strictly increasing."
      end
    end
  end

end
