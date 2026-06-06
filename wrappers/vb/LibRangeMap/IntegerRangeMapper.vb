Imports System.Text.Json

Public Class IntegerRangeMapper
    Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
        .PropertyNamingPolicy = Nothing,
        .WriteIndented = False
    }

    Private _native As NativeMethods.NativeMapper

    Public Sub New(inputMin As Long, inputMax As Long, Optional outputMin As Double = -1.0, Optional outputMax As Double = 1.0, Optional clip As Boolean = False)
        Dim mapper As New NativeMethods.NativeMapper()
        Dim status = NativeMethods.lrm_integer_range_mapper_init(mapper, inputMin, inputMax, outputMin, outputMax, If(clip, 1, 0))
        If status <> 0 Then
            Throw CreateException("init", status)
        End If
        _native = mapper
    End Sub

    Private Sub New(nativeMapper As NativeMethods.NativeMapper)
        _native = nativeMapper
    End Sub

    Public Function MapValue(value As Long) As Double
        Dim mapped As Double
        Dim status = NativeMethods.lrm_integer_range_mapper_map_value(_native, value, mapped)
        If status <> 0 Then
            Throw CreateException("map_value", status)
        End If
        Return mapped
    End Function

    Public Function Map(value As Long) As Double
        Return MapValue(value)
    End Function

    Public Function Spec() As MapperSpec
        Dim nativeSpec As New NativeMethods.NativeSpec()
        Dim status = NativeMethods.lrm_integer_range_mapper_get_spec(_native, nativeSpec)
        If status <> 0 Then
            Throw CreateException("get_spec", status)
        End If

        Return New MapperSpec With {
            .SpecVersion = CurrentSpecVersion,
            .MapperType = "integer_range",
            .InputRange = New Long() {nativeSpec.InputMin, nativeSpec.InputMax},
            .OutputRange = New Double() {nativeSpec.OutputMin, nativeSpec.OutputMax},
            .Clip = nativeSpec.Clip <> 0
        }
    End Function

    Public Function ToJson() As String
        Return JsonSerializer.Serialize(Spec(), JsonOptions)
    End Function

    Public Shared Function FromJson(json As String) As IntegerRangeMapper
        Dim spec = JsonSerializer.Deserialize(Of MapperSpec)(json, JsonOptions)
        If spec Is Nothing Then
            Throw New InvalidOperationException("mapper spec JSON produced null.")
        End If
        Return FromSpec(spec)
    End Function

    Public Shared Function FromSpec(spec As MapperSpec) As IntegerRangeMapper
        If spec.SpecVersion <> CurrentSpecVersion Then
            Throw New ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", NameOf(spec))
        End If

        If spec.MapperType <> "integer_range" Then
            Throw New ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", NameOf(spec))
        End If

        If spec.InputRange Is Nothing OrElse spec.InputRange.Length <> 2 Then
            Throw New ArgumentException("input_range must contain exactly two values.", NameOf(spec))
        End If

        If spec.OutputRange Is Nothing OrElse spec.OutputRange.Length <> 2 Then
            Throw New ArgumentException("output_range must contain exactly two values.", NameOf(spec))
        End If

        Return New IntegerRangeMapper(
            spec.InputRange(0),
            spec.InputRange(1),
            spec.OutputRange(0),
            spec.OutputRange(1),
            spec.Clip)
    End Function

    Private Shared Function CreateException(operation As String, status As Integer) As Exception
        Select Case status
            Case 1
                Return New ArgumentException($"librangemap {operation} failed: invalid range.")
            Case 2
                Return New InvalidOperationException($"librangemap {operation} failed: invalid value.")
            Case 3
                Return New ArgumentOutOfRangeException(NameOf(operation), $"librangemap {operation} failed: out of range.")
            Case 4
                Return New InvalidOperationException($"librangemap {operation} failed: null pointer.")
            Case Else
                Return New InvalidOperationException($"librangemap {operation} failed with native status {status}.")
        End Select
    End Function
End Class
