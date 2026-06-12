Imports System.Text.Json.Serialization

Public Class BooleanMapperSpec
    <JsonPropertyName("spec_version")>
    Public Property SpecVersion As String = CurrentSpecVersion

    <JsonPropertyName("mapper_type")>
    Public Property MapperType As String = "boolean_range"

    <JsonPropertyName("output_range")>
    Public Property OutputRange As Double() = New Double(1) {}

    <JsonPropertyName("false_value")>
    Public Property FalseValue As Double

    <JsonPropertyName("true_value")>
    Public Property TrueValue As Double
End Class
