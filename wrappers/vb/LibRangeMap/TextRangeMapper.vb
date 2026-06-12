Imports System.Text
Imports System.Text.Json

Public Class TextRangeMapper
    Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
        .PropertyNamingPolicy = Nothing,
        .WriteIndented = False
    }

    Private ReadOnly _mode As String
    Private ReadOnly _alphabet As String
    Private ReadOnly _outputMin As Double
    Private ReadOnly _outputMax As Double
    Private ReadOnly _allowEmpty As Boolean

    Public Sub New(Optional mode As String = "codepoint", Optional alphabet As String = "", Optional outputMin As Double = -1.0, Optional outputMax As Double = 1.0, Optional allowEmpty As Boolean = False)
        If String.IsNullOrWhiteSpace(mode) Then
            Throw New ArgumentException("mode must not be empty.", NameOf(mode))
        End If
        If Double.IsNaN(outputMin) OrElse Double.IsInfinity(outputMin) OrElse Double.IsNaN(outputMax) OrElse Double.IsInfinity(outputMax) Then
            Throw New ArgumentException("output range endpoints must be finite.")
        End If
        If outputMin >= outputMax Then
            Throw New ArgumentException("outputMin must be less than outputMax.")
        End If

        Dim normalizedMode = mode.Trim().ToLowerInvariant()
        If normalizedMode <> "codepoint" AndAlso normalizedMode <> "byte" AndAlso normalizedMode <> "alphabet" Then
            Throw New ArgumentException($"unsupported text mode '{mode}'.", NameOf(mode))
        End If

        If normalizedMode = "alphabet" Then
            If String.IsNullOrEmpty(alphabet) Then
                Throw New ArgumentException("alphabet must not be empty for alphabet mode.", NameOf(alphabet))
            End If
            Dim seen As New HashSet(Of Char)()
            For Each ch In alphabet
                If Not seen.Add(ch) Then
                    Throw New ArgumentException($"duplicate alphabet token '{ch}'.", NameOf(alphabet))
                End If
            Next
        ElseIf alphabet <> "" Then
            Throw New ArgumentException("alphabet must be empty unless mode is alphabet.", NameOf(alphabet))
        End If

        _mode = normalizedMode
        _alphabet = alphabet
        _outputMin = outputMin
        _outputMax = outputMax
        _allowEmpty = allowEmpty
    End Sub

    Public Function MapValue(value As String) As Double()
        If value Is Nothing Then
            Throw New ArgumentNullException(NameOf(value))
        End If
        If value.Length = 0 AndAlso Not _allowEmpty Then
            Throw New ArgumentException("empty text input is invalid by default.", NameOf(value))
        End If

        If _mode = "byte" Then
            Dim bytes = Encoding.UTF8.GetBytes(value)
            If bytes.Length = 0 AndAlso Not _allowEmpty Then
                Throw New ArgumentException("empty text input is invalid by default.", NameOf(value))
            End If
            Dim mapped(bytes.Length - 1) As Double
            For index = 0 To bytes.Length - 1
                mapped(index) = _outputMin + ((CDbl(bytes(index)) / 255.0) * (_outputMax - _outputMin))
            Next
            Return mapped
        End If

        Dim runes = value.EnumerateRunes().ToArray()
        If runes.Length = 0 AndAlso Not _allowEmpty Then
            Throw New ArgumentException("empty text input is invalid by default.", NameOf(value))
        End If

        Dim mappedValues(runes.Length - 1) As Double
        If _mode = "alphabet" Then
            For index = 0 To runes.Length - 1
                Dim ch = ChrW(runes(index).Value)
                Dim position = _alphabet.IndexOf(ch)
                If position < 0 Then
                    Throw New ArgumentException($"unknown text token '{ch}'.", NameOf(value))
                End If
                If _alphabet.Length = 1 Then
                    mappedValues(index) = (_outputMin + _outputMax) / 2.0
                Else
                    mappedValues(index) = _outputMin + ((CDbl(position) / CDbl(_alphabet.Length - 1)) * (_outputMax - _outputMin))
                End If
            Next
            Return mappedValues
        End If

        For index = 0 To runes.Length - 1
            Dim current = CDbl(runes(index).Value)
            mappedValues(index) = _outputMin + ((current / 255.0) * (_outputMax - _outputMin))
        Next
        Return mappedValues
    End Function

    Public Function Map(value As String) As Double()
        Return MapValue(value)
    End Function

    Public Function Spec() As TextMapperSpec
        Return New TextMapperSpec With {
            .SpecVersion = CurrentSpecVersion,
            .MapperType = "text_range",
            .Mode = _mode,
            .Alphabet = _alphabet,
            .OutputRange = New Double() {_outputMin, _outputMax},
            .AllowEmpty = _allowEmpty
        }
    End Function

    Public Function ToJson() As String
        Return JsonSerializer.Serialize(Spec(), JsonOptions)
    End Function

    Public Shared Function FromJson(json As String) As TextRangeMapper
        Dim spec = JsonSerializer.Deserialize(Of TextMapperSpec)(json, JsonOptions)
        If spec Is Nothing Then
            Throw New InvalidOperationException("mapper spec JSON produced null.")
        End If
        Return FromSpec(spec)
    End Function

    Public Shared Function FromSpec(spec As TextMapperSpec) As TextRangeMapper
        If spec.SpecVersion <> CurrentSpecVersion Then
            Throw New ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", NameOf(spec))
        End If
        If spec.MapperType <> "text_range" Then
            Throw New ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", NameOf(spec))
        End If
        If spec.OutputRange Is Nothing OrElse spec.OutputRange.Length <> 2 Then
            Throw New ArgumentException("output_range must contain exactly two values.", NameOf(spec))
        End If
        Return New TextRangeMapper(spec.Mode, spec.Alphabet, spec.OutputRange(0), spec.OutputRange(1), spec.AllowEmpty)
    End Function
End Class
