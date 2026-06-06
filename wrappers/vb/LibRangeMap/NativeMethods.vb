Imports System.Runtime.InteropServices

Friend Module NativeMethods
    Friend Const LibraryName As String = "librangemap_core.dll"

    <StructLayout(LayoutKind.Sequential)>
    Friend Structure NativeMapper
        Public InputMin As Long
        Public InputMax As Long
        Public OutputMin As Double
        Public OutputMax As Double
        Public Clip As Integer
    End Structure

    <StructLayout(LayoutKind.Sequential)>
    Friend Structure NativeSpec
        Public SpecVersionMajor As Integer
        Public SpecVersionMinor As Integer
        Public InputMin As Long
        Public InputMax As Long
        Public OutputMin As Double
        Public OutputMax As Double
        Public Clip As Integer
    End Structure

    <DllImport(LibraryName, CallingConvention:=CallingConvention.Cdecl, ExactSpelling:=True)>
    Friend Function lrm_integer_range_mapper_init(ByRef mapper As NativeMapper, inputMin As Long, inputMax As Long, outputMin As Double, outputMax As Double, clip As Integer) As Integer
    End Function

    <DllImport(LibraryName, CallingConvention:=CallingConvention.Cdecl, ExactSpelling:=True)>
    Friend Function lrm_integer_range_mapper_map_value(ByRef mapper As NativeMapper, value As Long, ByRef outValue As Double) As Integer
    End Function

    <DllImport(LibraryName, CallingConvention:=CallingConvention.Cdecl, ExactSpelling:=True)>
    Friend Function lrm_integer_range_mapper_get_spec(ByRef mapper As NativeMapper, ByRef outSpec As NativeSpec) As Integer
    End Function
End Module
