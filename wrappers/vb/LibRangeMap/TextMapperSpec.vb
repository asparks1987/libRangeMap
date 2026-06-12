Imports System.Text.Json.Serialization

Public Class TextMapperSpec
    <JsonPropertyName("spec_version")>
    Public Property SpecVersion As String = CurrentSpecVersion

    <JsonPropertyName("mapper_type")>
    Public Property MapperType As String = "text_range"

    <JsonPropertyName("mode")>
    Public Property Mode As String = "codepoint"

    <JsonPropertyName("alphabet")>
    Public Property Alphabet As String = ""

    <JsonPropertyName("output_range")>
    Public Property OutputRange As Double() = New Double(1) {}

    <JsonPropertyName("allow_empty")>
    Public Property AllowEmpty As Boolean
End Class
