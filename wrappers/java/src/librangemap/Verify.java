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

        BooleanRangeMapper boolMapper = new BooleanRangeMapper();
        assertEqual(boolMapper.mapValue(false), -1.0, "boolMapper.mapValue(false)");
        assertEqual(boolMapper.mapValue(true), 1.0, "boolMapper.mapValue(true)");

        BooleanRangeMapper customBool = new BooleanRangeMapper(-1.0, 2.0, 0.25, 1.75);
        assertEqual(customBool.mapValue(false), 0.25, "customBool.mapValue(false)");
        assertEqual(customBool.mapValue(true), 1.75, "customBool.mapValue(true)");

        BooleanRangeMapper roundTripBool = BooleanRangeMapper.fromJson(customBool.toJson());
        assertEqual(roundTripBool.mapValue(false), 0.25, "roundTripBool.mapValue(false)");

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
