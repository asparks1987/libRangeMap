package librangemap;

public final class IntegerRangeMapper implements AutoCloseable {
    private static final String SPEC_VERSION = "1.0-alpha";

    static {
        System.loadLibrary("librangemap_java");
    }

    private long nativeHandle;
    private final long inputMin;
    private final long inputMax;
    private final double outputMin;
    private final double outputMax;
    private final boolean clip;
    private boolean closed;

    public IntegerRangeMapper(long inputMin, long inputMax) {
        this(inputMin, inputMax, -1.0, 1.0, false);
    }

    public IntegerRangeMapper(long inputMin, long inputMax, double outputMin, double outputMax, boolean clip) {
        this.inputMin = inputMin;
        this.inputMax = inputMax;
        this.outputMin = outputMin;
        this.outputMax = outputMax;
        this.clip = clip;
        this.nativeHandle = nativeCreate(inputMin, inputMax, outputMin, outputMax, clip);
    }

    public double mapValue(long value) {
        ensureOpen();
        return nativeMapValue(nativeHandle, value);
    }

    public double map(long value) {
        return mapValue(value);
    }

    public MapperSpec spec() {
        ensureOpen();
        return new MapperSpec(SPEC_VERSION, "integer_range", inputMin, inputMax, outputMin, outputMax, clip);
    }

    public String toJson() {
        return spec().toJson();
    }

    public static IntegerRangeMapper fromJson(String json) {
        return fromSpec(MapperSpec.fromJson(json));
    }

    public static IntegerRangeMapper fromSpec(MapperSpec spec) {
        if (!SPEC_VERSION.equals(spec.getSpecVersion())) {
            throw new IllegalArgumentException("unsupported spec_version " + spec.getSpecVersion());
        }
        if (!"integer_range".equals(spec.getMapperType())) {
            throw new IllegalArgumentException("unsupported mapper_type " + spec.getMapperType());
        }
        return new IntegerRangeMapper(
            spec.getInputRange()[0],
            spec.getInputRange()[1],
            spec.getOutputRange()[0],
            spec.getOutputRange()[1],
            spec.isClip()
        );
    }

    @Override
    public void close() {
        if (!closed) {
            nativeDestroy(nativeHandle);
            nativeHandle = 0;
            closed = true;
        }
    }

    private void ensureOpen() {
        if (closed) {
            throw new IllegalStateException("mapper has been closed");
        }
    }

    private static native long nativeCreate(long inputMin, long inputMax, double outputMin, double outputMax, boolean clip);
    private static native void nativeDestroy(long handle);
    private static native double nativeMapValue(long handle, long value);
}
