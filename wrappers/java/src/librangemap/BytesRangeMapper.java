package librangemap;

import java.nio.charset.StandardCharsets;

public final class BytesRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "bytes_range";

    private final double outputMin;
    private final double outputMax;
    private final boolean clip;
    private final boolean allowEmpty;
    private final String name;

    public BytesRangeMapper() {
        this(-1.0, 1.0, false, false, null);
    }

    public BytesRangeMapper(double outputMin, double outputMax) {
        this(outputMin, outputMax, false, false, null);
    }

    public BytesRangeMapper(double outputMin, double outputMax, boolean clip) {
        this(outputMin, outputMax, clip, false, null);
    }

    public BytesRangeMapper(double outputMin, double outputMax, boolean clip, boolean allowEmpty) {
        this(outputMin, outputMax, clip, allowEmpty, null);
    }

    public BytesRangeMapper(double outputMin, double outputMax, boolean clip, boolean allowEmpty, String name) {
        requireFiniteNumber(outputMin, "output_min");
        requireFiniteNumber(outputMax, "output_max");

        if (outputMax <= outputMin) {
            throw new IllegalArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (name != null && name.isEmpty()) {
            throw new IllegalArgumentException("name must not be empty");
        }
        this.outputMin = outputMin;
        this.outputMax = outputMax;
        this.clip = clip;
        this.allowEmpty = allowEmpty;
        this.name = name;
    }

    public double[] mapValue(String value) {
        if (value == null) {
            throw new IllegalArgumentException("value must be a string.");
        }
        return mapBytes(value.getBytes(StandardCharsets.UTF_8));
    }

    public double[] mapValue(byte[] value) {
        if (value == null) {
            throw new IllegalArgumentException("value must not be null.");
        }
        double[] output = new double[value.length];
        if (!allowEmpty && value.length == 0) {
            throw new IllegalArgumentException("empty bytes value is invalid by default; set allowEmpty=true to map empty inputs.");
        }

        for (int i = 0; i < value.length; i++) {
            int byteValue = value[i] & 0xff;
            output[i] = mapUnit(byteValue, i);
        }
        return output;
    }

    public double[] mapValue(int[] value) {
        if (value == null) {
            throw new IllegalArgumentException("value must not be null.");
        }
        double[] output = new double[value.length];
        if (!allowEmpty && value.length == 0) {
            throw new IllegalArgumentException("empty bytes value is invalid by default; set allowEmpty=true to map empty inputs.");
        }

        for (int i = 0; i < value.length; i++) {
            int byteValue = validateByte(value[i], i);
            output[i] = mapUnit(byteValue, i);
        }
        return output;
    }

    public double[] map(Object value) {
        return mapValue(value);
    }

    public double[] mapValue(Object value) {
        if (value instanceof byte[] byteArray) {
            return mapValue(byteArray);
        }
        if (value instanceof int[] intArray) {
            return mapValue(intArray);
        }
        if (value instanceof String stringValue) {
            return mapValue(stringValue);
        }
        throw new IllegalArgumentException("value must be a byte array, int array, or string.");
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append("\",");
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append("\",");
        sb.append("\"input_range\":[0,255],");
        sb.append("\"output_range\":[").append(outputMin).append(",").append(outputMax).append("],");
        sb.append("\"clip\":").append(clip).append(",");
        sb.append("\"allow_empty\":").append(allowEmpty);
        if (name != null) {
            sb.append(",\"name\":\"").append(escape(name)).append("\"");
        }
        sb.append("}");
        return sb.toString();
    }

    public static BytesRangeMapper fromJson(String json) {
        if (json == null) {
            throw new IllegalArgumentException("mapper json must not be null");
        }
        String specVersion = extractString(json, "spec_version");
        if (!SPEC_VERSION.equals(specVersion)) {
            throw new IllegalArgumentException("unsupported spec_version " + specVersion);
        }
        String mapperType = extractString(json, "mapper_type");
        if (!MAPPER_TYPE.equals(mapperType)) {
            throw new IllegalArgumentException("unsupported mapper_type " + mapperType);
        }

        int[] inputRange = extractIntPairOrNull(json, "input_range");
        if (inputRange != null) {
            if (inputRange.length != 2 || inputRange[0] != 0 || inputRange[1] != 255) {
                throw new IllegalArgumentException("unsupported input_range [" + inputRange[0] + "," + inputRange[1] + "]");
            }
        }

        double[] outputRange = extractDoublePair(json, "output_range");
        Boolean clip = extractBooleanOrNull(json, "clip");
        Boolean allowEmpty = extractBooleanOrNull(json, "allow_empty");
        String name = extractStringOrNull(json, "name");
        return new BytesRangeMapper(
                outputRange[0],
                outputRange[1],
                clip != null && clip,
                allowEmpty != null && allowEmpty,
                name
        );
    }

    private double mapUnit(int byteValue, int index) {
        int mappedByte = byteValue;
        if (mappedByte < 0) {
            if (!clip) {
                throw new IllegalArgumentException(
                        "byte value " + mappedByte + " at index " + index
                        + " is below input_range lower bound 0; enable clip to clamp."
                );
            }
            mappedByte = 0;
        } else if (mappedByte > 255) {
            if (!clip) {
                throw new IllegalArgumentException(
                        "byte value " + mappedByte + " at index " + index
                        + " is above input_range upper bound 255; enable clip to clamp."
                );
            }
            mappedByte = 255;
        }
        return outputMin + ((mappedByte / 255.0) * (outputMax - outputMin));
    }

    private int validateByte(int value, int index) {
        if (value < 0 || value > 255) {
            if (!clip) {
                if (value < 0) {
                    throw new IllegalArgumentException(
                        "byte value " + value + " at index " + index
                        + " is below input_range lower bound 0; enable clip to clamp."
                    );
                }
                throw new IllegalArgumentException(
                    "byte value " + value + " at index " + index
                    + " is above input_range upper bound 255; enable clip to clamp."
                );
            }
            return Math.max(0, Math.min(255, value));
        }
        return value;
    }

    private static void requireFiniteNumber(double value, String label) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(label + " must be a finite number.");
        }
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

    private static String extractStringOrNull(String json, String key) {
        String needle = "\"" + key + "\":\"";
        int start = json.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        int end = json.indexOf('"', start);
        if (end < 0) {
            return null;
        }
        return json.substring(start, end);
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
        return new double[] {
            Double.parseDouble(parts[0].trim()),
            Double.parseDouble(parts[1].trim()),
        };
    }

    private static int[] extractIntPairOrNull(String json, String key) {
        String needle = "\"" + key + "\":[";
        int start = json.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        int end = json.indexOf(']', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated array for " + key);
        }
        String[] parts = json.substring(start, end).split(",");
        if (parts.length != 2) {
            return null;
        }
        return new int[] {
            Integer.parseInt(parts[0].trim()),
            Integer.parseInt(parts[1].trim()),
        };
    }

    private static Boolean extractBooleanOrNull(String json, String key) {
        String needle = "\"" + key + "\":";
        int start = json.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        if (json.startsWith("true", start)) {
            return Boolean.TRUE;
        }
        if (json.startsWith("false", start)) {
            return Boolean.FALSE;
        }
        throw new IllegalArgumentException("invalid boolean for " + key);
    }

    private static String escape(String text) {
        return text.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
