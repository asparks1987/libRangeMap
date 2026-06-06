using System.Runtime.InteropServices;

namespace LibRangeMap;

[StructLayout(LayoutKind.Sequential)]
internal struct NativeMapper
{
    public long InputMin;
    public long InputMax;
    public double OutputMin;
    public double OutputMax;
    public int Clip;
}

[StructLayout(LayoutKind.Sequential)]
internal struct NativeSpec
{
    public int SpecVersionMajor;
    public int SpecVersionMinor;
    public long InputMin;
    public long InputMax;
    public double OutputMin;
    public double OutputMax;
    public int Clip;
}

internal static class NativeMethods
{
    private const string LibraryName = "librangemap_core.dll";

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl, ExactSpelling = true)]
    internal static extern int lrm_integer_range_mapper_init(
        ref NativeMapper mapper,
        long inputMin,
        long inputMax,
        double outputMin,
        double outputMax,
        int clip);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl, ExactSpelling = true)]
    internal static extern int lrm_integer_range_mapper_map_value(
        ref NativeMapper mapper,
        long value,
        out double outValue);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl, ExactSpelling = true)]
    internal static extern int lrm_integer_range_mapper_get_spec(
        ref NativeMapper mapper,
        out NativeSpec outSpec);
}
