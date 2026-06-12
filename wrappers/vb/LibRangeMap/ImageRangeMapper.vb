Imports System.Text.Json

Public Class ImageRangeMapper
    Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
        .PropertyNamingPolicy = Nothing,
        .WriteIndented = False
    }

    Private ReadOnly _outputMin As Double
    Private ReadOnly _outputMax As Double
    Private ReadOnly _clip As Boolean
    Private ReadOnly _allowEmpty As Boolean

    Public Sub New(Optional outputMin As Double = -1.0, Optional outputMax As Double = 1.0, Optional clip As Boolean = False, Optional allowEmpty As Boolean = False)
        If Double.IsNaN(outputMin) OrElse Double.IsInfinity(outputMin) OrElse Double.IsNaN(outputMax) OrElse Double.IsInfinity(outputMax) Then
            Throw New ArgumentException("output range endpoints must be finite.")
        End If
        If outputMin >= outputMax Then
            Throw New ArgumentException("outputMin must be less than outputMax.")
        End If

        _outputMin = outputMin
        _outputMax = outputMax
        _clip = clip
        _allowEmpty = allowEmpty
    End Sub

    Public Function MapValue(value As Byte(), width As Integer, height As Integer, channels As Integer) As Double()
        If value Is Nothing Then
            Throw New ArgumentNullException(NameOf(value))
        End If
        If width <= 0 Then
            Throw New ArgumentException("image width must be positive.", NameOf(width))
        End If
        If height <= 0 Then
            Throw New ArgumentException("image height must be positive.", NameOf(height))
        End If
        If channels <= 0 Then
            Throw New ArgumentException("image channels must be positive.", NameOf(channels))
        End If
        If value.Length = 0 AndAlso Not _allowEmpty Then
            Throw New ArgumentException("empty image payload is invalid by default; set allowEmpty=True to map empty images.")
        End If
        If value.Length = 0 Then
            Return New Double() {}
        End If

        Dim expectedLength = width * height * channels
        If expectedLength <> value.Length Then
            Throw New ArgumentException($"image payload length {value.Length} does not match width*height*channels {expectedLength}.", NameOf(value))
        End If

        Dim mapped(value.Length - 1) As Double
        For index = 0 To value.Length - 1
            mapped(index) = _outputMin + ((CDbl(value(index)) / 255.0) * (_outputMax - _outputMin))
        Next
        Return mapped
    End Function

    Public Function Spec() As ImageMapperSpec
        Return New ImageMapperSpec With {
            .SpecVersion = CurrentSpecVersion,
            .MapperType = "image_range",
            .InputRange = New Long() {0, 255},
            .OutputRange = New Double() {_outputMin, _outputMax},
            .Clip = _clip,
            .AllowEmpty = _allowEmpty
        }
    End Function

    Public Function ToJson() As String
        Return JsonSerializer.Serialize(Spec(), JsonOptions)
    End Function

    Public Shared Function FromJson(json As String) As ImageRangeMapper
        Dim spec = JsonSerializer.Deserialize(Of ImageMapperSpec)(json, JsonOptions)
        If spec Is Nothing Then
            Throw New InvalidOperationException("mapper spec JSON produced null.")
        End If
        Return FromSpec(spec)
    End Function

    Public Shared Function FromSpec(spec As ImageMapperSpec) As ImageRangeMapper
        If spec.SpecVersion <> CurrentSpecVersion Then
            Throw New ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", NameOf(spec))
        End If
        If spec.MapperType <> "image_range" Then
            Throw New ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", NameOf(spec))
        End If
        If spec.OutputRange Is Nothing OrElse spec.OutputRange.Length <> 2 Then
            Throw New ArgumentException("output_range must contain exactly two values.", NameOf(spec))
        End If
        Return New ImageRangeMapper(spec.OutputRange(0), spec.OutputRange(1), spec.Clip, spec.AllowEmpty)
    End Function
End Class
