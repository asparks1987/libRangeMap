Imports System.Text.Json.Serialization

Public Module MapperSpecConstants
    Public Const CurrentSpecVersion As String = "1.0-alpha"
End Module

Public Class MapperSpec
    <JsonPropertyName("spec_version")>
    Public Property SpecVersion As String = CurrentSpecVersion

    <JsonPropertyName("mapper_type")>
    Public Property MapperType As String = "integer_range"

    <JsonPropertyName("input_range")>
    Public Property InputRange As Long() = New Long(1) {}

    <JsonPropertyName("output_range")>
    Public Property OutputRange As Double() = New Double(1) {}

    <JsonPropertyName("clip")>
    Public Property Clip As Boolean
End Class
