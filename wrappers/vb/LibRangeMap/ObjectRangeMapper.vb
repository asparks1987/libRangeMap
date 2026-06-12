Imports System.Collections
Imports System.Collections.Generic
Imports System.Linq
Imports System.Reflection
Imports System.Text.Json

Public Class ObjectRangeMapper
    Private Shared ReadOnly JsonOptions As New JsonSerializerOptions With {
        .PropertyNamingPolicy = Nothing,
        .WriteIndented = False
    }

    Private Const SpecType As String = "map_range"

    Private ReadOnly _schema As Dictionary(Of String, Object)
    Private ReadOnly _hasMissingValue As Boolean
    Private ReadOnly _missingValue As Object

    Public ReadOnly Property AllowUnknown As Boolean
    Public ReadOnly Property AllowEmpty As Boolean
    Public ReadOnly Property Name As String
    Public ReadOnly Property Schema As IReadOnlyDictionary(Of String, Object)
        Get
            Return _schema
        End Get
    End Property

    Public ReadOnly Property MissingValue As Object
        Get
            Return _missingValue
        End Get
    End Property

    Public ReadOnly Property HasMissingValue As Boolean
        Get
            Return _hasMissingValue
        End Get
    End Property

    Public Sub New(schema As IDictionary(Of String, Object), Optional allowUnknown As Boolean = False, Optional allowEmpty As Boolean = False, Optional name As String = Nothing, Optional hasMissingValue As Boolean = False, Optional missingValue As Object = Nothing)
        If schema Is Nothing Then
            Throw New ArgumentNullException(NameOf(schema), "schema payload must not be null.")
        End If

        Dim normalized = ValidateSchema(schema)
        If Not allowEmpty AndAlso normalized.Count = 0 Then
            Throw New ArgumentException("schema must include at least one field.")
        End If

        If name IsNot Nothing AndAlso name.Length = 0 Then
            Throw New ArgumentException("name must not be empty.", NameOf(name))
        End If

        _schema = normalized
        AllowUnknown = allowUnknown
        AllowEmpty = allowEmpty
        Me.Name = name

        _hasMissingValue = hasMissingValue
        _missingValue = missingValue
    End Sub

    Public Function MapValue(value As Object) As Dictionary(Of String, Object)
        Return Map(value)
    End Function

    Public Function Map(value As Object) As Dictionary(Of String, Object)
        If value Is Nothing Then
            Throw New ArgumentNullException(NameOf(value), "map payload must not be null.")
        End If

        If TypeOf value Is IDictionary Then
            Return MapDictionary(DirectCast(value, IDictionary))
        End If

        Return MapObject(value)
    End Function

    Public Function Spec() As ObjectMapperSpec
        Return ToSpec()
    End Function

    Public Function ToJson() As String
        Return JsonSerializer.Serialize(Spec(), JsonOptions)
    End Function

    Public Shared Function FromJson(json As String) As ObjectRangeMapper
        Dim spec = JsonSerializer.Deserialize(Of ObjectMapperSpec)(json, JsonOptions)
        If spec Is Nothing Then
            Throw New InvalidOperationException("mapper spec JSON produced null.")
        End If

        Return FromSpec(spec)
    End Function

    Public Shared Function FromSpec(spec As ObjectMapperSpec) As ObjectRangeMapper
        If spec.SpecVersion <> CurrentSpecVersion Then
            Throw New ArgumentException($"unsupported spec_version '{spec.SpecVersion}'.", NameOf(spec))
        End If

        If spec.MapperType <> SpecType Then
            Throw New ArgumentException($"unsupported mapper_type '{spec.MapperType}'.", NameOf(spec))
        End If

        If spec.Schema Is Nothing Then
            Throw New ArgumentException("schema is required for map mapper.", NameOf(spec))
        End If

        Dim schema As New Dictionary(Of String, Object)(spec.Schema.Count, StringComparer.Ordinal)
        For Each kvp In spec.Schema
            If String.IsNullOrWhiteSpace(kvp.Key) Then
                Throw New ArgumentException("schema field names must be non-empty strings.")
            End If
            schema(kvp.Key) = MapperFromSpecElement(kvp.Value)
        Next

        Dim missing As Object = Nothing
        If spec.HasMissingValue Then
            If spec.MissingValue.HasValue Then
                missing = JsonElementToObject(spec.MissingValue.Value)
            End If
        End If

        Return New ObjectRangeMapper(schema, spec.AllowUnknown, spec.AllowEmpty, spec.Name, spec.HasMissingValue, missing)
    End Function

    Private Shared Function ValidateSchema(schema As IDictionary(Of String, Object)) As Dictionary(Of String, Object)
        Dim normalized As New Dictionary(Of String, Object)(schema.Count, StringComparer.Ordinal)

        For Each field In schema
            If String.IsNullOrWhiteSpace(field.Key) Then
                Throw New InvalidOperationException("schema field names must be non-empty strings.")
            End If
            If field.Value Is Nothing Then
                Throw New ArgumentNullException($"schema field '{field.Key}' mapper")
            End If
            If normalized.ContainsKey(field.Key) Then
                Throw New ArgumentException($"duplicate schema field '{field.Key}'.")
            End If

            normalized(field.Key) = field.Value
        Next

        Return normalized
    End Function

    Private Function MapDictionary(mapInput As IDictionary) As Dictionary(Of String, Object)
        Dim input As New Dictionary(Of String, Object)(StringComparer.Ordinal)
        For Each entry As DictionaryEntry In mapInput
            Dim key = TryCast(entry.Key, String)
            If String.IsNullOrWhiteSpace(key) Then
                Throw New ArgumentException("map keys must be non-empty strings.")
            End If
            input(key) = entry.Value
        Next

        If input.Count = 0 AndAlso Not AllowEmpty Then
            Throw New ArgumentException("map payload must not be empty unless allowEmpty is true.")
        End If

        If Not AllowUnknown Then
            Dim unknownKeys = input.Keys.Where(Function(key) Not _schema.ContainsKey(key)).OrderBy(Function(key) key).ToArray()
            If unknownKeys.Length > 0 Then
                Throw New ArgumentException($"unknown schema fields: {String.Join(", ", unknownKeys)}; set allowUnknown=True to accept extra fields.")
            End If
        End If

        Return MapBySchema(input, "dictionary")
    End Function

    Private Function MapObject(value As Object) As Dictionary(Of String, Object)
        Dim input As New Dictionary(Of String, Object)(StringComparer.Ordinal)
        Dim valueType = value.GetType()

        For Each entry In ReadableMembers(valueType, value)
            input(entry.Key) = entry.Value
        Next

        If input.Count = 0 AndAlso Not AllowEmpty Then
            Throw New ArgumentException("map payload must not be empty unless allowEmpty is true.")
        End If

        If Not AllowUnknown Then
            Dim unknownMembers = ReadableMemberNames(valueType).Where(Function(fieldName) Not _schema.ContainsKey(fieldName)).OrderBy(Function(fieldName) fieldName).ToArray()
            If unknownMembers.Length > 0 Then
                Throw New ArgumentException($"map object has unknown fields: {String.Join(", ", unknownMembers)}; set allowUnknown=True to accept extras.")
            End If
        End If

        Return MapBySchema(input, "object")
    End Function

    Private Function MapBySchema(input As Dictionary(Of String, Object), context As String) As Dictionary(Of String, Object)
        Dim mapped As New Dictionary(Of String, Object)(StringComparer.Ordinal)

        For Each kvp In _schema
            Dim fieldName = kvp.Key
            Dim fieldMapper = kvp.Value
            Dim hasValue As Boolean
            Dim rawValue As Object = Nothing

            hasValue = input.TryGetValue(fieldName, rawValue)
            If hasValue Then
                mapped(fieldName) = MapField(fieldMapper, fieldName, rawValue, context)
                Continue For
            End If

            If HasMissingValue Then
                mapped(fieldName) = MissingValue
                Continue For
            End If

            Throw New KeyNotFoundException($"missing required field '{fieldName}' in {context}.")
        Next

        Return mapped
    End Function

    Private Shared Function MapField(mapper As Object, fieldName As String, fieldValue As Object, context As String) As Object
        If mapper Is Nothing Then
            Throw New InvalidOperationException($"schema field '{fieldName}' has no mapper configured.")
        End If

        If TypeOf mapper Is IntegerRangeMapper Then
            Return DirectCast(mapper, IntegerRangeMapper).MapValue(ConvertToLong(fieldValue, fieldName, context))
        End If

        If TypeOf mapper Is FloatRangeMapper Then
            Return DirectCast(mapper, FloatRangeMapper).MapValue(ConvertToDouble(fieldValue, fieldName, context))
        End If

        If TypeOf mapper Is BooleanRangeMapper Then
            Return DirectCast(mapper, BooleanRangeMapper).MapValue(ConvertToBoolean(fieldValue, fieldName, context))
        End If

        If TypeOf mapper Is BytesRangeMapper Then
            Return DirectCast(mapper, BytesRangeMapper).MapValue(ConvertToBytePayload(fieldValue, fieldName, context))
        End If

        If TypeOf mapper Is CategoricalRangeMapper Then
            Return DirectCast(mapper, CategoricalRangeMapper).MapValue(ConvertToToken(fieldValue, fieldName, context))
        End If

        If TypeOf mapper Is TextRangeMapper Then
            Return DirectCast(mapper, TextRangeMapper).MapValue(ConvertToSingleCharacter(fieldValue, fieldName, context))
        End If

        If TypeOf mapper Is ObjectRangeMapper Then
            Return DirectCast(mapper, ObjectRangeMapper).Map(fieldValue)
        End If

        Dim mapperType = mapper.GetType()
        If mapperType.Name.StartsWith("SequenceRangeMapper") Then
            Return InvokeSequenceMapper(mapper, fieldName, fieldValue, context)
        End If

        Throw New ArgumentException($"schema field '{fieldName}' must provide a supported mapper type.")
    End Function

    Private Shared Function InvokeSequenceMapper(mapper As Object, fieldName As String, fieldValue As Object, context As String) As Object
        If fieldValue Is Nothing Then
            Throw New ArgumentNullException($"field '{fieldName}'")
        End If

        Dim mapMethod As MethodInfo = GetCompatibleMapperMethod(mapper.GetType(), "MapValue", fieldValue)
        If mapMethod Is Nothing Then
            mapMethod = GetCompatibleMapperMethod(mapper.GetType(), "Map", fieldValue)
        End If

        If mapMethod Is Nothing Then
            Throw New ArgumentException($"schema field '{fieldName}' sequence mapper is incompatible for {context}.")
        End If

        Try
            Return mapMethod.Invoke(mapper, New Object() {fieldValue})
        Catch ex As TargetInvocationException When ex.InnerException IsNot Nothing
            Throw ex.InnerException
        End Try
    End Function

    Private Shared Function GetCompatibleMapperMethod(mapperType As Type, methodName As String, fieldValue As Object) As MethodInfo
        Dim methods = mapperType.GetMethods(BindingFlags.Public Or BindingFlags.Instance).Where(Function(method) method.Name = methodName AndAlso method.GetParameters().Length = 1)
        For Each method In methods
            Dim parameterType = method.GetParameters()(0).ParameterType
            If fieldValue Is Nothing Then
                If Not parameterType.IsValueType OrElse Nullable.GetUnderlyingType(parameterType) IsNot Nothing Then
                    Return method
                End If
                Continue For
            End If

            If parameterType Is GetType(Object) OrElse parameterType.IsAssignableFrom(fieldValue.GetType()) Then
                Return method
            End If
        Next

        Return Nothing
    End Function

    Private Shared Function ConvertToLong(value As Object, fieldName As String, context As String) As Long
        If value Is Nothing Then
            Throw New ArgumentException($"field '{fieldName}' expects integer values only when mapping from {context}.")
        End If

        If TypeOf value Is Boolean Then
            Throw New ArgumentException($"field '{fieldName}' expects integer values only.")
        End If

        Try
            Select Case True
                Case TypeOf value Is Byte
                    Return CLng(DirectCast(value, Byte))
                Case TypeOf value Is SByte
                    Return CLng(DirectCast(value, SByte))
                Case TypeOf value Is Short
                    Return CLng(DirectCast(value, Short))
                Case TypeOf value Is UShort
                    Return CLng(DirectCast(value, UShort))
                Case TypeOf value Is Integer
                    Return CLng(DirectCast(value, Integer))
                Case TypeOf value Is UInteger
                    Return CLng(DirectCast(value, UInteger))
                Case TypeOf value Is Long
                    Return CLng(DirectCast(value, Long))
                Case TypeOf value Is ULong
                    Return Convert.ToInt64(DirectCast(value, ULong))
                Case Else
                    Throw New ArgumentException($"field '{fieldName}' expects integer values only.")
            End Select
        Catch ex As OverflowException
            Throw New ArgumentException($"field '{fieldName}' integer value is out of supported range.")
        End Try
    End Function

    Private Shared Function ConvertToDouble(value As Object, fieldName As String, context As String) As Double
        If value Is Nothing Then
            Throw New ArgumentException($"field '{fieldName}' expects float values only when mapping from {context}.")
        End If

        Select Case True
            Case TypeOf value Is Single
                Return CDbl(DirectCast(value, Single))
            Case TypeOf value Is Double
                Return CDbl(DirectCast(value, Double))
            Case TypeOf value Is Decimal
                Return CDbl(DirectCast(value, Decimal))
            Case Else
                Throw New ArgumentException($"field '{fieldName}' expects float values only.")
        End Select
    End Function

    Private Shared Function ConvertToBoolean(value As Object, fieldName As String, context As String) As Boolean
        If value Is Nothing Then
            Throw New ArgumentException($"field '{fieldName}' expects boolean values only when mapping from {context}.")
        End If

        If TypeOf value Is Boolean Then
            Return DirectCast(value, Boolean)
        End If

        Throw New ArgumentException($"field '{fieldName}' expects boolean values only.")
    End Function

    Private Shared Function ConvertToBytePayload(value As Object, fieldName As String, context As String) As Byte()
        If value Is Nothing Then
            Throw New ArgumentException($"field '{fieldName}' expects a byte array when mapping from {context}.")
        End If

        Dim bytes = TryCast(value, Byte())
        If bytes Is Nothing Then
            Throw New ArgumentException($"field '{fieldName}' expects a byte array when mapping from {context}.")
        End If

        Return bytes
    End Function

    Private Shared Function ConvertToToken(value As Object, fieldName As String, context As String) As String
        If value Is Nothing Then
            Throw New ArgumentException($"field '{fieldName}' expects a categorical token when mapping from {context}.")
        End If

        Dim token = TryCast(value, String)
        If token Is Nothing Then
            Throw New ArgumentException($"field '{fieldName}' expects a categorical token when mapping from {context}.")
        End If

        Return token
    End Function

    Private Shared Function ConvertToSingleCharacter(value As Object, fieldName As String, context As String) As Char
        If value Is Nothing Then
            Throw New ArgumentException($"field '{fieldName}' expects a single character when mapping from {context}.")
        End If

        If TypeOf value Is Char Then
            Return DirectCast(value, Char)
        End If

        Dim text = TryCast(value, String)
        If text IsNot Nothing AndAlso text.Length = 1 Then
            Return text(0)
        End If

        Throw New ArgumentException($"field '{fieldName}' expects a single character when mapping from {context}.")
    End Function

    Private Shared Function ReadableMemberNames(valueType As Type) As String()
        Dim names As New List(Of String)()

        For Each propertyInfo In valueType.GetProperties(BindingFlags.Instance Or BindingFlags.Public)
            If propertyInfo.GetMethod IsNot Nothing AndAlso propertyInfo.GetIndexParameters().Length = 0 Then
                names.Add(propertyInfo.Name)
            End If
        Next

        For Each fieldInfo In valueType.GetFields(BindingFlags.Instance Or BindingFlags.Public)
            names.Add(fieldInfo.Name)
        Next

        Return names.ToArray()
    End Function

    Private Shared Function ReadableMembers(valueType As Type, value As Object) As Dictionary(Of String, Object)
        Dim members As New Dictionary(Of String, Object)(StringComparer.Ordinal)

        For Each propertyInfo In valueType.GetProperties(BindingFlags.Instance Or BindingFlags.Public)
            If propertyInfo.GetMethod Is Nothing OrElse propertyInfo.GetIndexParameters().Length > 0 Then
                Continue For
            End If

            members(propertyInfo.Name) = propertyInfo.GetValue(value)
        Next

        For Each fieldInfo In valueType.GetFields(BindingFlags.Instance Or BindingFlags.Public)
            members(fieldInfo.Name) = fieldInfo.GetValue(value)
        Next

        Return members
    End Function

    Private Function ToSpec() As ObjectMapperSpec
        Dim schema As New Dictionary(Of String, JsonElement)(StringComparer.Ordinal)

        For Each kvp In _schema
            schema(kvp.Key) = JsonDocument.Parse(SerializeMapper(kvp.Value)).RootElement.Clone()
        Next

        Dim missingElement As JsonElement? = Nothing
        If _hasMissingValue Then
            If _missingValue Is Nothing Then
                Using nullDoc As JsonDocument = JsonDocument.Parse("null")
                    missingElement = nullDoc.RootElement.Clone()
                End Using
            Else
                Using valueDoc As JsonDocument = JsonSerializer.SerializeToDocument(_missingValue, JsonOptions)
                    missingElement = valueDoc.RootElement.Clone()
                End Using
            End If
        End If

        Return New ObjectMapperSpec With {
            .SpecVersion = CurrentSpecVersion,
            .MapperType = SpecType,
            .Schema = schema,
            .AllowUnknown = AllowUnknown,
            .AllowEmpty = AllowEmpty,
            .HasMissingValue = _hasMissingValue,
            .MissingValue = missingElement,
            .Name = Name
        }
    End Function

    Private Shared Function SerializeMapper(mapper As Object) As String
        If TypeOf mapper Is IntegerRangeMapper Then
            Return DirectCast(mapper, IntegerRangeMapper).ToJson()
        End If
        If TypeOf mapper Is FloatRangeMapper Then
            Return DirectCast(mapper, FloatRangeMapper).ToJson()
        End If
        If TypeOf mapper Is BooleanRangeMapper Then
            Return DirectCast(mapper, BooleanRangeMapper).ToJson()
        End If
        If TypeOf mapper Is BytesRangeMapper Then
            Return DirectCast(mapper, BytesRangeMapper).ToJson()
        End If
        If TypeOf mapper Is CategoricalRangeMapper Then
            Return DirectCast(mapper, CategoricalRangeMapper).ToJson()
        End If
        If TypeOf mapper Is TextRangeMapper Then
            Return DirectCast(mapper, TextRangeMapper).ToJson()
        End If
        If TypeOf mapper Is ObjectRangeMapper Then
            Return DirectCast(mapper, ObjectRangeMapper).ToJson()
        End If

        Dim mapperType = mapper.GetType()
        If mapperType.Name.StartsWith("SequenceRangeMapper") Then
            Dim toJsonMethod = mapperType.GetMethod("ToJson")
            If toJsonMethod IsNot Nothing Then
                Return CStr(toJsonMethod.Invoke(mapper, Array.Empty(Of Object)()))
            End If
        End If

        Throw New InvalidOperationException("unsupported mapper type for schema.")
    End Function

    Private Shared Function MapperFromSpecElement(mapperElement As JsonElement) As Object
        If mapperElement.ValueKind <> JsonValueKind.Object Then
            Throw New InvalidOperationException("schema values must be mapper spec objects.")
        End If

        Dim mapperTypeElement As JsonElement
        If Not mapperElement.TryGetProperty("mapper_type", mapperTypeElement) Then
            Throw New InvalidOperationException("schema values require a mapper_type field.")
        End If

        If mapperTypeElement.ValueKind <> JsonValueKind.String Then
            Throw New InvalidOperationException("schema values require a valid mapper_type string.")
        End If

        Dim mapperType = mapperTypeElement.GetString()
        Select Case mapperType
            Case "integer_range"
                Return IntegerRangeMapper.FromJson(mapperElement.GetRawText())
            Case "float_range"
                Return FloatRangeMapper.FromJson(mapperElement.GetRawText())
            Case "boolean_range"
                Return BooleanRangeMapper.FromJson(mapperElement.GetRawText())
            Case "bytes_range"
                Return BytesRangeMapper.FromJson(mapperElement.GetRawText())
            Case "categorical_range"
                Return CategoricalRangeMapper.FromJson(mapperElement.GetRawText())
            Case "text_range"
                Return TextRangeMapper.FromJson(mapperElement.GetRawText())
            Case "map_range"
                Return FromSpec(JsonSerializer.Deserialize(Of ObjectMapperSpec)(mapperElement.GetRawText(), JsonOptions))
            Case "sequence_range"
                Throw New NotSupportedException("sequence_range specs are not supported by ObjectRangeMapper.FromSpec in Visual Basic wrapper yet.")
            Case Else
                Throw New InvalidOperationException($"unsupported mapper_type '{mapperType}'.")
        End Select
    End Function

    Private Shared Function JsonElementToObject(element As JsonElement) As Object
        Select Case element.ValueKind
            Case JsonValueKind.String
                Return element.GetString()
            Case JsonValueKind.Number
                Dim intValue As Long
                If element.TryGetInt64(intValue) Then
                    Return intValue
                End If
                Return element.GetDouble()
            Case JsonValueKind.True
                Return True
            Case JsonValueKind.False
                Return False
            Case JsonValueKind.Null
                Return Nothing
            Case JsonValueKind.Object
                Return JsonSerializer.Deserialize(Of Dictionary(Of String, Object))(element.GetRawText(), JsonOptions)
            Case JsonValueKind.Array
                Return JsonSerializer.Deserialize(Of List(Of Object))(element.GetRawText(), JsonOptions)
            Case Else
                Throw New InvalidOperationException("unsupported missing_value JSON kind.")
        End Select
    End Function
End Class
