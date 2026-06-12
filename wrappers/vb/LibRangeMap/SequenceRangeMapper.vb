Imports System.Text.Json

Public Class SequenceRangeMapper(Of T, R)
    Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
        .PropertyNamingPolicy = Nothing,
        .WriteIndented = False
    }

    Private ReadOnly _elementMapper As Func(Of T, R)
    Private ReadOnly _allowEmpty As Boolean

    Public Sub New(elementMapper As Func(Of T, R), Optional allowEmpty As Boolean = False)
        If elementMapper Is Nothing Then
            Throw New ArgumentNullException(NameOf(elementMapper))
        End If

        _elementMapper = elementMapper
        _allowEmpty = allowEmpty
    End Sub

    Public Function MapValue(value As T()) As R()
        If value Is Nothing Then
            Throw New ArgumentNullException(NameOf(value))
        End If
        If value.Length = 0 AndAlso Not _allowEmpty Then
            Throw New ArgumentException("empty sequence input is invalid by default; set allowEmpty=True to map empty sequences.")
        End If
        If value.Length = 0 Then
            Return New R() {}
        End If

        Dim mapped(value.Length - 1) As R
        For index = 0 To value.Length - 1
            mapped(index) = _elementMapper(value(index))
        Next
        Return mapped
    End Function

    Public Function Map(value As T()) As R()
        Return MapValue(value)
    End Function

    Public Function Spec() As SequenceMapperSpec
        Return New SequenceMapperSpec With {
            .SpecVersion = CurrentSpecVersion,
            .MapperType = "sequence_range",
            .AllowEmpty = _allowEmpty
        }
    End Function

    Public Function ToJson() As String
        Return JsonSerializer.Serialize(Spec(), JsonOptions)
    End Function
End Class
