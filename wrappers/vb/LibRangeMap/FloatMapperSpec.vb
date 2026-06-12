Imports System.Text.Json.Serialization

Public Class FloatMapperSpec
    <JsonPropertyName("spec_version")>
    Public Property SpecVersion As String = CurrentSpecVersion

    <JsonPropertyName("mapper_type")>
    Public Property MapperType As String = "float_range"

    <JsonPropertyName("input_range")>
    Public Property InputRange As Double() = New Double(1) {}

    <JsonPropertyName("output_range")>
    Public Property OutputRange As Double() = New Double(1) {}

    <JsonPropertyName("clip")>
    Public Property Clip As Boolean
End Class
