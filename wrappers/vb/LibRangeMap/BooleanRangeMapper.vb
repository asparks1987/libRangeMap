Imports System.Text.Json
Imports System.Text.Json.Serialization

Public Class BooleanRangeMapper
    Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
        .PropertyNamingPolicy = Nothing,
        .WriteIndented = False
    }

    Private ReadOnly _outputMin As Double
    Private ReadOnly _outputMax As Double
    Private ReadOnly _falseValue As Double
    Private ReadOnly _trueValue As Double

    Public Sub New(Optional outputMin As Double = -1.0, Optional outputMax As Double = 1.0, Optional falseValue As Double = -1.0, Optional trueValue As Double = 1.0)
        If Double.IsNaN(outputMin) OrElse Double.IsInfinity(outputMin) OrElse Double.IsNaN(outputMax) OrElse Double.IsInfinity(outputMax) OrElse Double.IsNaN(falseValue) OrElse Double.IsInfinity(falseValue) OrElse Double.IsNaN(trueValue) OrElse Double.IsInfinity(trueValue) Then
            Throw New ArgumentException("all range values must be finite.")
        End If
        If outputMin >= outputMax Then
            Throw New ArgumentException("outputMin must be less than outputMax.")
        End If
        If falseValue < outputMin OrElse falseValue > outputMax OrElse trueValue < outputMin OrElse trueValue > outputMax Then
            Throw New ArgumentException("boolean values must lie within the output range.")
        End If
        If falseValue = trueValue Then
            Throw New ArgumentException("falseValue and trueValue must differ.")
        End If

        _outputMin = outputMin
        _outputMax = outputMax
        _falseValue = falseValue
        _trueValue = trueValue
    End Sub

    Public Function MapValue(value As Boolean) As Double
        Return If(value, _trueValue, _falseValue)
    End Function

    Public Function Map(value As Boolean) As Double
        Return MapValue(value)
    End Function

    Public Function Spec() As BooleanMapperSpec
        Return New BooleanMapperSpec With {
            .SpecVersion = CurrentSpecVersion,
            .MapperType = "boolean_range",
            .OutputRange = New Double() {_outputMin, _outputMax},
            .FalseValue = _falseValue,
            .TrueValue = _trueValue
        }
    End Function

    Public Function ToJson() As String
        Return JsonSerializer.Serialize(Spec(), JsonOptions)
    End Function

    Public Shared Function FromJson(json As String) As BooleanRangeMapper
        Dim spec = JsonSerializer.Deserialize(Of BooleanMapperSpec)(json, JsonOptions)
        If spec Is Nothing Then
            Throw New InvalidOperationException("mapper spec JSON produced null.")
        End If
        Return FromSpec(spec)
    End Function

    Public Shared Function FromSpec(spec As BooleanMapperSpec) As BooleanRangeMapper
        If spec.SpecVersion <> CurrentSpecVersion Then
            Throw New ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", NameOf(spec))
        End If
        If spec.MapperType <> "boolean_range" Then
            Throw New ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", NameOf(spec))
        End If
        If spec.OutputRange Is Nothing OrElse spec.OutputRange.Length <> 2 Then
            Throw New ArgumentException("output_range must contain exactly two values.", NameOf(spec))
        End If
        Return New BooleanRangeMapper(spec.OutputRange(0), spec.OutputRange(1), spec.FalseValue, spec.TrueValue)
    End Function
End Class
