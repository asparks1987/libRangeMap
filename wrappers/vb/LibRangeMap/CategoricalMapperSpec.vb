Imports System.Text.Json.Serialization

Public Class CategoricalMapperSpec
    <JsonPropertyName("spec_version")>
    Public Property SpecVersion As String = CurrentSpecVersion

    <JsonPropertyName("mapper_type")>
    Public Property MapperType As String = "categorical_range"

    <JsonPropertyName("vocabulary")>
    Public Property Vocabulary As String() = Array.Empty(Of String)()

    <JsonPropertyName("output_range")>
    Public Property OutputRange As Double() = New Double() { -1.0, 1.0 }
End Class
