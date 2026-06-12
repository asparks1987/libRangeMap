package librangemap;

public final class CategoricalRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "categorical_range";

    private final Object[] vocabulary;
    private final java.util.Map<String, Integer> vocabularyIndex;
    private final double outputMin;
    private final double outputMax;
    private final String name;

    public CategoricalRangeMapper(Object[] vocabulary) {
        this(vocabulary, -1.0, 1.0, null);
    }

    public CategoricalRangeMapper(Object[] vocabulary, double outputMin, double outputMax) {
        this(vocabulary, outputMin, outputMax, null);
    }

    public CategoricalRangeMapper(Object[] vocabulary, double outputMin, double outputMax, String name) {
        requireVocabulary(vocabulary);
        requireFinite(outputMin, "outputMin");
        requireFinite(outputMax, "outputMax");

        if (outputMax <= outputMin) {
            throw new IllegalArgumentException("output_range must be ordered from lower value to higher value.");
        }
        if (name != null && name.isEmpty()) {
            throw new IllegalArgumentException("name must not be empty");
        }

        this.vocabulary = vocabulary.clone();
        this.outputMin = outputMin;
        this.outputMax = outputMax;
        this.name = name;
        this.vocabularyIndex = buildVocabularyIndex(this.vocabulary);
    }

    public double mapValue(Object value) {
        if (!isSupportedToken(value)) {
            throw new IllegalArgumentException("value must be a string, finite number, boolean, character, or null.");
        }
        String key = tokenKey(value);
        Integer index = vocabularyIndex.get(key);
        if (index == null) {
            throw new IllegalArgumentException("unknown token: " + valueToString(value));
        }

        if (vocabulary.length == 1) {
            return outputMin;
        }
        return outputMin + (index.doubleValue() / (vocabulary.length - 1.0)) * (outputMax - outputMin);
    }

    public double map(Object value) {
        return mapValue(value);
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append('{');
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append("\",");
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append("\",");
        sb.append("\"vocabulary\":[");
        for (int i = 0; i < vocabulary.length; i++) {
            if (i > 0) {
                sb.append(",");
            }
            sb.append(encodeToken(vocabulary[i]));
        }
        sb.append("],\"output_range\":[");
        sb.append(outputMin).append(",").append(outputMax).append("]");
        if (name != null) {
            sb.append(",\"name\":\"").append(escape(name)).append("\"");
        }
        sb.append('}');
        return sb.toString();
    }

    public static CategoricalRangeMapper fromJson(String json) {
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

        Object[] vocabulary = parseVocabulary(json, "vocabulary");
        double[] outputRange = extractDoublePair(json, "output_range");
        String name = extractStringOrNull(json, "name");
        return new CategoricalRangeMapper(vocabulary, outputRange[0], outputRange[1], name);
    }

    private static void requireFinite(double value, String label) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(label + " must be finite.");
        }
    }

    private static void requireVocabulary(Object[] vocabulary) {
        if (vocabulary == null) {
            throw new IllegalArgumentException("vocabulary must not be null.");
        }
        if (vocabulary.length == 0) {
            throw new IllegalArgumentException("vocabulary must not be empty.");
        }
    }

    private static boolean isSupportedToken(Object value) {
        if (value == null) {
            return true;
        }
        if (value instanceof String || value instanceof Boolean || value instanceof Character) {
            return true;
        }
        if (value instanceof Number valueNumber) {
            return Double.isFinite(valueNumber.doubleValue());
        }
        return false;
    }

    private static String tokenKey(Object value) {
        if (value == null) {
            return "null";
        }
        if (value instanceof String text) {
            return "str:" + text;
        }
        if (value instanceof Boolean boolValue) {
            return "bool:" + boolValue;
        }
        if (value instanceof Character ch) {
            return "char:" + (int) ch.charValue();
        }
        if (value instanceof Number number) {
            double num = number.doubleValue();
            long asLong = number.longValue();
            if (Double.isFinite(num) && num == (double) asLong) {
                return "num:" + asLong;
            }
            return "num:" + Double.toString(num);
        }
        throw new IllegalArgumentException("value must be a string, finite number, boolean, character, or null.");
    }

    private static java.util.Map<String, Integer> buildVocabularyIndex(Object[] vocabulary) {
        java.util.Map<String, Integer> index = new java.util.LinkedHashMap<>();
        for (int i = 0; i < vocabulary.length; i++) {
            Object token = vocabulary[i];
            if (!isSupportedToken(token)) {
                throw new IllegalArgumentException("unsupported vocabulary token type: " + token.getClass().getName());
            }
            String key = tokenKey(token);
            if (index.containsKey(key)) {
                throw new IllegalArgumentException("vocabulary contains duplicate token: " + valueToString(token));
            }
            index.put(key, i);
        }
        return index;
    }

    private static String encodeToken(Object token) {
        if (token == null) {
            return "null";
        }
        if (token instanceof String text) {
            return "\"" + escapeToken("str", text) + "\"";
        }
        if (token instanceof Character ch) {
            return "\"" + escapeToken("char", Integer.toString((int) ch.charValue())) + "\"";
        }
        if (token instanceof Boolean boolValue) {
            return "\"" + escapeToken("bool", boolValue ? "true" : "false") + "\"";
        }
        if (token instanceof Number number) {
            if (!Double.isFinite(number.doubleValue())) {
                throw new IllegalArgumentException("vocabulary tokens must be finite numbers.");
            }
            double value = number.doubleValue();
            long asLong = number.longValue();
            if (value == (double) asLong) {
                return "\"" + escapeToken("num", Long.toString(asLong)) + "\"";
            }
            return "\"" + escapeToken("num", Double.toString(value)) + "\"";
        }
        throw new IllegalArgumentException("unsupported vocabulary token type: " + token.getClass().getName());
    }

    private static String escapeToken(String type, String value) {
        return type + ":" + escape(value);
    }

    private static String valueToString(Object value) {
        if (value == null) {
            return "null";
        }
        if (value instanceof String text) {
            return "\"" + text + "\"";
        }
        return String.valueOf(value);
    }

    private static String escape(String text) {
        return text.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static String unescape(String text) {
        return text.replace("\\\"", "\"").replace("\\\\", "\\");
    }

    private static Object[] parseVocabulary(String json, String key) {
        String arrayText = extractArray(json, key);
        String content = stripOuter(arrayText);
        if (content.trim().isEmpty()) {
            return new Object[0];
        }
        java.util.List<Object> tokens = new java.util.ArrayList<>();
        int i = 0;
        while (i < content.length()) {
            i = skipWhitespace(content, i);
            if (i >= content.length()) {
                break;
            }
            Object token;
            char ch = content.charAt(i);
            if (ch == '"') {
                int end = indexAfterString(content, i);
                String raw = content.substring(i + 1, end - 1);
                token = decodeToken(unescape(raw));
                i = end;
            } else if (content.startsWith("null", i)) {
                token = null;
                i += 4;
            } else {
                throw new IllegalArgumentException("unsupported token literal in vocabulary array");
            }
            tokens.add(token);
            i = skipWhitespace(content, i);
            if (i < content.length() && content.charAt(i) == ',') {
                i++;
            }
        }
        return tokens.toArray();
    }

    private static Object decodeToken(String encoded) {
        if (encoded == null) {
            return null;
        }
        int sep = encoded.indexOf(':');
        if (sep < 0) {
            return encoded;
        }
        String type = encoded.substring(0, sep);
        String raw = encoded.substring(sep + 1);
        return switch (type) {
            case "str" -> raw;
            case "char" -> (char) Integer.parseInt(raw);
            case "bool" -> Boolean.parseBoolean(raw);
            case "num" -> {
                double number = Double.parseDouble(raw);
                long asLong = (long) number;
                if (number == (double) asLong) {
                    yield asLong;
                }
                yield number;
            }
            default -> throw new IllegalArgumentException("unsupported token encoding: " + encoded);
        };
    }

    private static String extractArray(String json, String key) {
        String needle = "\"" + key + "\":[";
        int start = json.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        int open = start + needle.length() - 1;
        int end = indexAfterArray(json, open);
        return json.substring(start, end);
    }

    private static int indexAfterArray(String text, int openIndex) {
        int depth = 0;
        boolean inString = false;
        boolean escaped = false;
        for (int i = openIndex; i < text.length(); i++) {
            char c = text.charAt(i);
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c == '\\') {
                escaped = true;
                continue;
            }
            if (c == '"') {
                inString = !inString;
                continue;
            }
            if (inString) {
                continue;
            }
            if (c == '[') {
                depth++;
            } else if (c == ']') {
                depth--;
                if (depth == 0) {
                    return i + 1;
                }
            }
        }
        throw new IllegalArgumentException("unterminated array for key");
    }

    private static String stripOuter(String text) {
        if (text == null || text.isEmpty()) {
            return "";
        }
        if (text.charAt(0) != '[' || text.charAt(text.length() - 1) != ']') {
            throw new IllegalArgumentException("expected array.");
        }
        return text.substring(1, text.length() - 1);
    }

    private static int skipWhitespace(String text, int start) {
        int i = start;
        while (i < text.length() && Character.isWhitespace(text.charAt(i))) {
            i++;
        }
        return i;
    }

    private static int indexAfterString(String text, int start) {
        if (text.charAt(start) != '"') {
            throw new IllegalArgumentException("expected string literal start");
        }
        boolean escaped = false;
        for (int i = start + 1; i < text.length(); i++) {
            char c = text.charAt(i);
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c == '\\') {
                escaped = true;
                continue;
            }
            if (c == '"') {
                return i + 1;
            }
        }
        throw new IllegalArgumentException("unterminated string");
    }

    private static String extractString(String text, String key) {
        String needle = "\"" + key + "\":\"";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        start += needle.length();
        int end = indexAfterString(text, start - 1);
        return unescape(text.substring(start, end - 1));
    }

    private static String extractStringOrNull(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        start += needle.length();
        if (start >= text.length()) {
            throw new IllegalArgumentException("invalid value for " + key);
        }
        if (text.startsWith("null", start)) {
            return null;
        }
        if (text.charAt(start) != '"') {
            throw new IllegalArgumentException("invalid string for " + key);
        }
        int end = indexAfterString(text, start);
        return unescape(text.substring(start + 1, end - 1));
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
