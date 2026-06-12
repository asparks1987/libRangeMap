Imports System.Text.Json.Serialization

Public Class ImageMapperSpec
    <JsonPropertyName("spec_version")>
    Public Property SpecVersion As String = CurrentSpecVersion

    <JsonPropertyName("mapper_type")>
    Public Property MapperType As String = "image_range"

    <JsonPropertyName("input_range")>
    Public Property InputRange As Long() = New Long() {0, 255}

    <JsonPropertyName("output_range")>
    Public Property OutputRange As Double() = New Double() { -1.0, 1.0 }

    <JsonPropertyName("clip")>
    Public Property Clip As Boolean

    <JsonPropertyName("allow_empty")>
    Public Property AllowEmpty As Boolean
End Class
