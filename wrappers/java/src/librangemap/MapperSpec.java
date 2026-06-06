package librangemap;

public final class MapperSpec {
    private final String specVersion;
    private final String mapperType;
    private final long[] inputRange;
    private final double[] outputRange;
    private final boolean clip;

    public MapperSpec(String specVersion, String mapperType, long inputMin, long inputMax, double outputMin, double outputMax, boolean clip) {
        this(specVersion, mapperType, new long[] { inputMin, inputMax }, new double[] { outputMin, outputMax }, clip);
    }

    public MapperSpec(String specVersion, String mapperType, long[] inputRange, double[] outputRange, boolean clip) {
        if (inputRange == null || inputRange.length != 2) {
            throw new IllegalArgumentException("input_range must contain exactly two values");
        }
        if (outputRange == null || outputRange.length != 2) {
            throw new IllegalArgumentException("output_range must contain exactly two values");
        }
        this.specVersion = specVersion;
        this.mapperType = mapperType;
        this.inputRange = new long[] { inputRange[0], inputRange[1] };
        this.outputRange = new double[] { outputRange[0], outputRange[1] };
        this.clip = clip;
    }

    public String getSpecVersion() {
        return specVersion;
    }

    public String getMapperType() {
        return mapperType;
    }

    public long[] getInputRange() {
        return new long[] { inputRange[0], inputRange[1] };
    }

    public double[] getOutputRange() {
        return new double[] { outputRange[0], outputRange[1] };
    }

    public boolean isClip() {
        return clip;
    }

    public String toJson() {
        return "{\"spec_version\":\"" + escape(specVersion) + "\","
            + "\"mapper_type\":\"" + escape(mapperType) + "\","
            + "\"input_range\":[" + inputRange[0] + "," + inputRange[1] + "],"
            + "\"output_range\":[" + outputRange[0] + "," + outputRange[1] + "],"
            + "\"clip\":" + clip + "}";
    }

    public static MapperSpec fromJson(String json) {
        String specVersion = extractString(json, "spec_version");
        String mapperType = extractString(json, "mapper_type");
        long[] inputRange = extractLongPair(json, "input_range");
        double[] outputRange = extractDoublePair(json, "output_range");
        boolean clip = extractBoolean(json, "clip");
        return new MapperSpec(specVersion, mapperType, inputRange, outputRange, clip);
    }

    private static String extractString(String json, String key) {
        String needle = "\"" + key + "\":\"";
        int start = json.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = json.indexOf('"', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated string for " + key);
        }
        return json.substring(start, end);
    }

    private static long[] extractLongPair(String json, String key) {
        String needle = "\"" + key + "\":[";
        int start = json.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = json.indexOf(']', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated array for " + key);
        }
        String[] parts = json.substring(start, end).split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException(key + " must contain two values");
        }
        return new long[] { Long.parseLong(parts[0].trim()), Long.parseLong(parts[1].trim()) };
    }

    private static double[] extractDoublePair(String json, String key) {
        String needle = "\"" + key + "\":[";
        int start = json.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = json.indexOf(']', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated array for " + key);
        }
        String[] parts = json.substring(start, end).split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException(key + " must contain two values");
        }
        return new double[] { Double.parseDouble(parts[0].trim()), Double.parseDouble(parts[1].trim()) };
    }

    private static boolean extractBoolean(String json, String key) {
        String needle = "\"" + key + "\":";
        int start = json.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        if (json.startsWith("true", start)) {
            return true;
        }
        if (json.startsWith("false", start)) {
            return false;
        }
        throw new IllegalArgumentException("invalid boolean for " + key);
    }

    private static String escape(String text) {
        return text.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
