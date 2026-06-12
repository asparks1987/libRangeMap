using LibRangeMap;

public sealed class ProfileWithJunk
{
    public long Age { get; set; }
    public bool Active { get; set; }
    public int Extra { get; set; }
}

static void AssertEqual(double actual, double expected, string label)
{
    if (actual != expected)
    {
        throw new InvalidOperationException($"{label} = {actual}, expected {expected}");
    }
}

static void AssertArrayEqual(double[] actual, double[] expected, string label)
{
    if (actual.Length != expected.Length)
    {
        throw new InvalidOperationException($"{label} length {actual.Length}, expected {expected.Length}");
    }

    for (var i = 0; i < actual.Length; i++)
    {
        if (actual[i] != expected[i])
        {
            throw new InvalidOperationException($"{label}[{i}] = {actual[i]}, expected {expected[i]}");
        }
    }
}

static void AssertDictionaryEqual(Dictionary<string, object?> actual, Dictionary<string, object?> expected, string label)
{
    if (actual.Count != expected.Count)
    {
        throw new InvalidOperationException($"{label} count {actual.Count}, expected {expected.Count}");
    }

    foreach (var key in expected.Keys)
    {
        if (!actual.ContainsKey(key))
        {
            throw new InvalidOperationException($"{label} missing key {key}");
        }

        if (actual[key] is object[] actualSeq && expected[key] is object[] expectedSeq)
        {
            AssertObjectArrayEqual(actualSeq, expectedSeq, $"{label}[{key}]");
            continue;
        }

        if (!Equals(actual[key], expected[key]))
        {
            throw new InvalidOperationException($"{label}[{key}] = {actual[key]}, expected {expected[key]}");
        }
    }
}

static void AssertObjectArrayEqual(object[] actual, object[] expected, string label)
{
    if (actual.Length != expected.Length)
    {
        throw new InvalidOperationException($"{label} length {actual.Length}, expected {expected.Length}");
    }

    for (var i = 0; i < actual.Length; i++)
    {
        if (actual[i] is double aDouble && expected[i] is double eDouble)
        {
            if (aDouble != eDouble)
            {
                throw new InvalidOperationException($"{label}[{i}] = {aDouble}, expected {eDouble}");
            }

            continue;
        }

        if (actual[i] is object[] aSeq && expected[i] is object[] eSeq)
        {
            AssertObjectArrayEqual(aSeq, eSeq, $"{label}[{i}]");
            continue;
        }

        if (actual[i]?.GetType() != expected[i]?.GetType())
        {
            throw new InvalidOperationException($"{label}[{i}] type {actual[i]?.GetType().Name}, expected {expected[i]?.GetType().Name}");
        }

        if (!Equals(actual[i], expected[i]))
        {
            throw new InvalidOperationException($"{label}[{i}] = {actual[i]}, expected {expected[i]}");
        }
    }
}

var mapper = new IntegerRangeMapper(0, 100);

AssertEqual(mapper.MapValue(0), -1.0, "MapValue(0)");
AssertEqual(mapper.MapValue(50), 0.0, "MapValue(50)");
AssertEqual(mapper.MapValue(100), 1.0, "MapValue(100)");

var spec = mapper.Spec();
if (spec.SpecVersion != MapperSpec.CurrentSpecVersion)
{
    throw new InvalidOperationException($"SpecVersion = {spec.SpecVersion}");
}

var repeatedFirst = mapper.MapValue(50);
var repeatedSecond = mapper.MapValue(50);
AssertEqual(repeatedFirst, repeatedSecond, "Repeated.MapValue(50)");

var json = mapper.ToJson();
var roundTrip = IntegerRangeMapper.FromJson(json);
AssertEqual(roundTrip.MapValue(50), 0.0, "RoundTrip.MapValue(50)");

var clipped = new IntegerRangeMapper(0, 10, -1.0, 1.0, true);
AssertEqual(clipped.MapValue(-5), -1.0, "Clipped.MapValue(-5)");

var floatMapper = new FloatRangeMapper(0.0, 10.0);
AssertEqual(floatMapper.MapValue(0.0), -1.0, "Float.MapValue(0.0)");
AssertEqual(floatMapper.MapValue(5.0), 0.0, "Float.MapValue(5.0)");
AssertEqual(floatMapper.MapValue(10.0), 1.0, "Float.MapValue(10.0)");

var floatRoundTrip = FloatRangeMapper.FromJson(floatMapper.ToJson());
AssertEqual(floatRoundTrip.MapValue(5.0), 0.0, "Float.RoundTrip.MapValue(5.0)");

var boolMapper = new BooleanRangeMapper();
AssertEqual(boolMapper.MapValue(false), -1.0, "Boolean.MapValue(false)");
AssertEqual(boolMapper.MapValue(true), 1.0, "Boolean.MapValue(true)");

var customBool = new BooleanRangeMapper(-1.0, 2.0, 0.25, 1.75);
AssertEqual(customBool.MapValue(false), 0.25, "Boolean.Custom.MapValue(false)");
AssertEqual(customBool.MapValue(true), 1.75, "Boolean.Custom.MapValue(true)");

var boolRoundTrip = BooleanRangeMapper.FromJson(customBool.ToJson());
AssertEqual(boolRoundTrip.MapValue(false), 0.25, "Boolean.RoundTrip.MapValue(false)");

var temporalMapper = new TemporalRangeMapper(1_700_000_000_000, 1_700_000_100_000);
AssertEqual(temporalMapper.MapValue(1_700_000_000_000), -1.0, "Temporal.MapValue(lower)");
AssertEqual(temporalMapper.MapValue(1_700_000_050_000), 0.0, "Temporal.MapValue(mid)");
AssertEqual(temporalMapper.MapValue(DateTimeOffset.FromUnixTimeMilliseconds(1_700_000_100_000)), 1.0, "Temporal.MapValue(DateTimeOffset.upper)");

var temporalUtc = DateTimeOffset.FromUnixTimeMilliseconds(1_700_000_050_000).UtcDateTime;
AssertEqual(temporalMapper.MapValue(temporalUtc), 0.0, "Temporal.MapValue(DateTime.utc)");
AssertEqual(temporalMapper.MapValue(temporalUtc), temporalMapper.MapValue(temporalUtc), "Temporal.Repeated.MapValue(DateTime.utc)");

var temporalRoundTrip = TemporalRangeMapper.FromJson(temporalMapper.ToJson());
AssertEqual(temporalRoundTrip.MapValue(1_700_000_050_000), 0.0, "Temporal.RoundTrip.MapValue(mid)");

var temporalStrictRejected = false;
try
{
    temporalMapper.MapValue(1_700_000_200_000);
}
catch (ArgumentOutOfRangeException)
{
    temporalStrictRejected = true;
}

if (!temporalStrictRejected)
{
    throw new InvalidOperationException("Temporal.MapValue(out-of-range) should reject when clip=false.");
}

var temporalUnspecifiedRejected = false;
try
{
    temporalMapper.MapValue(DateTime.SpecifyKind(DateTime.UnixEpoch, DateTimeKind.Unspecified));
}
catch (ArgumentException)
{
    temporalUnspecifiedRejected = true;
}

if (!temporalUnspecifiedRejected)
{
    throw new InvalidOperationException("Temporal.MapValue(DateTimeKind.Unspecified) should reject explicitly.");
}

var byteMapper = new BytesRangeMapper();
AssertEqual(byteMapper.MapValue(0), -1.0, "Bytes.MapValue(0)");
AssertEqual(byteMapper.MapValue(255), 1.0, "Bytes.MapValue(255)");
AssertArrayEqual(byteMapper.Map(new byte[] { 0, 127, 255 }), new[] { -1.0, -0.00392156862745098, 1.0 }, "Bytes.Map(byte[])");
AssertArrayEqual(byteMapper.Map("AB"), new[] { -0.49019607843137253, -0.17254901960784315 }, "Bytes.Map(utf8-string)");
AssertArrayEqual(byteMapper.Map(new byte[] { 0, 127, 255 }), new[] { -1.0, -0.00392156862745098, 1.0 }, "Bytes.Map(byte[]) repeated");

var byteJson = byteMapper.ToJson();
var byteRoundTrip = BytesRangeMapper.FromJson(byteJson);
AssertEqual(byteRoundTrip.MapValue(128), 0.0039215686274509665, "Bytes.RoundTrip.MapValue(128)");
AssertArrayEqual(byteRoundTrip.Map(new byte[] { 0, 127, 255 }), new[] { -1.0, -0.00392156862745098, 1.0 }, "Bytes.RoundTrip.Map(byte[])");

var categoricalMapper = new CategoricalRangeMapper(new object[] { "cat", 1, true, null, 'x' });
AssertEqual(categoricalMapper.MapValue("cat"), -1.0, "Categorical.MapValue(string)");
AssertEqual(categoricalMapper.MapValue(1), -0.5, "Categorical.MapValue(int)");
AssertEqual(categoricalMapper.MapValue(true), 0.0, "Categorical.MapValue(bool)");
AssertEqual(categoricalMapper.MapValue(null), 0.5, "Categorical.MapValue(null)");
AssertEqual(categoricalMapper.MapValue('x'), 1.0, "Categorical.MapValue(char)");
AssertEqual(categoricalMapper.MapValue("cat"), categoricalMapper.MapValue("cat"), "Categorical.Repeated.MapValue(string)");

var categoricalJson = categoricalMapper.ToJson();
var categoricalRoundTrip = CategoricalRangeMapper.FromJson(categoricalJson);
AssertEqual(categoricalRoundTrip.MapValue(true), 0.0, "Categorical.RoundTrip.MapValue(bool)");

var categoricalUnknownRejected = false;
try
{
    categoricalMapper.MapValue("wolf");
}
catch (KeyNotFoundException)
{
    categoricalUnknownRejected = true;
}
if (!categoricalUnknownRejected)
{
    throw new InvalidOperationException("Categorical.MapValue(unknown) should reject explicitly.");
}

var categoricalDuplicateRejected = false;
try
{
    _ = new CategoricalRangeMapper(new object[] { "cat", "cat" });
}
catch (ArgumentException)
{
    categoricalDuplicateRejected = true;
}
if (!categoricalDuplicateRejected)
{
    throw new InvalidOperationException("Categorical vocabulary should reject duplicate tokens.");
}

var strictBytes = new BytesRangeMapper(0, 20);
var outOfRangeBytesRejected = false;
try
{
    strictBytes.MapValue(200);
}
catch (ArgumentOutOfRangeException)
{
    outOfRangeBytesRejected = true;
}
if (!outOfRangeBytesRejected)
{
    throw new InvalidOperationException("Bytes.MapValue(200) should reject when clip=false.");
}

var clippedBytes = new BytesRangeMapper(0, 20, -1.0, 1.0, true);
AssertEqual(clippedBytes.MapValue(200), 1.0, "Bytes.Clip.MapValue(200)");

var emptyRejected = false;
try
{
    byteMapper.Map(Array.Empty<byte>());
}
catch (ArgumentException)
{
    emptyRejected = true;
}
if (!emptyRejected)
{
    throw new InvalidOperationException("Bytes.Map(Array.Empty<byte>()) should reject by default.");
}

var imageMapper = new ImageRangeMapper();
double[] imageRaw = imageMapper.Map(new byte[] { 0, 128, 255 });
AssertArrayEqual(imageRaw, new[] { -1.0, 0.0039215686274509665, 1.0 }, "Image.Map(byte[])");

var imageNested = (object[])imageMapper.Map(new object[]
{
    new object[] { 0, 128, 255 },
    new object[] { 64, 192, 32 }
});
AssertObjectArrayEqual(
    imageNested,
    new object[]
    {
        new object[] { -1.0, 0.0039215686274509665, 1.0 },
        new object[] { -0.4980392156862745, 0.5058823529411764, -0.7490196078431373 }
    },
    "Image.Map(nested)");

var imageRoundTrip = ImageRangeMapper.FromJson(imageMapper.ToJson());
AssertArrayEqual(imageRoundTrip.Map(new byte[] { 0, 128, 255 }), imageRaw, "Image.RoundTrip.Map(byte[])");

var imageStrictRejected = false;
try
{
    imageMapper.Map(new object[] { new object[] { -1 } });
}
catch (ArgumentOutOfRangeException)
{
    imageStrictRejected = true;
}
if (!imageStrictRejected)
{
    throw new InvalidOperationException("Image.Map(out-of-range) should reject when clip=false.");
}

var sequenceIntegerMapper = new SequenceRangeMapper(new IntegerRangeMapper(0, 4));
AssertArrayEqual(sequenceIntegerMapper.MapValues(new long[] { 0, 2, 4 }), new[] { -1.0, 0.0, 1.0 }, "Seq.MapValues(integer)");

var sequenceCategoricalMapper = new SequenceRangeMapper(categoricalMapper);
AssertArrayEqual(
    sequenceCategoricalMapper.MapValues(new object?[] { "cat", 1, true, null, 'x' }),
    new[] { -1.0, -0.5, 0.0, 0.5, 1.0 },
    "Seq.MapValues(categorical)");

var nestedSequence = sequenceIntegerMapper.Map(new object[] { 0, new object[] { 1, 2 }, new object[] { new object[] { 3 } } });
AssertObjectArrayEqual(
    (object[])nestedSequence,
    new object[]
    {
        -1.0,
        new object[] { 0.0, 0.5 },
        new object[] { new object[] { 1.0 } }
    },
    "Seq.Map(nested)");

var sequenceRoundTrip = SequenceRangeMapper.FromJson(sequenceIntegerMapper.ToJson());
AssertArrayEqual(sequenceRoundTrip.MapValues(new long[] { 4, 0 }), new[] { 1.0, -1.0 }, "Seq.RoundTrip.MapValues");

var sequenceStrictReject = false;
try
{
    sequenceIntegerMapper.MapValues(new long[] { -1 });
}
catch (ArgumentOutOfRangeException)
{
    sequenceStrictReject = true;
}
if (!sequenceStrictReject)
{
    throw new InvalidOperationException("Seq.MapValues(-1) should reject when clip=false.");
}

var nestedRecordMapper = new ObjectRangeMapper(
    new Dictionary<string, object>
    {
        ["age"] = new IntegerRangeMapper(0, 120),
        ["active"] = new BooleanRangeMapper(),
        ["kind"] = categoricalMapper,
        ["scores"] = new SequenceRangeMapper(new FloatRangeMapper(0.0, 1.0), allowEmpty: true),
    });

var nestedRecord = nestedRecordMapper.Map(
    new Dictionary<string, object>
    {
        ["age"] = 40,
        ["active"] = true,
        ["kind"] = "cat",
        ["scores"] = new object[] { 0.0, 0.5, 1.0 }
    }
);
var nestedRecordSecond = nestedRecordMapper.Map(
    new Dictionary<string, object>
    {
        ["age"] = 40,
        ["active"] = true,
        ["kind"] = "cat",
        ["scores"] = new object[] { 0.0, 0.5, 1.0 }
    }
);
AssertDictionaryEqual(
    nestedRecord,
    new Dictionary<string, object?>
    {
        ["age"] = 0.0,
        ["active"] = 1.0,
        ["kind"] = -1.0,
        ["scores"] = new object[] { -1.0, 0.0, 1.0 }
    },
    "Map.Map");
AssertDictionaryEqual(
    nestedRecordSecond,
    new Dictionary<string, object?>
    {
        ["age"] = 0.0,
        ["active"] = 1.0,
        ["kind"] = -1.0,
        ["scores"] = new object[] { -1.0, 0.0, 1.0 }
    },
    "Map.Map.Second");

var recordMapperRoundTrip = ObjectRangeMapper.FromJson(nestedRecordMapper.ToJson());
var roundTripRecord = recordMapperRoundTrip.Map(
    new Dictionary<string, object>
    {
        ["age"] = 30,
        ["active"] = false,
        ["kind"] = "cat",
        ["scores"] = new object[] { 0.0 }
    }
);
AssertObjectArrayEqual((object[])roundTripRecord["scores"]!, new object[] { -1.0 }, "Map.RoundTrip.Array");
AssertEqual((double)roundTripRecord["age"]!, 0.0, "Map.RoundTrip.Field(\"age\")");

var mapUnknownFieldRejected = false;
try
{
    nestedRecordMapper.Map(
        new Dictionary<string, object>
        {
            ["age"] = 20,
            ["active"] = false,
            ["scores"] = new object[] { 0.0 },
            ["junk"] = 1,
        }
    );
}
catch (ArgumentException)
{
    mapUnknownFieldRejected = true;
}
if (!mapUnknownFieldRejected)
{
    throw new InvalidOperationException("Map.Map(dictionary with unknown field) should reject when allowUnknown=false.");
}

var objectSchemaMapper = new ObjectRangeMapper(
    new Dictionary<string, object>
    {
        ["Age"] = new IntegerRangeMapper(0, 120),
        ["Active"] = new BooleanRangeMapper(),
    });

var mapObjectUnknownFieldRejected = false;
try
{
    objectSchemaMapper.Map(
        new ProfileWithJunk
        {
            Age = 20,
            Active = false,
            Extra = 7
        });
}
catch (ArgumentException)
{
    mapObjectUnknownFieldRejected = true;
}
if (!mapObjectUnknownFieldRejected)
{
    throw new InvalidOperationException("Map.Map(object with unknown member) should reject when allowUnknown=false.");
}

var permissiveObjectMapper = new ObjectRangeMapper(
    new Dictionary<string, object>
    {
        ["Age"] = new IntegerRangeMapper(0, 120),
        ["Active"] = new BooleanRangeMapper(),
    },
    allowUnknown: true);

var permissiveObjectResult = permissiveObjectMapper.Map(
    new ProfileWithJunk
    {
        Age = 30,
        Active = true,
        Extra = 99
    }
);
AssertEqual((double)permissiveObjectResult["Age"]!, 1.0, "Map.allowUnknown.Map(object Age)");

var permissiveMap = new ObjectRangeMapper(
    new Dictionary<string, object>
    {
        ["age"] = new IntegerRangeMapper(0, 120),
        ["active"] = new BooleanRangeMapper(),
    },
    allowUnknown: true);

var permissiveResult = permissiveMap.Map(
    new Dictionary<string, object>
    {
        ["age"] = 100,
        ["active"] = false,
        ["ignored"] = "extra"
    }
);
AssertEqual((double)permissiveResult["age"]!, 1.0, "Map.allowUnknown.Map(age)");

var missingFieldMapper = new ObjectRangeMapper(
    new Dictionary<string, object>
    {
        ["age"] = new IntegerRangeMapper(0, 120),
        ["active"] = new BooleanRangeMapper(),
    },
    hasMissingValue: true,
    missingValue: "N/A");

var missingValueResult = missingFieldMapper.Map(new Dictionary<string, object> { ["age"] = 24 });
AssertEqual((double)missingValueResult["age"]!, -0.6, "Map.missing.age");
if (!Equals(missingValueResult["active"], "N/A"))
{
    throw new InvalidOperationException("Map.missing should apply configured missingValue.");
}

var missingFieldRejected = false;
try
{
    new ObjectRangeMapper(
        new Dictionary<string, object>
        {
            ["age"] = new IntegerRangeMapper(0, 120),
            ["active"] = new BooleanRangeMapper(),
        }
    ).Map(new Dictionary<string, object> { ["age"] = 24 });
}
catch (ArgumentException)
{
    missingFieldRejected = true;
}
if (!missingFieldRejected)
{
    throw new InvalidOperationException("Map.Map(dictionary with missing field) should reject when missingValue is not configured.");
}

var textCodepoint = new TextRangeMapper();
AssertArrayEqual(textCodepoint.Map("AB"), new[] { -0.9998833150377296, -0.9998815198844639 }, "Text.codepoint.Map('AB')");
AssertEqual(textCodepoint.MapValue('A'), -0.9998833150377296, "Text.codepoint.MapValue('A')");

var textAlphabet = new TextRangeMapper("alphabet", "ABC", outputMin: -1.0, outputMax: 1.0);
AssertArrayEqual(textAlphabet.Map("AC"), new[] { -1.0, 1.0 }, "Text.alphabet.Map('AC')");
AssertEqual(textAlphabet.MapValue('B'), 0.0, "Text.alphabet.MapValue('B')");

var textByte = new TextRangeMapper("byte", outputMin: -1.0, outputMax: 1.0);
var textByteMap = textByte.Map("A");
AssertArrayEqual(textByteMap, new[] { -0.4901960784313726 }, "Text.byte.Map('A')");

var textJson = textAlphabet.ToJson();
var textRoundTrip = TextRangeMapper.FromJson(textJson);
AssertArrayEqual(textRoundTrip.Map("ABC"), new[] { -1.0, 0.0, 1.0 }, "Text.alphabet.RoundTrip.Map('ABC')");

var emptyAlphabetRejected = false;
try
{
    new TextRangeMapper("alphabet", "");
}
catch (ArgumentException)
{
    emptyAlphabetRejected = true;
}
if (!emptyAlphabetRejected)
{
    throw new InvalidOperationException("Text.alphabet should reject empty alphabets by default.");
}

var textUnknownRejected = false;
try
{
    textAlphabet.Map("Z");
}
catch (KeyNotFoundException)
{
    textUnknownRejected = true;
}
if (!textUnknownRejected)
{
    throw new InvalidOperationException("Text.alphabet.Map('Z') should reject unknown symbol.");
}

Console.WriteLine("C# wrapper verification passed.");
