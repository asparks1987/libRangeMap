Imports System.Text.Json
Imports System.Text.Json.Serialization

Public Class ObjectMapperSpec
    <JsonPropertyName("spec_version")>
    Public Property SpecVersion As String = CurrentSpecVersion

    <JsonPropertyName("mapper_type")>
    Public Property MapperType As String = "map_range"

    <JsonPropertyName("schema")>
    Public Property Schema As Dictionary(Of String, JsonElement)

    <JsonPropertyName("allow_unknown")>
    Public Property AllowUnknown As Boolean

    <JsonPropertyName("allow_empty")>
    Public Property AllowEmpty As Boolean

    <JsonPropertyName("has_missing_value")>
    Public Property HasMissingValue As Boolean

    <JsonPropertyName("missing_value")>
    Public Property MissingValue As JsonElement?

    <JsonPropertyName("name")>
    Public Property Name As String
End Class
