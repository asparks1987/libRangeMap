package librangemap;

public final class Verify {
    public static void main(String[] args) {
        try (IntegerRangeMapper mapper = new IntegerRangeMapper(0, 100)) {
            assertEqual(mapper.mapValue(0), -1.0, "mapValue(0)");
            assertEqual(mapper.mapValue(50), 0.0, "mapValue(50)");
            assertEqual(mapper.mapValue(100), 1.0, "mapValue(100)");

            MapperSpec spec = mapper.spec();
            if (!"1.0-alpha".equals(spec.getSpecVersion())) {
                throw new IllegalStateException("unexpected spec version");
            }

            IntegerRangeMapper restored = IntegerRangeMapper.fromJson(mapper.toJson());
            assertEqual(restored.mapValue(50), 0.0, "restored.mapValue(50)");
            restored.close();

            assertEqual(mapper.mapValue(50), mapper.mapValue(50), "repeated.mapValue(50)");
        }

        try (IntegerRangeMapper clipped = new IntegerRangeMapper(0, 10, -1.0, 1.0, true)) {
            assertEqual(clipped.mapValue(-5), -1.0, "clipped.mapValue(-5)");
        }

        boolean threw = false;
        try (IntegerRangeMapper strict = new IntegerRangeMapper(0, 10, -1.0, 1.0, false)) {
            strict.mapValue(11);
        } catch (IllegalArgumentException expected) {
            threw = true;
        }

        if (!threw) {
            throw new IllegalStateException("strict out-of-range mapping should fail");
        }

        FloatRangeMapper floatMapper = new FloatRangeMapper(0.0, 10.0);
        assertEqual(floatMapper.mapValue(0.0), -1.0, "floatMapper.mapValue(0.0)");
        assertEqual(floatMapper.mapValue(5.0), 0.0, "floatMapper.mapValue(5.0)");
        assertEqual(floatMapper.mapValue(10.0), 1.0, "floatMapper.mapValue(10.0)");

        FloatRangeMapper clippedFloat = new FloatRangeMapper(0.0, 1.0, -1.0, 1.0, true);
        assertEqual(clippedFloat.mapValue(2.0), 1.0, "clippedFloat.mapValue(2.0)");

        String floatSpec = floatMapper.toJson();
        FloatRangeMapper roundTripFloat = FloatRangeMapper.fromJson(floatSpec);
        assertEqual(roundTripFloat.mapValue(5.0), 0.0, "roundTripFloat.mapValue(5.0)");

        TemporalRangeMapper durationMapper = new TemporalRangeMapper(0.0, 3600.0, -1.0, 1.0, false, "duration", 0.0, "naive_is_utc", null);
        assertEqual(durationMapper.mapValue(java.time.Duration.ofSeconds(1800)), 0.0, "durationMapper.mapValue(PT30M)");
        TemporalRangeMapper durationRoundTrip = TemporalRangeMapper.fromJson(durationMapper.toJson());
        assertEqual(durationRoundTrip.mapValue(java.time.Duration.ofSeconds(1800)), 0.0, "durationRoundTrip.mapValue(PT30M)");
        boolean durationStrict = false;
        try {
            durationMapper.mapValue(java.time.Duration.ofSeconds(7200));
        } catch (IllegalArgumentException expectedDurationStrict) {
            durationStrict = true;
        }
        if (!durationStrict) {
            throw new IllegalStateException("temporal strict out-of-range mapping should fail");
        }

        TemporalRangeMapper datetimeMapper = new TemporalRangeMapper(
                0.0,
                86400.0,
                -1.0,
                1.0,
                false,
                "datetime",
                0.0,
                "naive_is_utc",
                null
        );
        assertEqual(datetimeMapper.mapValue(java.time.LocalDateTime.of(1970, 1, 1, 12, 0, 0)), 0.0, "datetimeMapper.mapValue(1970-01-01T12:00:00)");

        TemporalRangeMapper badDatePolicy = new TemporalRangeMapper(
                0.0,
                86400.0,
                -1.0,
                1.0,
                false,
                "datetime",
                0.0,
                "reject",
                null
        );
        boolean datePolicyReject = false;
        try {
            badDatePolicy.mapValue(java.time.LocalDateTime.of(1970, 1, 2, 0, 0, 0));
        } catch (IllegalArgumentException expectedDatePolicy) {
            datePolicyReject = true;
        }
        if (!datePolicyReject) {
            throw new IllegalStateException("temporal mapper should reject naive datetime when policy is reject.");
        }

        ImageRangeMapper imageMapper = new ImageRangeMapper();
        double[] rawBytes = imageMapper.mapValue(new byte[] { 0, (byte) 128, (byte) 255 });
        assertEqual(rawBytes[0], -1.0, "imageMapper rawBytes[0]");
        assertEqual(rawBytes[1], ((128.0 / 255.0) * 2.0) - 1.0, "imageMapper rawBytes[1]");
        assertEqual(rawBytes[2], 1.0, "imageMapper rawBytes[2]");

        Object[] image = new Object[] {
                new Object[] { 0, 128, 255 },
                new Object[] { 64, 192, 32 }
        };
        Object[] imageMapped = (Object[]) imageMapper.mapValue(image);
        Object[] firstRow = (Object[]) imageMapped[0];
        Object[] secondRow = (Object[]) imageMapped[1];
        assertEqual((Double) firstRow[0], -1.0, "imageMapper row0 col0");
        assertEqual((Double) firstRow[1], ((128.0 / 255.0) * 2.0) - 1.0, "imageMapper row0 col1");
        assertEqual((Double) firstRow[2], 1.0, "imageMapper row0 col2");
        assertEqual((Double) secondRow[0], ((64.0 / 255.0) * 2.0) - 1.0, "imageMapper row1 col0");
        assertEqual((Double) secondRow[1], ((192.0 / 255.0) * 2.0) - 1.0, "imageMapper row1 col1");
        assertEqual((Double) secondRow[2], ((32.0 / 255.0) * 2.0) - 1.0, "imageMapper row1 col2");

        ImageRangeMapper imageRoundTrip = ImageRangeMapper.fromJson(imageMapper.toJson());
        Object[] roundTripImage = (Object[]) imageRoundTrip.mapValue(image);
        if (!java.util.Arrays.deepEquals(imageMapped, roundTripImage)) {
            throw new IllegalStateException("image roundtrip should preserve mapped pixels");
        }

        boolean imageStrict = false;
        try {
            imageMapper.mapValue(new Object[] { new Object[] { -1 } });
        } catch (IllegalArgumentException expectedImageStrict) {
            imageStrict = true;
        }
        if (!imageStrict) {
            throw new IllegalStateException("image-like strict out-of-range mapping should fail");
        }

        BooleanRangeMapper boolMapper = new BooleanRangeMapper();
        assertEqual(boolMapper.mapValue(false), -1.0, "boolMapper.mapValue(false)");
        assertEqual(boolMapper.mapValue(true), 1.0, "boolMapper.mapValue(true)");

        BooleanRangeMapper customBool = new BooleanRangeMapper(-1.0, 2.0, 0.25, 1.75);
        assertEqual(customBool.mapValue(false), 0.25, "customBool.mapValue(false)");
        assertEqual(customBool.mapValue(true), 1.75, "customBool.mapValue(true)");

        BooleanRangeMapper roundTripBool = BooleanRangeMapper.fromJson(customBool.toJson());
        assertEqual(roundTripBool.mapValue(false), 0.25, "roundTripBool.mapValue(false)");

        CategoricalRangeMapper catMapper = new CategoricalRangeMapper(new Object[] {"cat", "dog", "fox"});
        assertEqual(catMapper.mapValue("cat"), -1.0, "catMapper.mapValue(\"cat\")");
        assertEqual(catMapper.mapValue("dog"), 0.0, "catMapper.mapValue(\"dog\")");
        assertEqual(catMapper.mapValue("fox"), 1.0, "catMapper.mapValue(\"fox\")");

        boolean emptyCategoryVocabulary = false;
        try {
            new CategoricalRangeMapper(new Object[] {});
        } catch (IllegalArgumentException expectedEmptyVocabulary) {
            emptyCategoryVocabulary = true;
        }
        if (!emptyCategoryVocabulary) {
            throw new IllegalStateException("categorical mapper should reject empty vocabulary");
        }

        boolean unknownCategory = false;
        try {
            catMapper.mapValue("horse");
        } catch (IllegalArgumentException expectedCat) {
            unknownCategory = true;
        }
        if (!unknownCategory) {
            throw new IllegalStateException("categorical mapper should reject unknown token");
        }

        CategoricalRangeMapper catRoundTrip = CategoricalRangeMapper.fromJson(catMapper.toJson());
        assertEqual(catRoundTrip.mapValue("dog"), 0.0, "catRoundTrip.mapValue(\"dog\")");

        TextRangeMapper textMapper = new TextRangeMapper();
        double[] mappedText = textMapper.map("A");
        if (mappedText.length != 1) {
            throw new IllegalStateException("text mapping should return one element for single-character input");
        }
        double expected = -1.0 + ((double) 'A' / 0x10ffff) * 2.0;
        if (mappedText[0] != expected) {
            throw new IllegalStateException("unexpected text map result: " + mappedText[0] + ", expected " + expected);
        }

        TextRangeMapper alphaMapper = new TextRangeMapper(-1.0, 1.0, "alphabet", "abc", false, true, "labels");
        double[] mappedAlpha = alphaMapper.map("cab");
        if (mappedAlpha.length != 3) {
            throw new IllegalStateException("expected mapped alphabet sequence length 3");
        }
        assertEqual(mappedAlpha[0], 1.0, "alphaMapper.map(c)");
        assertEqual(mappedAlpha[1], -1.0, "alphaMapper.map(a)");
        assertEqual(mappedAlpha[2], 0.0, "alphaMapper.map(b)");

        boolean unknownAlphabet = false;
        try {
            alphaMapper.map("d");
        } catch (IllegalArgumentException expectedAlphabet) {
            unknownAlphabet = true;
        }
        if (!unknownAlphabet) {
            throw new IllegalStateException("alphabet mapper should reject unknown chars");
        }

        BytesRangeMapper bytesMapper = new BytesRangeMapper();
        double[] mappedBytes = bytesMapper.mapValue("\u0000\u007f");
        double expectedByteMid = ((127.0 / 255.0) * 2.0) - 1.0;
        if (mappedBytes.length != 2) {
            throw new IllegalStateException("expected two mapped bytes");
        }
        assertEqual(mappedBytes[0], -1.0, "bytesMapper.mapValue(\"\\\\0\\\\u007f\")[0]");
        assertEqual(mappedBytes[1], expectedByteMid, "bytesMapper.mapValue(\"\\\\0\\\\u007f\")[1]");
        assertEqual(bytesMapper.mapValue(new int[] {255})[0], 1.0, "bytesMapper.mapValue([255])[0]");
        double[] bytesRepeat = bytesMapper.mapValue("\u0000\u007f");
        if (bytesRepeat.length != mappedBytes.length || bytesRepeat[0] != mappedBytes[0] || bytesRepeat[1] != mappedBytes[1]) {
            throw new IllegalStateException("bytes repeated mapping changed output");
        }

        BytesRangeMapper bytesRoundTrip = BytesRangeMapper.fromJson(bytesMapper.toJson());
        assertEqual(bytesRoundTrip.mapValue(new int[] {0})[0], -1.0, "bytesRoundTrip.mapValue([0])[0]");
        double[] bytesRoundTripRepeat = bytesRoundTrip.mapValue("\u0000\u007f");
        if (bytesRoundTripRepeat.length != mappedBytes.length || bytesRoundTripRepeat[0] != mappedBytes[0] || bytesRoundTripRepeat[1] != mappedBytes[1]) {
            throw new IllegalStateException("bytes roundtrip repeated mapping changed output");
        }

        boolean bytesStrict = false;
        try {
            new BytesRangeMapper().mapValue(new int[] {256});
        } catch (IllegalArgumentException expected) {
            bytesStrict = true;
        }
        if (!bytesStrict) {
            throw new IllegalStateException("bytes strict mapping should reject out-of-range");
        }

        boolean emptyBytesFailed = false;
        try {
            new BytesRangeMapper(-1.0, 1.0, false, false).mapValue(new int[] {});
        } catch (IllegalArgumentException expectedBytesEmpty) {
            emptyBytesFailed = true;
        }
        if (!emptyBytesFailed) {
            throw new IllegalStateException("empty bytes should fail by default");
        }

        BytesRangeMapper bytesClipped = new BytesRangeMapper(-1.0, 1.0, true, true);
        double[] clippedBytes = bytesClipped.mapValue(new int[] {-5, 300});
        assertEqual(clippedBytes[0], -1.0, "bytesClipped.mapValue([-5, 300])[0]");
        assertEqual(clippedBytes[1], 1.0, "bytesClipped.mapValue([-5, 300])[1]");

        SequenceRangeMapper seq = new SequenceRangeMapper(new IntegerRangeMapper(0, 100));
        Object[] mapped = (Object[]) seq.mapValue(new Object[] {0L, new Object[] {25L, 50L, 75L}, 100L});
        assertEqual((Double) mapped[0], -1.0, "seq.mapValue(0)");
        assertEqual((Double) ((Object[]) mapped[1])[1], 0.0, "seq.mapValue(50)");
        assertEqual((Double) mapped[2], 1.0, "seq.mapValue(100)");

        boolean seqStrict = false;
        try {
            seq.mapValue(new Object[] {});
        } catch (IllegalArgumentException expectedSeq) {
            seqStrict = true;
        }
        if (!seqStrict) {
            throw new IllegalStateException("sequence empty should fail by default");
        }

        var objectSchema = new java.util.LinkedHashMap<String, Object>();
        objectSchema.put("age", new IntegerRangeMapper(0, 120));
        objectSchema.put("active", new BooleanRangeMapper());
        objectSchema.put(
            "scores",
            new SequenceRangeMapper(
                new FloatRangeMapper(0.0, 1.0),
                true
            )
        );

        ObjectRangeMapper objectMapper = new ObjectRangeMapper(objectSchema);

        class Profile {
            public int age;
            public boolean active;
            public Object[] scores;
            Profile(int age, boolean active, Object[] scores) {
                this.age = age;
                this.active = active;
                this.scores = scores;
            }
        }

        var objectMapped = objectMapper.map(new Profile(30, false, new Object[] { 0.0, 0.5 }));
        assertEqual((Double) objectMapped.get("age"), -0.5, "objectMapper.map(profile).age");
        assertEqual((Double) objectMapped.get("active"), -1.0, "objectMapper.map(profile).active");

        Object[] expectedObjectScores = (Object[]) objectMapped.get("scores");
        if (expectedObjectScores.length != 2) {
            throw new IllegalStateException("objectMapper nested sequence length should be 2");
        }
        assertEqual((Double) expectedObjectScores[0], -1.0, "objectMapper.map(profile).scores[0]");
        assertEqual((Double) expectedObjectScores[1], 0.0, "objectMapper.map(profile).scores[1]");

        ObjectRangeMapper objectRoundTrip = ObjectRangeMapper.fromJson(objectMapper.toJson());
        var objectRoundTripMapped = objectRoundTrip.map(
                new Profile(120, true, new Object[] { 1.0 })
        );
        assertEqual((Double) objectRoundTripMapped.get("age"), 1.0, "objectRoundTrip.map(profile).age");
        assertEqual((Double) objectRoundTripMapped.get("active"), 1.0, "objectRoundTrip.map(profile).active");

        Object[] objectRoundTripScores = (Object[]) objectRoundTripMapped.get("scores");
        if (objectRoundTripScores.length != 1 || (Double) objectRoundTripScores[0] != 1.0) {
            throw new IllegalStateException("objectRoundTrip nested score should map to 1.0");
        }

        var nestedSchema = new java.util.LinkedHashMap<String, Object>();
        nestedSchema.put("age", new IntegerRangeMapper(0, 100));
        nestedSchema.put("tags", new SequenceRangeMapper(new CategoricalRangeMapper(new Object[] {"red", "green", "blue"}), true));

        ObjectRangeMapper nestedMapper = new ObjectRangeMapper(
                new java.util.LinkedHashMap<String, Object>() {{
                    put("profile", new ObjectRangeMapper(nestedSchema));
                    put("active", new BooleanRangeMapper());
                }},
                true
        );

        var nestedInput = new java.util.LinkedHashMap<String, Object>() {{
            put("profile", new java.util.LinkedHashMap<String, Object>() {{
                put("age", 25);
                put("tags", new Object[] {"red", "green"});
            }});
            put("active", true);
        }};

        var nestedFirst = nestedMapper.map(nestedInput);
        var nestedSecond = ObjectRangeMapper.fromJson(nestedMapper.toJson()).map(nestedInput);
        if (!nestedFirst.equals(nestedSecond)) {
            throw new IllegalStateException("nested composite round-trip should preserve mapping results");
        }
        var nestedProfile = (java.util.Map<String, Object>) nestedFirst.get("profile");
        assertEqual((Double) nestedProfile.get("age"), -0.5, "nested composite age");
        Object[] nestedTags = (Object[]) nestedProfile.get("tags");
        assertEqual((Double) nestedTags[0], -1.0, "nested composite tag 0");
        assertEqual((Double) nestedTags[1], 0.0, "nested composite tag 1");
        assertEqual((Double) nestedFirst.get("active"), 1.0, "nested composite active");

        boolean objectUnknownFieldFailed = false;
        try {
            objectMapper.map(new java.util.LinkedHashMap<String, Object>() {{
                put("age", 10);
                put("active", true);
                put("scores", new Object[] { 0.5 });
                put("unexpected", 1);
            }});
        } catch (IllegalArgumentException expectedUnknown) {
            objectUnknownFieldFailed = true;
        }
        if (!objectUnknownFieldFailed) {
            throw new IllegalStateException("object mapper should reject unknown fields by default.");
        }

        boolean objectUnknownFieldFromPojoFailed = false;
        class ProfileWithExtra {
            public int age;
            public boolean active;
            public Object[] scores;
            public int unexpected;

            ProfileWithExtra(int age, boolean active, Object[] scores, int unexpected) {
                this.age = age;
                this.active = active;
                this.scores = scores;
                this.unexpected = unexpected;
            }
        }
        try {
            objectMapper.map(new ProfileWithExtra(10, true, new Object[] { 1.0 }, 99));
        } catch (IllegalArgumentException expectedUnknownObject) {
            objectUnknownFieldFromPojoFailed = true;
        }
        if (!objectUnknownFieldFromPojoFailed) {
            throw new IllegalStateException("object mapper should reject unknown fields on object inputs by default.");
        }

        boolean objectMissingFieldFailed = false;
        try {
            objectMapper.map(new java.util.LinkedHashMap<String, Object>() {{
                put("age", 10);
                put("active", true);
            }});
        } catch (IllegalArgumentException expectedMissing) {
            objectMissingFieldFailed = true;
        }
        if (!objectMissingFieldFailed) {
            throw new IllegalStateException("object mapper should reject missing fields by default.");
        }

        SequenceRangeMapper explicitSeq = new SequenceRangeMapper(new IntegerRangeMapper(0, 10), true);
        Object[] allowed = (Object[]) explicitSeq.mapValue(new Object[] {});
        if (allowed.length != 0) {
            throw new IllegalStateException("expected empty mapped sequence");
        }

        SequenceRangeMapper seqWithEmptyNested = new SequenceRangeMapper(
            new SequenceRangeMapper(new IntegerRangeMapper(0, 100), true)
        );
        Object[] mixed = (Object[]) seqWithEmptyNested.mapValue(new Object[] {new Object[] {}});
        if (((Object[]) mixed[0]).length != 0) {
            throw new IllegalStateException("nested empty sequence should remain empty");
        }

        SequenceRangeMapper seqJson = new SequenceRangeMapper(new IntegerRangeMapper(0, 10), true);
        String seqSpec = seqJson.toJson();
        SequenceRangeMapper seqRoundTrip = SequenceRangeMapper.fromJson(seqSpec);
        assertEqual((Double) ((Object[]) seqRoundTrip.mapValue(new Object[] {0L, 10L}))[0], -1.0,
                "seqRoundTrip.mapValue(0)");
        assertEqual((Double) ((Object[]) seqRoundTrip.mapValue(new Object[] {0L, 10L}))[1], 1.0,
                "seqRoundTrip.mapValue(10)");

        System.out.println("Java wrapper verification passed.");
    }

    private static void assertEqual(double actual, double expected, String label) {
        if (actual != expected) {
            throw new IllegalStateException(label + " = " + actual + ", expected " + expected);
        }
    }
}
