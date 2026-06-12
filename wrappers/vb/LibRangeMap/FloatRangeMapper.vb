Imports System.Text.Json
Imports System.Text.Json.Serialization

Public Class FloatRangeMapper
    Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
        .PropertyNamingPolicy = Nothing,
        .WriteIndented = False
    }

    Private ReadOnly _inputMin As Double
    Private ReadOnly _inputMax As Double
    Private ReadOnly _outputMin As Double
    Private ReadOnly _outputMax As Double
    Private ReadOnly _clip As Boolean

    Public Sub New(inputMin As Double, inputMax As Double, Optional outputMin As Double = -1.0, Optional outputMax As Double = 1.0, Optional clip As Boolean = False)
        If Double.IsNaN(inputMin) OrElse Double.IsInfinity(inputMin) OrElse Double.IsNaN(inputMax) OrElse Double.IsInfinity(inputMax) Then
            Throw New ArgumentException("input range endpoints must be finite.")
        End If
        If Double.IsNaN(outputMin) OrElse Double.IsInfinity(outputMin) OrElse Double.IsNaN(outputMax) OrElse Double.IsInfinity(outputMax) Then
            Throw New ArgumentException("output range endpoints must be finite.")
        End If
        If inputMin >= inputMax Then
            Throw New ArgumentException("inputMin must be less than inputMax.")
        End If
        If outputMin >= outputMax Then
            Throw New ArgumentException("outputMin must be less than outputMax.")
        End If

        _inputMin = inputMin
        _inputMax = inputMax
        _outputMin = outputMin
        _outputMax = outputMax
        _clip = clip
    End Sub

    Public Function MapValue(value As Double) As Double
        If Double.IsNaN(value) OrElse Double.IsInfinity(value) Then
            Throw New ArgumentException("value must be finite.")
        End If

        Dim bounded = value
        If bounded < _inputMin Then
            If Not _clip Then
                Throw New ArgumentOutOfRangeException(NameOf(value), "value is out of range.")
            End If
            bounded = _inputMin
        ElseIf bounded > _inputMax Then
            If Not _clip Then
                Throw New ArgumentOutOfRangeException(NameOf(value), "value is out of range.")
            End If
            bounded = _inputMax
        End If

        Return _outputMin + ((bounded - _inputMin) / (_inputMax - _inputMin)) * (_outputMax - _outputMin)
    End Function

    Public Function Map(value As Double) As Double
        Return MapValue(value)
    End Function

    Public Function Spec() As FloatMapperSpec
        Return New FloatMapperSpec With {
            .SpecVersion = CurrentSpecVersion,
            .MapperType = "float_range",
            .InputRange = New Double() {_inputMin, _inputMax},
            .OutputRange = New Double() {_outputMin, _outputMax},
            .Clip = _clip
        }
    End Function

    Public Function ToJson() As String
        Return JsonSerializer.Serialize(Spec(), JsonOptions)
    End Function

    Public Shared Function FromJson(json As String) As FloatRangeMapper
        Dim spec = JsonSerializer.Deserialize(Of FloatMapperSpec)(json, JsonOptions)
        If spec Is Nothing Then
            Throw New InvalidOperationException("mapper spec JSON produced null.")
        End If
        Return FromSpec(spec)
    End Function

    Public Shared Function FromSpec(spec As FloatMapperSpec) As FloatRangeMapper
        If spec.SpecVersion <> CurrentSpecVersion Then
            Throw New ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", NameOf(spec))
        End If
        If spec.MapperType <> "float_range" Then
            Throw New ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", NameOf(spec))
        End If
        If spec.InputRange Is Nothing OrElse spec.InputRange.Length <> 2 Then
            Throw New ArgumentException("input_range must contain exactly two values.", NameOf(spec))
        End If
        If spec.OutputRange Is Nothing OrElse spec.OutputRange.Length <> 2 Then
            Throw New ArgumentException("output_range must contain exactly two values.", NameOf(spec))
        End If
        Return New FloatRangeMapper(spec.InputRange(0), spec.InputRange(1), spec.OutputRange(0), spec.OutputRange(1), spec.Clip)
    End Function
End Class
