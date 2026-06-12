Imports System.Text.Json
Imports System.Text.Json.Serialization

Public NotInheritable Class TemporalRangeMapper
        Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
            .PropertyNamingPolicy = Nothing,
            .WriteIndented = False
        }

        Private Const SpecType As String = "temporal_range"

        Public ReadOnly Property InputMin As Long
        Public ReadOnly Property InputMax As Long
        Public ReadOnly Property OutputMin As Double
        Public ReadOnly Property OutputMax As Double
        Public ReadOnly Property Clip As Boolean

        Public Sub New(
            inputMinUnixMilliseconds As Long,
            inputMaxUnixMilliseconds As Long,
            Optional outputMin As Double = -1.0,
            Optional outputMax As Double = 1.0,
            Optional clip As Boolean = False
        )
            If inputMaxUnixMilliseconds <= inputMinUnixMilliseconds Then
                Throw New ArgumentException("input_min must be less than input_max.")
            End If
            If outputMax <= outputMin Then
                Throw New ArgumentException("output_min must be less than output_max.")
            End If

            Me.InputMin = inputMinUnixMilliseconds
            Me.InputMax = inputMaxUnixMilliseconds
            Me.OutputMin = outputMin
            Me.OutputMax = outputMax
            Me.Clip = clip
        End Sub

        Public Function MapValue(value As Long) As Double
            Return MapUnixMilliseconds(value)
        End Function

        Public Function MapValue(value As DateTime) As Double
            If value.Kind = DateTimeKind.Unspecified Then
                Throw New ArgumentException("DateTimeKind.Unspecified is not supported; use UTC, Local, or DateTimeOffset.")
            End If

            Return MapUnixMilliseconds(New DateTimeOffset(value).ToUnixTimeMilliseconds())
        End Function

        Public Function MapValue(value As DateTimeOffset) As Double
            Return MapUnixMilliseconds(value.ToUnixTimeMilliseconds())
        End Function

        Public Function Spec() As TemporalMapperSpec
            Return New TemporalMapperSpec With {
                .SpecVersion = CurrentSpecVersion,
                .MapperType = SpecType,
                .InputUnit = "unix_milliseconds",
                .InputRange = New Long() {InputMin, InputMax},
                .OutputRange = New Double() {OutputMin, OutputMax},
                .Clip = Clip
            }
        End Function

        Public Function ToJson() As String
            Return JsonSerializer.Serialize(Spec(), JsonOptions)
        End Function

        Public Shared Function FromJson(json As String) As TemporalRangeMapper
            Dim spec = JsonSerializer.Deserialize(Of TemporalMapperSpec)(json, JsonOptions)
            If spec Is Nothing Then
                Throw New InvalidOperationException("mapper spec JSON produced null.")
            End If

            Return FromSpec(spec)
        End Function

        Public Shared Function FromSpec(spec As TemporalMapperSpec) As TemporalRangeMapper
            If spec.SpecVersion <> CurrentSpecVersion Then
                Throw New ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", NameOf(spec))
            End If
            If spec.MapperType <> SpecType Then
                Throw New ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", NameOf(spec))
            End If
            If spec.InputUnit <> "unix_milliseconds" Then
                Throw New ArgumentException($"unsupported input_unit '{spec.InputUnit}'.", NameOf(spec))
            End If
            If spec.InputRange Is Nothing OrElse spec.InputRange.Length <> 2 Then
                Throw New ArgumentException("input_range must contain exactly two values.", NameOf(spec))
            End If
            If spec.OutputRange Is Nothing OrElse spec.OutputRange.Length <> 2 Then
                Throw New ArgumentException("output_range must contain exactly two values.", NameOf(spec))
            End If

            Return New TemporalRangeMapper(
                spec.InputRange(0),
                spec.InputRange(1),
                spec.OutputRange(0),
                spec.OutputRange(1),
                spec.Clip)
        End Function

        Private Function MapUnixMilliseconds(value As Long) As Double
            Dim v As Long = value
            If value < InputMin Then
                If Not Clip Then
                    Throw New ArgumentOutOfRangeException(NameOf(value), $"value {value} is below input_min {InputMin}; enable clip to clamp.")
                End If
                v = InputMin
            ElseIf value > InputMax Then
                If Not Clip Then
                    Throw New ArgumentOutOfRangeException(NameOf(value), $"value {value} is above input_max {InputMax}; enable clip to clamp.")
                End If
                v = InputMax
            End If

            Return OutputMin + ((CDbl(v - InputMin) / CDbl(InputMax - InputMin)) * (OutputMax - OutputMin))
        End Function
End Class

Public NotInheritable Class TemporalMapperSpec
        <JsonPropertyName("spec_version")>
        Public Property SpecVersion As String = CurrentSpecVersion

        <JsonPropertyName("mapper_type")>
        Public Property MapperType As String = "temporal_range"

        <JsonPropertyName("input_unit")>
        Public Property InputUnit As String = "unix_milliseconds"

        <JsonPropertyName("input_range")>
        Public Property InputRange As Long() = New Long(1) {}

        <JsonPropertyName("output_range")>
        Public Property OutputRange As Double() = New Double(1) {}

        <JsonPropertyName("clip")>
        Public Property Clip As Boolean
End Class
