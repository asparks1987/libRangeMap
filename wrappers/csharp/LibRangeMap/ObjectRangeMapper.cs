using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class ObjectRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "map_range";

    private readonly Dictionary<string, object> _schema;
    private readonly object? _missingValue;
    private readonly bool _hasMissingValue;

    public bool AllowUnknown { get; }
    public bool AllowEmpty { get; }
    public string? Name { get; }

    public ObjectRangeMapper(
        IDictionary<string, object> schema,
        bool allowUnknown = false,
        bool allowEmpty = false,
        string? name = null,
        bool hasMissingValue = false,
        object? missingValue = null)
    {
        if (schema is null)
        {
            throw new ArgumentNullException(nameof(schema), "schema payload must not be null.");
        }

        _schema = ValidateSchema(schema);
        if (!allowEmpty && _schema.Count == 0)
        {
            throw new ArgumentException("schema must include at least one field.", nameof(schema));
        }

        if (name is not null && name.Length == 0)
        {
            throw new ArgumentException("name must not be empty.", nameof(name));
        }

        if (hasMissingValue)
        {
            _missingValue = missingValue;
        }

        AllowUnknown = allowUnknown;
        AllowEmpty = allowEmpty;
        Name = name;
        _hasMissingValue = hasMissingValue;
    }

    public IReadOnlyDictionary<string, object> Schema => _schema;

    public object? MissingValue => _missingValue;

    public bool HasMissingValue => _hasMissingValue;

    public Dictionary<string, object?> Map(object value)
    {
        if (value is null)
        {
            throw new ArgumentNullException(nameof(value), "map payload must not be null.");
        }

        if (value is IDictionary dict)
        {
            return MapDictionary(dict);
        }

        return MapObject(value);
    }

    public string ToJson()
    {
        return JsonSerializer.Serialize(ToSpec(), JsonOptions);
    }

    public static ObjectRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<ObjectMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static ObjectRangeMapper FromSpec(ObjectMapperSpec spec)
    {
        if (spec.SpecVersion != SpecVersion)
        {
            throw new ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", nameof(spec));
        }

        if (spec.MapperType != SpecType)
        {
            throw new ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", nameof(spec));
        }

        if (spec.Schema is null)
        {
            throw new ArgumentException("schema is required for map mapper.", nameof(spec));
        }

        var schema = new Dictionary<string, object>(spec.Schema.Count, StringComparer.Ordinal);
        foreach (var kvp in spec.Schema)
        {
            if (string.IsNullOrWhiteSpace(kvp.Key))
            {
                throw new ArgumentException("schema field names must be non-empty.");
            }

            schema[kvp.Key] = MapperFromSpecElement(kvp.Value);
        }

        var hasMissingValue = spec.HasMissingValue;
        object? missingValue = null;
        if (hasMissingValue)
        {
            if (spec.MissingValue is JsonElement element)
            {
                missingValue = JsonElementToObject(element);
            }
        }

        return new ObjectRangeMapper(
            schema,
            spec.AllowUnknown,
            spec.AllowEmpty,
            spec.Name,
            hasMissingValue,
            missingValue);
    }

    private Dictionary<string, object?> MapDictionary(IDictionary dict)
    {
        var mapped = new Dictionary<string, object?>(StringComparer.Ordinal);
        var input = new Dictionary<string, object?>(StringComparer.Ordinal);

        foreach (DictionaryEntry item in dict)
        {
            if (item.Key is not string key || key.Length == 0)
            {
                throw new InvalidOperationException("map keys must be non-empty strings.");
            }

            input[key] = item.Value;
        }

        if (input.Count == 0 && !AllowEmpty)
        {
            throw new ArgumentException("map payload must not be empty unless allow_empty is true.");
        }

        var unknownKeys = input.Keys.Where(k => !_schema.ContainsKey(k)).ToArray();
        if (!AllowUnknown && unknownKeys.Length > 0)
        {
            throw new ArgumentException(
                $"unknown schema fields: {string.Join(\", \", unknownKeys)}; set allowUnknown=true to ignore extra fields.");
        }

        foreach (var (fieldName, mapper) in _schema)
        {
            if (input.TryGetValue(fieldName, out var fieldValue))
            {
                mapped[fieldName] = MapField(mapper, fieldName, fieldValue);
            }
            else if (_hasMissingValue)
            {
                mapped[fieldName] = _missingValue;
            }
            else
            {
                throw new KeyNotFoundException($"missing required field '{fieldName}' in map input.");
            }
        }

        return mapped;
    }

    private Dictionary<string, object?> MapObject(object value)
    {
        var type = value.GetType();
        var mapped = new Dictionary<string, object?>(StringComparer.Ordinal);
        var foundAtLeastOne = false;
        if (!AllowUnknown)
        {
            var memberNames = ReadableMemberNames(type);
            var unexpected = memberNames.Where(fieldName => !_schema.ContainsKey(fieldName)).ToArray();
            if (unexpected.Length > 0)
            {
                throw new ArgumentException(
                    $"map object has unknown fields: {string.Join(\", \", unexpected)}; set allowUnknown=true to accept extras.");
            }
        }

        foreach (var (fieldName, mapper) in _schema)
        {
            if (TryGetObjectMember(value, type, fieldName, out var fieldValue))
            {
                foundAtLeastOne = true;
                mapped[fieldName] = MapField(mapper, fieldName, fieldValue);
            }
            else if (_hasMissingValue)
            {
                mapped[fieldName] = _missingValue;
            }
            else
            {
                throw new KeyNotFoundException($"missing required field '{fieldName}' in object input.");
            }
        }

        if (!foundAtLeastOne && !AllowEmpty)
        {
            throw new ArgumentException("map payload must not be empty unless allow_empty is true.");
        }

        return mapped;
    }

    private static IEnumerable<string> ReadableMemberNames(Type type)
    {
        foreach (var property in type.GetProperties(BindingFlags.Instance | BindingFlags.Public))
        {
            if (property.GetMethod is not null && property.GetIndexParameters().Length == 0)
            {
                yield return property.Name;
            }
        }

        foreach (var field in type.GetFields(BindingFlags.Instance | BindingFlags.Public))
        {
            yield return field.Name;
        }
    }

    private static bool TryGetObjectMember(object value, Type type, string fieldName, out object? fieldValue)
    {
        var property = type.GetProperty(fieldName, BindingFlags.Instance | BindingFlags.Public);
        if (property is not null)
        {
            if (property.GetMethod is null)
            {
                fieldValue = null;
                return false;
            }

            fieldValue = property.GetValue(value);
            return true;
        }

        var field = type.GetField(fieldName, BindingFlags.Instance | BindingFlags.Public);
        if (field is not null)
        {
            fieldValue = field.GetValue(value);
            return true;
        }

        fieldValue = null;
        return false;
    }

    private object MapField(object mapper, string fieldName, object? value)
    {
        return mapper switch
        {
            IntegerRangeMapper integerMapper => integerMapper.MapValue(ConvertToLong(value, fieldName)),
            FloatRangeMapper floatMapper => floatMapper.MapValue(ConvertToDouble(value, fieldName)),
            BooleanRangeMapper booleanMapper => booleanMapper.MapValue(ConvertToBoolean(value, fieldName)),
            BytesRangeMapper bytesMapper => bytesMapper.MapValue(ConvertToByte(value, fieldName)),
            CategoricalRangeMapper categoricalMapper => categoricalMapper.MapValue(value),
            TextRangeMapper textMapper => textMapper.MapValue(ConvertToChar(value, fieldName)),
            SequenceRangeMapper sequenceMapper => sequenceMapper.Map(value),
            ObjectRangeMapper objectMapper => objectMapper.Map(value),
            _ => throw new ArgumentException(
                $"schema field '{fieldName}' must provide a supported mapper type with map methods.")
        };
    }

    private static long ConvertToLong(object? value, string fieldName)
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
            _ => throw new ArgumentException($"field '{fieldName}' expects integer values only.")
        };
    }

    private static double ConvertToDouble(object? value, string fieldName)
    {
        return value switch
        {
            float v => v,
            double v => v,
            decimal v => (double)v,
            _ => throw new ArgumentException($"field '{fieldName}' expects float values only.")
        };
    }

    private static bool ConvertToBoolean(object? value, string fieldName)
    {
        return value is bool v
            ? v
            : throw new ArgumentException($"field '{fieldName}' expects boolean values only.");
    }

    private static long ConvertToByte(object? value, string fieldName)
    {
        return value is byte v
            ? v
            : throw new ArgumentException($"field '{fieldName}' expects byte values only.");
    }

    private static char ConvertToChar(object? value, string fieldName)
    {
        if (value is char v)
        {
            return v;
        }

        if (value is string text && text.Length == 1)
        {
            return text[0];
        }

        throw new ArgumentException($"field '{fieldName}' expects a single character.");
    }

    private static object MapperFromSpecElement(JsonElement specElement)
    {
        if (specElement.ValueKind != JsonValueKind.Object)
        {
            throw new InvalidOperationException("schema values must be mapper spec objects.");
        }

        if (!specElement.TryGetProperty("mapper_type", out var mapperTypeElement) ||
            mapperTypeElement.ValueKind != JsonValueKind.String)
        {
            throw new InvalidOperationException("schema values require a mapper_type.");
        }

        var mapperType = mapperTypeElement.GetString();

        return mapperType switch
        {
            "integer_range" => IntegerRangeMapper.FromJson(specElement.GetRawText()),
            "float_range" => FloatRangeMapper.FromJson(specElement.GetRawText()),
            "boolean_range" => BooleanRangeMapper.FromJson(specElement.GetRawText()),
            "bytes_range" => BytesRangeMapper.FromJson(specElement.GetRawText()),
            "categorical_range" => CategoricalRangeMapper.FromJson(specElement.GetRawText()),
            "sequence_range" => SequenceRangeMapper.FromSpec(
                JsonSerializer.Deserialize<SequenceMapperSpec>(specElement.GetRawText(), JsonOptions)
                    ?? throw new InvalidOperationException("mapper spec JSON produced null.")
            ),
            "text_range" => TextRangeMapper.FromJson(specElement.GetRawText()),
            "map_range" => FromSpec(
                JsonSerializer.Deserialize<ObjectMapperSpec>(specElement.GetRawText(), JsonOptions)
                    ?? throw new InvalidOperationException("mapper spec JSON produced null.")
            ),
            _ => throw new InvalidOperationException($"unsupported mapper_type '{mapperType}'.")
        };
    }

    private static object? JsonElementToObject(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => element.GetString(),
            JsonValueKind.Number => element.TryGetInt64(out var i64) ? i64 : element.GetDouble(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Null => null,
            JsonValueKind.Object => JsonSerializer.Deserialize<Dictionary<string, object>>(element.GetRawText(), JsonOptions),
            JsonValueKind.Array => JsonSerializer.Deserialize<List<object>>(element.GetRawText(), JsonOptions),
            _ => throw new InvalidOperationException("unsupported missing_value JSON kind.")
        };
    }

    private static Dictionary<string, object> ValidateSchema(IDictionary<string, object> schema)
    {
        var normalized = new Dictionary<string, object>(schema.Count, StringComparer.Ordinal);
        foreach (var kvp in schema)
        {
            if (string.IsNullOrWhiteSpace(kvp.Key))
            {
                throw new InvalidOperationException("schema field names must be non-empty strings.");
            }

            if (kvp.Value is null)
            {
                throw new ArgumentNullException($"schema field '{kvp.Key}' mapper");
            }

            normalized[kvp.Key] = kvp.Value;
        }

        return normalized;
    }

    private ObjectMapperSpec ToSpec()
    {
        var schema = new Dictionary<string, JsonElement>(_schema.Count);
        foreach (var (fieldName, mapper) in _schema)
        {
            var mappedSpec = mapper switch
            {
                IntegerRangeMapper integerMapper => integerMapper.ToJson(),
                FloatRangeMapper floatMapper => floatMapper.ToJson(),
                BooleanRangeMapper booleanMapper => booleanMapper.ToJson(),
                BytesRangeMapper bytesMapper => bytesMapper.ToJson(),
                CategoricalRangeMapper categoricalMapper => categoricalMapper.ToJson(),
                SequenceRangeMapper sequenceMapper => sequenceMapper.ToJson(),
                TextRangeMapper textMapper => textMapper.ToJson(),
                ObjectRangeMapper objectMapper => objectMapper.ToJson(),
                _ => throw new InvalidOperationException($"unsupported mapper type for field '{fieldName}'.")
            };

            schema[fieldName] = JsonDocument.Parse(mappedSpec).RootElement.Clone();
        }

        JsonElement? missingValueElement = null;
        if (_hasMissingValue)
        {
            if (_missingValue is null)
            {
                using var doc = JsonDocument.Parse("null");
                missingValueElement = doc.RootElement.Clone();
            }
            else
            {
                using var doc = JsonSerializer.SerializeToDocument(_missingValue, JsonOptions);
                missingValueElement = doc.RootElement.Clone();
            }
        }

        return new ObjectMapperSpec
        {
            SpecVersion = SpecVersion,
            MapperType = SpecType,
            Schema = schema,
            AllowUnknown = AllowUnknown,
            AllowEmpty = AllowEmpty,
            HasMissingValue = _hasMissingValue,
            MissingValue = missingValueElement,
            Name = Name
        };
    }
}

public sealed class ObjectMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "map_range";

    [JsonPropertyName("schema")]
    public Dictionary<string, JsonElement>? Schema { get; init; }

    [JsonPropertyName("allow_unknown")]
    public bool AllowUnknown { get; init; }

    [JsonPropertyName("allow_empty")]
    public bool AllowEmpty { get; init; }

    [JsonPropertyName("has_missing_value")]
    public bool HasMissingValue { get; init; }

    [JsonPropertyName("missing_value")]
    public JsonElement? MissingValue { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }
}
