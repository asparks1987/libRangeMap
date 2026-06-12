Imports System.Collections.Generic
Imports System.Text.Json

Public Class CategoricalRangeMapper
    Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
        .PropertyNamingPolicy = Nothing,
        .WriteIndented = False
    }

    Private ReadOnly _vocabulary As String()
    Private ReadOnly _outputMin As Double
    Private ReadOnly _outputMax As Double

    Public Sub New(vocabulary As String(), Optional outputMin As Double = -1.0, Optional outputMax As Double = 1.0)
        If vocabulary Is Nothing Then
            Throw New ArgumentNullException(NameOf(vocabulary))
        End If
        If vocabulary.Length = 0 Then
            Throw New ArgumentException("vocabulary must not be empty.", NameOf(vocabulary))
        End If
        If Double.IsNaN(outputMin) OrElse Double.IsInfinity(outputMin) OrElse Double.IsNaN(outputMax) OrElse Double.IsInfinity(outputMax) Then
            Throw New ArgumentException("output range endpoints must be finite.")
        End If
        If outputMin >= outputMax Then
            Throw New ArgumentException("outputMin must be less than outputMax.")
        End If

        Dim seen As New HashSet(Of String)(StringComparer.Ordinal)
        For Each token In vocabulary
            If token Is Nothing OrElse token.Length = 0 Then
                Throw New ArgumentException("vocabulary tokens must be non-empty strings.", NameOf(vocabulary))
            End If
            If Not seen.Add(token) Then
                Throw New ArgumentException($"duplicate vocabulary token '{token}'.", NameOf(vocabulary))
            End If
        Next

        _vocabulary = DirectCast(vocabulary.Clone(), String())
        _outputMin = outputMin
        _outputMax = outputMax
    End Sub

    Public Function MapValue(value As String) As Double
        If value Is Nothing Then
            Throw New ArgumentNullException(NameOf(value))
        End If

        Dim index As Integer = Array.IndexOf(_vocabulary, value)
        If index < 0 Then
            Throw New ArgumentException($"unknown categorical token '{value}'.", NameOf(value))
        End If

        If _vocabulary.Length = 1 Then
            Return (_outputMin + _outputMax) / 2.0
        End If

        Return _outputMin + ((CDbl(index) / CDbl(_vocabulary.Length - 1)) * (_outputMax - _outputMin))
    End Function

    Public Function Map(value As String) As Double
        Return MapValue(value)
    End Function

    Public Function Spec() As CategoricalMapperSpec
        Return New CategoricalMapperSpec With {
            .SpecVersion = CurrentSpecVersion,
            .MapperType = "categorical_range",
            .Vocabulary = DirectCast(_vocabulary.Clone(), String()),
            .OutputRange = New Double() {_outputMin, _outputMax}
        }
    End Function

    Public Function ToJson() As String
        Return JsonSerializer.Serialize(Spec(), JsonOptions)
    End Function

    Public Shared Function FromJson(json As String) As CategoricalRangeMapper
        Dim spec = JsonSerializer.Deserialize(Of CategoricalMapperSpec)(json, JsonOptions)
        If spec Is Nothing Then
            Throw New InvalidOperationException("mapper spec JSON produced null.")
        End If
        Return FromSpec(spec)
    End Function

    Public Shared Function FromSpec(spec As CategoricalMapperSpec) As CategoricalRangeMapper
        If spec.SpecVersion <> CurrentSpecVersion Then
            Throw New ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", NameOf(spec))
        End If
        If spec.MapperType <> "categorical_range" Then
            Throw New ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", NameOf(spec))
        End If
        If spec.Vocabulary Is Nothing OrElse spec.Vocabulary.Length = 0 Then
            Throw New ArgumentException("vocabulary must contain at least one token.", NameOf(spec))
        End If
        If spec.OutputRange Is Nothing OrElse spec.OutputRange.Length <> 2 Then
            Throw New ArgumentException("output_range must contain exactly two values.", NameOf(spec))
        End If

        Return New CategoricalRangeMapper(spec.Vocabulary, spec.OutputRange(0), spec.OutputRange(1))
    End Function
End Class
