using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace LibRangeMap;

public sealed class CategoricalRangeMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };

    private const string SpecVersion = MapperSpec.CurrentSpecVersion;
    private const string SpecType = "categorical_range";

    private readonly object[] _vocabulary;
    private readonly Dictionary<string, int> _vocabularyIndex;

    public double OutputMin { get; }
    public double OutputMax { get; }
    public string? Name { get; }

    public CategoricalRangeMapper(object[] vocabulary, double outputMin = -1.0, double outputMax = 1.0, string? name = null)
    {
        if (vocabulary is null)
        {
            throw new ArgumentNullException(nameof(vocabulary), "vocabulary payload must not be null.");
        }
        if (vocabulary.Length == 0)
        {
            throw new ArgumentException("vocabulary must not be empty.", nameof(vocabulary));
        }

        ValidateFinite(nameof(outputMin), outputMin);
        ValidateFinite(nameof(outputMax), outputMax);
        if (outputMax <= outputMin)
        {
            throw new ArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (name is not null && name.Length == 0)
        {
            throw new ArgumentException("name must not be empty.", nameof(name));
        }

        _vocabulary = vocabulary.Select(NormalizeToken).ToArray();
        OutputMin = outputMin;
        OutputMax = outputMax;
        Name = name;
        _vocabularyIndex = BuildVocabularyIndex(_vocabulary);
    }

    public double MapValue(object? value)
    {
        if (!IsSupportedToken(value))
        {
            throw new ArgumentException("value must be a string, finite number, boolean, character, or null.");
        }

        var key = TokenKey(value);
        if (!_vocabularyIndex.TryGetValue(key, out var index))
        {
            throw new KeyNotFoundException($"unknown token: {ValueToString(value)}");
        }

        if (_vocabulary.Length == 1)
        {
            return OutputMin;
        }

        return OutputMin + (index / (_vocabulary.Length - 1.0)) * (OutputMax - OutputMin);
    }

    public double Map(object? value) => MapValue(value);

    public string ToJson() => JsonSerializer.Serialize(ToSpec(), JsonOptions);

    public static CategoricalRangeMapper FromJson(string json)
    {
        var spec = JsonSerializer.Deserialize<CategoricalMapperSpec>(json, JsonOptions)
            ?? throw new InvalidOperationException("mapper spec JSON produced null.");
        return FromSpec(spec);
    }

    public static CategoricalRangeMapper FromSpec(CategoricalMapperSpec spec)
    {
        if (spec.SpecVersion != SpecVersion)
        {
            throw new ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", nameof(spec));
        }
        if (spec.MapperType != SpecType)
        {
            throw new ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", nameof(spec));
        }
        if (spec.Vocabulary is null)
        {
            throw new ArgumentException("vocabulary is required.", nameof(spec));
        }
        if (spec.Vocabulary.Length == 0)
        {
            throw new ArgumentException("vocabulary must not be empty.", nameof(spec));
        }
        if (spec.OutputRange is null || spec.OutputRange.Length != 2)
        {
            throw new ArgumentException("output_range must contain exactly two values.", nameof(spec));
        }

        return new CategoricalRangeMapper(spec.Vocabulary.Select(DecodeToken).ToArray(), spec.OutputRange[0], spec.OutputRange[1], spec.Name);
    }

    private CategoricalMapperSpec ToSpec()
    {
        return new CategoricalMapperSpec
        {
            SpecVersion = SpecVersion,
            MapperType = SpecType,
            Vocabulary = _vocabulary.Select(EncodeToken).ToArray(),
            OutputRange = new[] { OutputMin, OutputMax },
            Name = Name
        };
    }

    private static string? EncodeToken(object? token)
    {
        return token switch
        {
            null => null,
            string text => "str:" + text,
            char ch => "char:" + (int)ch,
            bool boolValue => "bool:" + (boolValue ? "true" : "false"),
            byte v => "num:" + v.ToString(System.Globalization.CultureInfo.InvariantCulture),
            sbyte v => "num:" + v.ToString(System.Globalization.CultureInfo.InvariantCulture),
            short v => "num:" + v.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ushort v => "num:" + v.ToString(System.Globalization.CultureInfo.InvariantCulture),
            int v => "num:" + v.ToString(System.Globalization.CultureInfo.InvariantCulture),
            uint v => "num:" + v.ToString(System.Globalization.CultureInfo.InvariantCulture),
            long v => "num:" + v.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ulong v => "num:" + v.ToString(System.Globalization.CultureInfo.InvariantCulture),
            float v => "num:" + FormatNumber(v),
            double v => "num:" + FormatNumber(v),
            decimal v => "num:" + FormatNumber(v),
            _ => throw new ArgumentException($"unsupported vocabulary token type: {token?.GetType().FullName}")
        };
    }

    private static object? DecodeToken(string? encoded)
    {
        if (encoded is null)
        {
            return null;
        }

        var separator = encoded.IndexOf(':');
        if (separator < 0)
        {
            return encoded;
        }

        var kind = encoded[..separator];
        var raw = encoded[(separator + 1)..];
        return kind switch
        {
            "str" => raw,
            "char" => (char)int.Parse(raw, System.Globalization.CultureInfo.InvariantCulture),
            "bool" => bool.Parse(raw),
            "num" => ParseNumber(raw),
            _ => throw new ArgumentException($"unsupported token encoding: {encoded}")
        };
    }

    private static object NormalizeToken(object token)
    {
        if (!IsSupportedToken(token))
        {
            throw new ArgumentException($"unsupported vocabulary token type: {token.GetType().FullName}");
        }

        return token switch
        {
            string text => text,
            char ch => ch,
            bool value => value,
            byte or sbyte or short or ushort or int or uint or long or ulong => token,
            float floatValue => floatValue,
            double doubleValue => doubleValue,
            decimal decimalValue => decimalValue,
            null => null!,
            _ => throw new ArgumentException($"unsupported vocabulary token type: {token.GetType().FullName}")
        };
    }

    private static bool IsSupportedToken(object? value)
    {
        return value switch
        {
            null => true,
            string => true,
            bool => true,
            char => true,
            byte or sbyte or short or ushort or int or uint or long or ulong => true,
            float v => float.IsFinite(v),
            double v => double.IsFinite(v),
            decimal => true,
            _ => false
        };
    }

    private static string TokenKey(object? value)
    {
        if (value is null)
        {
            return "null";
        }

        return value switch
        {
            string text => "str:" + text,
            bool boolValue => "bool:" + boolValue,
            char ch => "char:" + (int)ch,
            byte v => "num:" + v,
            sbyte v => "num:" + v,
            short v => "num:" + v,
            ushort v => "num:" + v,
            int v => "num:" + v,
            uint v => "num:" + v,
            long v => "num:" + v,
            ulong v => "num:" + v,
            float v => float.IsFinite(v) ? "num:" + FormatNumber(v) : throw new ArgumentException("vocabulary tokens must be finite numbers."),
            double v => double.IsFinite(v) ? "num:" + FormatNumber(v) : throw new ArgumentException("vocabulary tokens must be finite numbers."),
            decimal v => "num:" + FormatNumber(v),
            _ => throw new ArgumentException("value must be a string, finite number, boolean, character, or null.")
        };
    }

    private static string FormatNumber(double value)
    {
        return value % 1 == 0 ? ((long)value).ToString() : value.ToString("R");
    }

    private static string FormatNumber(float value)
    {
        return value % 1 == 0 ? ((long)value).ToString() : value.ToString("R");
    }

    private static string FormatNumber(decimal value)
    {
        return decimal.Truncate(value) == value ? decimal.ToInt64(value).ToString() : value.ToString(System.Globalization.CultureInfo.InvariantCulture);
    }

    private static object ParseNumber(string raw)
    {
        var number = double.Parse(raw, System.Globalization.CultureInfo.InvariantCulture);
        if (!double.IsFinite(number))
        {
            throw new ArgumentException("vocabulary tokens must be finite numbers.");
        }

        var asLong = (long)number;
        if (number == asLong)
        {
            return asLong;
        }

        return number;
    }

    private static Dictionary<string, int> BuildVocabularyIndex(object[] vocabulary)
    {
        var index = new Dictionary<string, int>(vocabulary.Length, StringComparer.Ordinal);
        for (var i = 0; i < vocabulary.Length; i++)
        {
            var token = vocabulary[i];
            var key = TokenKey(token);
            if (index.ContainsKey(key))
            {
                throw new ArgumentException($"vocabulary contains duplicate token: {ValueToString(token)}");
            }
            index[key] = i;
        }

        return index;
    }

    private static string ValueToString(object? value)
    {
        return value switch
        {
            null => "null",
            string text => $"\"{text}\"",
            char ch => $"'{ch}'",
            _ => value.ToString() ?? string.Empty
        };
    }

    private static void ValidateFinite(string label, double value)
    {
        if (!double.IsFinite(value))
        {
            throw new ArgumentException($"{label} must be finite.", label);
        }
    }
}

public sealed class CategoricalMapperSpec
{
    [JsonPropertyName("spec_version")]
    public string SpecVersion { get; init; } = MapperSpec.CurrentSpecVersion;

    [JsonPropertyName("mapper_type")]
    public string MapperType { get; init; } = "categorical_range";

    [JsonPropertyName("vocabulary")]
    public string?[]? Vocabulary { get; init; }

    [JsonPropertyName("output_range")]
    public double[]? OutputRange { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }
}
