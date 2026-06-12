using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class SequenceRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "sequence_range";

    private readonly IntegerRangeMapper? _integerMapper;
    private readonly FloatRangeMapper? _floatMapper;
    private readonly BooleanRangeMapper? _booleanMapper;
    private readonly BytesRangeMapper? _bytesMapper;
    private readonly CategoricalRangeMapper? _categoricalMapper;

    public string ElementMapperType { get; }
    public bool AllowEmpty { get; }
    public string? Name { get; }

    public SequenceRangeMapper(IntegerRangeMapper elementMapper, bool allowEmpty = false, string? name = null)
    {
        _integerMapper = elementMapper ?? throw new ArgumentNullException(nameof(elementMapper));
        ElementMapperType = "integer_range";
        AllowEmpty = allowEmpty;
        Name = NormalizeName(name);
    }

    public SequenceRangeMapper(FloatRangeMapper elementMapper, bool allowEmpty = false, string? name = null)
    {
        _floatMapper = elementMapper ?? throw new ArgumentNullException(nameof(elementMapper));
        ElementMapperType = "float_range";
        AllowEmpty = allowEmpty;
        Name = NormalizeName(name);
    }

    public SequenceRangeMapper(BooleanRangeMapper elementMapper, bool allowEmpty = false, string? name = null)
    {
        _booleanMapper = elementMapper ?? throw new ArgumentNullException(nameof(elementMapper));
        ElementMapperType = "boolean_range";
        AllowEmpty = allowEmpty;
        Name = NormalizeName(name);
    }

    public SequenceRangeMapper(BytesRangeMapper elementMapper, bool allowEmpty = false, string? name = null)
    {
        _bytesMapper = elementMapper ?? throw new ArgumentNullException(nameof(elementMapper));
        ElementMapperType = "bytes_range";
        AllowEmpty = allowEmpty;
        Name = NormalizeName(name);
    }

    public SequenceRangeMapper(CategoricalRangeMapper elementMapper, bool allowEmpty = false, string? name = null)
    {
        _categoricalMapper = elementMapper ?? throw new ArgumentNullException(nameof(elementMapper));
        ElementMapperType = "categorical_range";
        AllowEmpty = allowEmpty;
        Name = NormalizeName(name);
    }

    public double[] MapValues(IEnumerable<long> values)
    {
        EnsureIntegerMapper();
        if (values is null)
        {
            throw new ArgumentNullException(nameof(values), "sequence payload must not be null.");
        }

        if (!AllowEmpty && !values.Any())
        {
            throw new ArgumentException("sequence payload must not be empty unless allow_empty is true.");
        }

        return MapValues(values, value => _integerMapper!.MapValue(value));
    }

    public double[] MapValues(IEnumerable<double> values)
    {
        EnsureFloatMapper();
        if (values is null)
        {
            throw new ArgumentNullException(nameof(values), "sequence payload must not be null.");
        }

        if (!AllowEmpty && !values.Any())
        {
            throw new ArgumentException("sequence payload must not be empty unless allow_empty is true.");
        }

        return MapValues(values, value => _floatMapper!.MapValue(value));
    }

    public double[] MapValues(IEnumerable<bool> values)
    {
        EnsureBooleanMapper();
        if (values is null)
        {
            throw new ArgumentNullException(nameof(values), "sequence payload must not be null.");
        }

        if (!AllowEmpty && !values.Any())
        {
            throw new ArgumentException("sequence payload must not be empty unless allow_empty is true.");
        }

        return MapValues(values, value => _booleanMapper!.MapValue(value));
    }

    public double[] MapValues(IEnumerable<byte> values)
    {
        EnsureBytesMapper();
        if (values is null)
        {
            throw new ArgumentNullException(nameof(values), "sequence payload must not be null.");
        }

        if (!AllowEmpty && !values.Any())
        {
            throw new ArgumentException("sequence payload must not be empty unless allow_empty is true.");
        }

        return MapValues(values, value => _bytesMapper!.MapValue(value));
    }

    public double[] MapValues(IEnumerable<object?> values)
    {
        EnsureCategoricalMapper();
        if (values is null)
        {
            throw new ArgumentNullException(nameof(values), "sequence payload must not be null.");
        }

        if (!AllowEmpty && !values.Any())
        {
            throw new ArgumentException("sequence payload must not be empty unless allow_empty is true.");
        }

        return MapValues(values, value => _categoricalMapper!.MapValue(value));
    }

    public object MapNested(object value)
    {
        return MapNestedRecursive(value);
    }

    public object Map(IEnumerable value)
    {
        return MapNested(value);
    }

    public string ToJson()
    {
        return JsonSerializer.Serialize(ToSpec(), JsonOptions);
    }

    public static SequenceRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<SequenceMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static SequenceRangeMapper FromSpec(SequenceMapperSpec spec)
    {
        if (spec.SpecVersion != SpecVersion)
        {
            throw new ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", nameof(spec));
        }
        if (spec.MapperType != SpecType)
        {
            throw new ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", nameof(spec));
        }
        if (spec.ElementMapperType is null)
        {
            throw new ArgumentException("element_mapper_type is required.", nameof(spec));
        }
        if (spec.ElementMapperSpec is null)
        {
            throw new ArgumentException("element_mapper_spec is required.", nameof(spec));
        }

        return spec.ElementMapperType switch
        {
            "integer_range" => new SequenceRangeMapper(IntegerRangeMapper.FromJson(spec.ElementMapperSpec.Value.GetRawText()), spec.AllowEmpty, spec.Name),
            "float_range" => new SequenceRangeMapper(FloatRangeMapper.FromJson(spec.ElementMapperSpec.Value.GetRawText()), spec.AllowEmpty, spec.Name),
            "boolean_range" => new SequenceRangeMapper(BooleanRangeMapper.FromJson(spec.ElementMapperSpec.Value.GetRawText()), spec.AllowEmpty, spec.Name),
            "bytes_range" => new SequenceRangeMapper(BytesRangeMapper.FromJson(spec.ElementMapperSpec.Value.GetRawText()), spec.AllowEmpty, spec.Name),
            "categorical_range" => new SequenceRangeMapper(CategoricalRangeMapper.FromJson(spec.ElementMapperSpec.Value.GetRawText()), spec.AllowEmpty, spec.Name),
            _ => throw new ArgumentException($"unsupported element_mapper_type '{spec.ElementMapperType}'.", nameof(spec))
        };
    }

    private object MapNestedRecursive(object value)
    {
        if (value is null)
        {
            throw new ArgumentNullException(nameof(value), "sequence payload must not be null.");
        }

        if (value is string)
        {
            throw new ArgumentException("string payload is not supported for sequence mapping. use text mapper or bytes mapping.");
        }

        if (IsScalarValue(value))
        {
            return MapScalar(value);
        }

        if (value is IDictionary)
        {
            throw new ArgumentException("dict-like values are not supported for sequence mapping. Use map/object family.");
        }

        if (value is IEnumerable enumerable)
        {
            return MapSequence(enumerable);
        }

        throw new InvalidOperationException($"unsupported value type '{value.GetType().FullName}'.");
    }

    private object MapSequence(IEnumerable sequence)
    {
        var mapped = new List<object>();
        foreach (var item in sequence)
        {
            mapped.Add(MapNestedRecursive(item));
        }

        if (mapped.Count == 0 && !AllowEmpty)
        {
            throw new ArgumentException("sequence payload must not be empty unless allow_empty is true.");
        }

        return mapped.ToArray();
    }

    private double MapScalar(object value)
    {
        return ElementMapperType switch
        {
            "integer_range" => _integerMapper!.MapValue(ConvertToLong(value)),
            "float_range" => _floatMapper!.MapValue(ConvertToDouble(value)),
            "boolean_range" => _booleanMapper!.MapValue(ConvertToBoolean(value)),
            "bytes_range" => _bytesMapper!.MapValue(ConvertToByte(value)),
            "categorical_range" => _categoricalMapper!.MapValue(value),
            _ => throw new InvalidOperationException($"invalid sequence element mapper '{ElementMapperType}'.")
        };
    }

    private static double[] MapValues<T>(IEnumerable<T> values, Func<T, double> mapValue)
    {
        return values.Select(mapValue).ToArray();
    }

    private static long ConvertToLong(object value)
    {
        return value switch
        {
            sbyte v => v,
            byte v => v,
            short v => v,
            ushort v => v,
            int v => v,
            uint v => checked((long)v),
            long v => v,
            ulong v => checked((long)v),
            _ => throw new ArgumentException("integer sequence expects integer values only.")
        };
    }

    private static double ConvertToDouble(object value)
    {
        return value switch
        {
            float v => v,
            double v => v,
            decimal v => (double)v,
            _ => throw new ArgumentException("float sequence expects float values only.")
        };
    }

    private static bool ConvertToBoolean(object value)
    {
        return value switch
        {
            bool v => v,
            _ => throw new ArgumentException("boolean sequence expects bool values only.")
        };
    }

    private static long ConvertToByte(object value)
    {
        return value is byte v
            ? v
            : throw new ArgumentException("bytes sequence expects byte values only.");
    }

    private static bool IsScalarValue(object value) =>
        value switch
        {
            string or byte[] => false,
            char or bool or sbyte or byte or short or ushort or int or uint or long or ulong or float or double or decimal => true,
            null => false,
            _ => value is not IEnumerable
        };

    private SequenceMapperSpec ToSpec()
    {
        var elementSpec = ElementMapperType switch
        {
            "integer_range" => _integerMapper!.ToJson(),
            "float_range" => _floatMapper!.ToJson(),
            "boolean_range" => _booleanMapper!.ToJson(),
            "bytes_range" => _bytesMapper!.ToJson(),
            "categorical_range" => _categoricalMapper!.ToJson(),
            _ => throw new InvalidOperationException($"invalid element mapper '{ElementMapperType}'.")
        };

        if (elementSpec is not string elementSpecJson)
        {
            throw new InvalidOperationException("Unable to serialize element mapper.");
        }

        return new SequenceMapperSpec
        {
            SpecVersion = SpecVersion,
            MapperType = SpecType,
            ElementMapperType = ElementMapperType,
            ElementMapperSpec = JsonDocument.Parse(elementSpecJson).RootElement.Clone(),
            AllowEmpty = AllowEmpty,
            Name = Name
        };
    }

    private static string? NormalizeName(string? name)
    {
        if (name is not null && name.Length == 0)
        {
            throw new ArgumentException("name must not be empty.", nameof(name));
        }

        return name;
    }

    private void EnsureIntegerMapper()
    {
        if (_integerMapper is null)
        {
            throw new InvalidOperationException("sequence mapper is not configured for integer values.");
        }
    }

    private void EnsureFloatMapper()
    {
        if (_floatMapper is null)
        {
            throw new InvalidOperationException("sequence mapper is not configured for float values.");
        }
    }

    private void EnsureBooleanMapper()
    {
        if (_booleanMapper is null)
        {
            throw new InvalidOperationException("sequence mapper is not configured for boolean values.");
        }
    }

    private void EnsureBytesMapper()
    {
        if (_bytesMapper is null)
        {
            throw new InvalidOperationException("sequence mapper is not configured for bytes values.");
        }
    }

    private void EnsureCategoricalMapper()
    {
        if (_categoricalMapper is null)
        {
            throw new InvalidOperationException("sequence mapper is not configured for categorical values.");
        }
    }
}

public sealed class SequenceMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "sequence_range";

    [JsonPropertyName("element_mapper_type")]
    public string? ElementMapperType { get; init; }

    [JsonPropertyName("element_mapper_spec")]
    public JsonElement? ElementMapperSpec { get; init; }

    [JsonPropertyName("allow_empty")]
    public bool AllowEmpty { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }
}
