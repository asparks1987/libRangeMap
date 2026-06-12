package librangemap;

public final class TextRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "text_range";
    private static final double CODEPOINT_MIN = 0.0;
    private static final double CODEPOINT_MAX = 0x10ffff;
    private static final double BYTE_MIN = 0.0;
    private static final double BYTE_MAX = 255.0;

    private final String mode;
    private final double outputMin;
    private final double outputMax;
    private final boolean clip;
    private final boolean allowEmpty;
    private final String alphabet;
    private final double inputMin;
    private final double inputMax;
    private final String name;

    public TextRangeMapper(double outputMin, double outputMax) {
        this(outputMin, outputMax, "codepoint", null, false, false, null);
    }

    public TextRangeMapper() {
        this(-1.0, 1.0, "codepoint", null, false, false, null);
    }

    public TextRangeMapper(String mode, String alphabet) {
        this(-1.0, 1.0, mode, alphabet, false, false, null);
    }

    public TextRangeMapper(
            double outputMin,
            double outputMax,
            String mode,
            String alphabet,
            boolean clip,
            boolean allowEmpty,
            String name) {
        requireFiniteNumber(outputMin, "outputMin");
        requireFiniteNumber(outputMax, "outputMax");

        if (!"codepoint".equals(mode) && !"alphabet".equals(mode) && !"byte".equals(mode)) {
            throw new IllegalArgumentException("mode must be codepoint, alphabet, or byte");
        }
        if (outputMax <= outputMin) {
            throw new IllegalArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if ("alphabet".equals(mode) && (alphabet == null || alphabet.isEmpty())) {
            throw new IllegalArgumentException("alphabet is required for alphabet mode");
        }

        this.mode = mode;
        this.outputMin = outputMin;
        this.outputMax = outputMax;
        this.clip = clip;
        this.allowEmpty = allowEmpty;
        this.alphabet = alphabet;
        this.name = (name != null && name.isEmpty()) ? null : name;

        if ("alphabet".equals(mode)) {
            this.inputMin = 0.0;
            this.inputMax = alphabet.length() - 1.0;
        } else if ("byte".equals(mode)) {
            this.inputMin = BYTE_MIN;
            this.inputMax = BYTE_MAX;
        } else {
            this.inputMin = CODEPOINT_MIN;
            this.inputMax = CODEPOINT_MAX;
        }
    }

    public double[] mapValue(String value) {
        if (value == null) {
            throw new IllegalArgumentException("value must be a string.");
        }
        if (value.isEmpty() && !allowEmpty) {
            throw new IllegalArgumentException("empty string is invalid by default; set allowEmpty=true to map empty strings.");
        }

        if (mode.equals("byte")) {
            byte[] bytes = value.getBytes(java.nio.charset.StandardCharsets.UTF_8);
            double[] output = new double[bytes.length];
            for (int i = 0; i < bytes.length; i++) {
                double unit = bytes[i] & 0xff;
                output[i] = mapUnit(unit);
            }
            return output;
        }

        int[] codepoints = value.codePoints().toArray();
        double[] output = new double[codepoints.length];
        for (int i = 0; i < codepoints.length; i++) {
            double unit = codepoints[i];
            output[i] = mapUnit(unit);
        }
        return output;
    }

    private double mapUnit(double unit) {
        if (mode.equals("alphabet")) {
            String symbol = Character.toString((char) Math.round(unit));
            int index = alphabet.indexOf(symbol);
            if (index < 0) {
                throw new IllegalArgumentException("unknown character '" + symbol + "' for alphabet mode");
            }
            unit = index;
        }

        double mapped = unit;
        if (mapped < inputMin) {
            if (!clip) {
                throw new IllegalArgumentException(
                        "value " + mapped + " is below input_range lower bound " + inputMin + "; enable clip to clamp."
                );
            }
            mapped = inputMin;
        } else if (mapped > inputMax) {
            if (!clip) {
                throw new IllegalArgumentException(
                        "value " + mapped + " is above input_range upper bound " + inputMax + "; enable clip to clamp."
                );
            }
            mapped = inputMax;
        }
        return outputMapped(mapped, inputMin, inputMax, outputMin, outputMax);
    }

    public double[] map(String value) {
        return mapValue(value);
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append("\",");
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append("\",");
        sb.append("\"output_range\":[").append(outputMin).append(",").append(outputMax).append("],");
        sb.append("\"mode\":\"").append(mode).append("\",");
        sb.append("\"clip\":").append(clip).append(",");
        sb.append("\"allow_empty\":").append(allowEmpty);
        if (alphabet != null) {
            sb.append(",\"alphabet\":\"").append(escape(alphabet)).append("\"");
        }
        if (name != null) {
            sb.append(",\"name\":\"").append(escape(name)).append("\"");
        }
        sb.append("}");
        return sb.toString();
    }

    public static TextRangeMapper fromJson(String json) {
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

        double[] outputRange = extractDoublePair(json, "output_range");
        String mode = extractStringOrNull(json, "mode");
        if (mode == null) {
            mode = "codepoint";
        }
        String alphabet = extractStringOrNull(json, "alphabet");
        Boolean clip = extractBooleanOrNull(json, "clip");
        Boolean allowEmpty = extractBooleanOrNull(json, "allow_empty");
        String name = extractStringOrNull(json, "name");
        return new TextRangeMapper(
                outputRange[0],
                outputRange[1],
                mode,
                alphabet,
                clip != null && clip,
                allowEmpty != null && allowEmpty,
                name
        );
    }

    private static String escape(String text) {
        return text.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static void requireFiniteNumber(double value, String label) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(label + " must be a finite number.");
        }
    }

    private static double outputMapped(double value, double inMin, double inMax, double outMin, double outMax) {
        return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
    }

    private static String extractString(String text, String key) {
        String needle = "\"" + key + "\":\"";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = text.indexOf('"', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated string for " + key);
        }
        return text.substring(start, end);
    }

    private static String extractStringOrNull(String text, String key) {
        String needle = "\"" + key + "\":\"";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        int end = text.indexOf('"', start);
        if (end < 0) {
            return null;
        }
        return text.substring(start, end);
    }

    private static Boolean parseBoolean(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        if (text.startsWith("true", start)) {
            return true;
        }
        if (text.startsWith("false", start)) {
            return false;
        }
        throw new IllegalArgumentException("invalid boolean for " + key);
    }

    private static Boolean extractBooleanOrNull(String text, String key) {
        return parseBoolean(text, key);
    }

    private static double[] extractDoublePair(String text, String key) {
        String needle = "\"" + key + "\":[";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = text.indexOf(']', start);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated array for " + key);
        }
        String[] parts = text.substring(start, end).split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException(key + " must contain two values");
        }
        return new double[] {
            Double.parseDouble(parts[0].trim()),
            Double.parseDouble(parts[1].trim()),
        };
    }
}
