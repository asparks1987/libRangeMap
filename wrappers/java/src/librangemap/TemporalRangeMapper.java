package librangemap;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;

public final class TemporalRangeMapper {
    private static final String SPEC_VERSION = "1.0-alpha";
    private static final String MAPPER_TYPE = "temporal_range";

    private static final String MODE_AUTO = "auto";
    private static final String MODE_TIMESTAMP = "timestamp";
    private static final String MODE_DURATION = "duration";
    private static final String MODE_DATETIME = "datetime";
    private static final String MODE_TIME = "time";

    private static final String POLICY_NAIVE_UTC = "naive_is_utc";
    private static final String POLICY_REJECT = "reject";

    private final double inMin;
    private final double inMax;
    private final double outMin;
    private final double outMax;
    private final boolean clip;
    private final String mode;
    private final double epoch;
    private final String naiveDatetimePolicy;
    private final String name;

    public TemporalRangeMapper(double inMin, double inMax) {
        this(inMin, inMax, -1.0, 1.0, false, MODE_AUTO, 0.0, POLICY_NAIVE_UTC, null);
    }

    public TemporalRangeMapper(
        double inMin,
        double inMax,
        double outMin,
        double outMax,
        boolean clip
    ) {
        this(inMin, inMax, outMin, outMax, clip, MODE_AUTO, 0.0, POLICY_NAIVE_UTC, null);
    }

    public TemporalRangeMapper(
        double inMin,
        double inMax,
        double outMin,
        double outMax,
        boolean clip,
        String mode,
        Object epoch,
        String naiveDatetimePolicy,
        String name
    ) {
        validateFinite(inMin, "in_min");
        validateFinite(inMax, "in_max");
        if (inMax <= inMin) {
            throw new IllegalArgumentException("input_range must be ordered from lower value to higher value.");
        }
        validateFinite(outMin, "out_min");
        validateFinite(outMax, "out_max");
        if (outMax <= outMin) {
            throw new IllegalArgumentException("output_range must be ordered from lower value to higher value.");
        }
        validateMode(mode);
        validateNaivePolicy(naiveDatetimePolicy);
        if (name != null && name.isEmpty()) {
            throw new IllegalArgumentException("name must not be empty");
        }

        this.inMin = inMin;
        this.inMax = inMax;
        this.outMin = outMin;
        this.outMax = outMax;
        this.clip = clip;
        this.mode = mode;
        this.epoch = coerceEpochBase(epoch, naiveDatetimePolicy);
        this.naiveDatetimePolicy = naiveDatetimePolicy;
        this.name = name;
    }

    public double mapValue(Object value) {
        double raw = coerceTemporalValue(value) - epoch;
        double clamped = raw;
        if (clamped < inMin) {
            if (!clip) {
                throw new IllegalArgumentException("value is below input_range lower bound; set clip=true to clamp.");
            }
            clamped = inMin;
        } else if (clamped > inMax) {
            if (!clip) {
                throw new IllegalArgumentException("value is above input_range upper bound; set clip=true to clamp.");
            }
            clamped = inMax;
        }
        return outMin + ((clamped - inMin) / (inMax - inMin)) * (outMax - outMin);
    }

    public double map(Object value) {
        return mapValue(value);
    }

    public String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append('{');
        sb.append("\"spec_version\":\"").append(SPEC_VERSION).append('\"').append(',');
        sb.append("\"mapper_type\":\"").append(MAPPER_TYPE).append('\"').append(',');
        sb.append("\"input_range\":[").append(inMin).append(',').append(inMax).append("],");
        sb.append("\"output_range\":[").append(outMin).append(',').append(outMax).append("],");
        sb.append("\"clip\":" ).append(clip).append(',');
        sb.append("\"mode\":\"").append(escape(mode)).append("\",");
        sb.append("\"epoch\":").append(epoch).append(',');
        sb.append("\"naive_datetime_policy\":\"").append(escape(naiveDatetimePolicy)).append('\"');
        if (name != null) {
            sb.append(',').append("\"name\":\"").append(escape(name)).append('\"');
        }
        sb.append('}');
        return sb.toString();
    }

    public static TemporalRangeMapper fromJson(String json) {
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

        double[] inputRange = extractDoublePair(json, "input_range");
        double[] outputRange = extractDoublePair(json, "output_range");
        boolean clip = extractBoolean(json, "clip");
        String mode = extractStringOrDefault(json, "mode", MODE_AUTO);
        double epoch = extractDoubleOrDefault(json, "epoch", 0.0);
        String policy = extractStringOrDefault(json, "naive_datetime_policy", POLICY_NAIVE_UTC);
        String name = extractStringOrNull(json, "name");

        return new TemporalRangeMapper(
            inputRange[0],
            inputRange[1],
            outputRange[0],
            outputRange[1],
            clip,
            mode,
            epoch,
            policy,
            name
        );
    }

    private double coerceTemporalValue(Object value) {
        return switch (mode) {
            case MODE_TIMESTAMP -> coerceTimestamp(value);
            case MODE_DURATION -> coerceDuration(value);
            case MODE_TIME -> coerceTime(value);
            case MODE_DATETIME -> coerceDateLike(value);
            default -> coerceAuto(value);
        };
    }

    private double coerceTimestamp(Object value) {
        if (value instanceof Number number && !(value instanceof Boolean)) {
            return finite(number.doubleValue(), "value");
        }
        throw new IllegalArgumentException("timestamp mode accepts finite numeric values only.");
    }

    private double coerceDuration(Object value) {
        if (value instanceof Duration duration) {
            return duration.toNanos() / 1_000_000_000.0;
        }
        if (value instanceof Number number && !(value instanceof Boolean)) {
            return finite(number.doubleValue(), "value");
        }
        throw new IllegalArgumentException("duration mode accepts finite numeric values or Duration values.");
    }

    private double coerceTime(Object value) {
        if (value instanceof LocalTime time) {
            return time.toSecondOfDay() + (time.getNano() / 1_000_000_000.0);
        }
        throw new IllegalArgumentException("time mode accepts LocalTime values only.");
    }

    private double coerceDateLike(Object value) {
        if (value instanceof Instant instant) {
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (value instanceof OffsetDateTime offsetDateTime) {
            Instant instant = offsetDateTime.toInstant();
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (value instanceof ZonedDateTime zonedDateTime) {
            Instant instant = zonedDateTime.toInstant();
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (value instanceof LocalDateTime localDateTime) {
            return coerceLocalDateTime(localDateTime);
        }
        if (value instanceof LocalDate localDate) {
            return localDate.atStartOfDay(ZoneId.of("UTC")).toEpochSecond();
        }
        if (value instanceof LocalTime localTime) {
            return localTime.toSecondOfDay() + (localTime.getNano() / 1_000_000_000.0);
        }
        if (value instanceof Number number && !(value instanceof Boolean)) {
            return finite(number.doubleValue(), "value");
        }
        throw new IllegalArgumentException(
            "datetime mode accepts Instant, OffsetDateTime, ZonedDateTime, LocalDateTime, LocalDate, LocalTime, or finite numeric values."
        );
    }

    private double coerceAuto(Object value) {
        if (value instanceof LocalDateTime localDateTime) {
            return coerceLocalDateTime(localDateTime);
        }
        if (value instanceof LocalDate localDate) {
            return localDate.atStartOfDay(ZoneId.of("UTC")).toEpochSecond();
        }
        if (value instanceof LocalTime localTime) {
            return localTime.toSecondOfDay() + (localTime.getNano() / 1_000_000_000.0);
        }
        if (value instanceof Duration duration) {
            return duration.toNanos() / 1_000_000_000.0;
        }
        if (value instanceof Instant instant) {
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (value instanceof OffsetDateTime offsetDateTime) {
            Instant instant = offsetDateTime.toInstant();
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (value instanceof ZonedDateTime zonedDateTime) {
            Instant instant = zonedDateTime.toInstant();
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (value instanceof Number number && !(value instanceof Boolean)) {
            return finite(number.doubleValue(), "value");
        }
        throw new IllegalArgumentException(
            "auto mode accepts numeric values, Instant, OffsetDateTime, ZonedDateTime, LocalDateTime, LocalDate, LocalTime, or Duration."
        );
    }

    private double coerceLocalDateTime(LocalDateTime localDateTime) {
        if (naiveDatetimePolicy == null || POLICY_REJECT.equals(naiveDatetimePolicy)) {
            throw new IllegalArgumentException("naive datetime inputs require mode-specific policy 'naive_is_utc'.");
        }
        return localDateTime.atZone(ZoneId.of("UTC")).toEpochSecond() + (localDateTime.getNano() / 1_000_000_000.0);
    }

    private static double coerceEpochBase(Object epoch, String policy) {
        if (epoch == null) {
            return 0.0;
        }
        if (epoch instanceof Number number && !(number instanceof Boolean)) {
            return finite(number.doubleValue(), "epoch");
        }
        if (epoch instanceof Instant instant) {
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (epoch instanceof OffsetDateTime offsetDateTime) {
            Instant instant = offsetDateTime.toInstant();
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (epoch instanceof ZonedDateTime zonedDateTime) {
            Instant instant = zonedDateTime.toInstant();
            return instant.getEpochSecond() + (instant.getNano() / 1_000_000_000.0);
        }
        if (epoch instanceof LocalDateTime localDateTime) {
            if (policy == null || POLICY_REJECT.equals(policy)) {
                throw new IllegalArgumentException("naive epoch datetime requires naive_is_utc policy.");
            }
            return localDateTime.atZone(ZoneId.of("UTC")).toEpochSecond() + (localDateTime.getNano() / 1_000_000_000.0);
        }
        if (epoch instanceof LocalDate localDate) {
            return localDate.atStartOfDay(ZoneId.of("UTC")).toEpochSecond();
        }
        throw new IllegalArgumentException("epoch must be null, finite number, Instant, OffsetDateTime, ZonedDateTime, LocalDateTime, or LocalDate.");
    }

    private static void validateFinite(double value, String fieldName) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(fieldName + " must be finite.");
        }
    }

    private static double finite(double value, String fieldName) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(fieldName + " must be finite.");
        }
        return value;
    }

    private static void validateMode(String mode) {
        if (mode == null) {
            throw new IllegalArgumentException("mode must be one of: auto, timestamp, datetime, duration, time.");
        }
        if (!MODE_AUTO.equals(mode)
            && !MODE_TIMESTAMP.equals(mode)
            && !MODE_DURATION.equals(mode)
            && !MODE_DATETIME.equals(mode)
            && !MODE_TIME.equals(mode)) {
            throw new IllegalArgumentException("mode must be one of: auto, timestamp, datetime, duration, time.");
        }
    }

    private static void validateNaivePolicy(String policy) {
        if (policy == null) {
            throw new IllegalArgumentException("naive_datetime_policy must be 'naive_is_utc' or 'reject'.");
        }
        if (!POLICY_NAIVE_UTC.equals(policy) && !POLICY_REJECT.equals(policy)) {
            throw new IllegalArgumentException("naive_datetime_policy must be 'naive_is_utc' or 'reject'.");
        }
    }

    private static String extractString(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        int valueStart = text.indexOf('"', start + needle.length());
        if (valueStart < 0) {
            throw new IllegalArgumentException("invalid string for " + key);
        }
        int end = text.indexOf('"', valueStart + 1);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated string for " + key);
        }
        return unescape(text.substring(valueStart + 1, end));
    }

    private static String extractStringOrDefault(String text, String key, String defaultValue) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return defaultValue;
        }
        int valueStart = text.indexOf('"', start + needle.length());
        if (valueStart < 0) {
            return defaultValue;
        }
        int end = text.indexOf('"', valueStart + 1);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated string for " + key);
        }
        return unescape(text.substring(valueStart + 1, end));
    }

    private static String extractStringOrNull(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return null;
        }
        int valueStart = start + needle.length();
        while (valueStart < text.length() && Character.isWhitespace(text.charAt(valueStart))) {
            valueStart++;
        }
        if (text.startsWith("null", valueStart)) {
            return null;
        }
        if (text.charAt(valueStart) != '"') {
            return null;
        }
        int end = text.indexOf('"', valueStart + 1);
        if (end < 0) {
            throw new IllegalArgumentException("unterminated string for " + key);
        }
        return unescape(text.substring(valueStart + 1, end));
    }

    private static double extractDoubleOrDefault(String text, String key, double defaultValue) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            return defaultValue;
        }
        int valueStart = start + needle.length();
        while (valueStart < text.length() && Character.isWhitespace(text.charAt(valueStart))) {
            valueStart++;
        }
        if (valueStart >= text.length()) {
            return defaultValue;
        }
        int end = valueStart;
        while (end < text.length() && text.charAt(end) != ',' && text.charAt(end) != '}') {
            end++;
        }
        try {
            return Double.parseDouble(text.substring(valueStart, end).trim());
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("invalid numeric value for " + key);
        }
    }

    private static boolean extractBoolean(String text, String key) {
        String needle = "\"" + key + "\":";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        int valueStart = start + needle.length();
        if (text.startsWith("true", valueStart)) {
            return true;
        }
        if (text.startsWith("false", valueStart)) {
            return false;
        }
        throw new IllegalArgumentException("invalid boolean for " + key);
    }

    private static double[] extractDoublePair(String text, String key) {
        String needle = "\"" + key + "\":[";
        int start = text.indexOf(needle);
        if (start < 0) {
            throw new IllegalArgumentException("missing key " + key);
        }
        int open = start + needle.length();
        int close = text.indexOf(']', open);
        if (close < 0) {
            throw new IllegalArgumentException("unterminated array for " + key);
        }
        String[] parts = text.substring(open, close).split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException(key + " must contain two values");
        }
        return new double[] { Double.parseDouble(parts[0].trim()), Double.parseDouble(parts[1].trim()) };
    }

    private static String escape(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static String unescape(String value) {
        return value.replace("\\\"", "\"").replace("\\\\", "\\");
    }
}
