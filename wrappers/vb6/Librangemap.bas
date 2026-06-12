Option Explicit

Public Function MapIntegerValue(ByVal value As Long, ByVal inputMin As Long, ByVal inputMax As Long, _
                               Optional ByVal outputMin As Double = -1#, _
                               Optional ByVal outputMax As Double = 1#, _
                               Optional ByVal clip As Boolean = False) As Double
    Dim boundedValue As Long
    If inputMin >= inputMax Then
        Err.Raise vbObjectError + 1001, "libRangeMap", "input_min must be less than input_max"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If

    boundedValue = value
    If clip Then
        If boundedValue < inputMin Then boundedValue = inputMin
        If boundedValue > inputMax Then boundedValue = inputMax
    Else
        If boundedValue < inputMin Or boundedValue > inputMax Then
            Err.Raise vbObjectError + 1003, "libRangeMap", "value out of range"
        End If
    End If

    MapIntegerValue = outputMin + ((boundedValue - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin)
End Function

Public Function MapFloatValue(ByVal value As Double, ByVal inputMin As Double, ByVal inputMax As Double, _
                              Optional ByVal outputMin As Double = -1#, _
                              Optional ByVal outputMax As Double = 1#, _
                              Optional ByVal clip As Boolean = False) As Double
    Dim boundedValue As Double
    If IsNull(value) Then Err.Raise vbObjectError + 1010, "libRangeMap", "value must be finite"
    If value <> value Then Err.Raise vbObjectError + 1010, "libRangeMap", "value must be finite"
    If inputMin <> inputMin Or inputMax <> inputMax Or outputMin <> outputMin Or outputMax <> outputMax Then
        Err.Raise vbObjectError + 1011, "libRangeMap", "range endpoints must be finite"
    End If
    If inputMin >= inputMax Then
        Err.Raise vbObjectError + 1001, "libRangeMap", "input_min must be less than input_max"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If

    boundedValue = value
    If clip Then
        If boundedValue < inputMin Then boundedValue = inputMin
        If boundedValue > inputMax Then boundedValue = inputMax
    Else
        If boundedValue < inputMin Or boundedValue > inputMax Then
            Err.Raise vbObjectError + 1003, "libRangeMap", "value out of range"
        End If
    End If

    MapFloatValue = outputMin + ((boundedValue - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin)
End Function

Public Function MapBooleanValue(ByVal value As Boolean, Optional ByVal outputMin As Double = -1#, _
                                Optional ByVal outputMax As Double = 1#, _
                                Optional ByVal falseValue As Double = -1#, _
                                Optional ByVal trueValue As Double = 1#) As Double
    If outputMin <> outputMin Or outputMax <> outputMax Or falseValue <> falseValue Or trueValue <> trueValue Then
        Err.Raise vbObjectError + 1011, "libRangeMap", "output values must be finite"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If
    If falseValue < outputMin Or falseValue > outputMax Or trueValue < outputMin Or trueValue > outputMax Then
        Err.Raise vbObjectError + 1004, "libRangeMap", "false_value/true_value must be within output range"
    End If
    If falseValue = trueValue Then
        Err.Raise vbObjectError + 1005, "libRangeMap", "false_value and true_value must differ"
    End If

    If value Then
        MapBooleanValue = trueValue
    Else
        MapBooleanValue = falseValue
    End If
End Function

Public Function MapTextValue(ByVal value As String, Optional ByVal outputMin As Double = -1#, _
                             Optional ByVal outputMax As Double = 1#, _
                             Optional ByVal mode As String = "codepoint", _
                             Optional ByVal alphabet As String = "", _
                             Optional ByVal clip As Boolean = False, _
                             Optional ByVal allowEmpty As Boolean = False) As Variant
    Dim i As Long
    Dim output() As Double
    Dim current As Double
    Dim charCode As Long
    Dim tokenCount As Long
    Dim index As Long
    Dim candidate As String

    If outputMin <> outputMin Or outputMax <> outputMax Then
        Err.Raise vbObjectError + 1011, "libRangeMap", "output range endpoints must be finite"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If

    If Len(value) = 0 Then
        If allowEmpty Then
            MapTextValue = Array()
            Exit Function
        End If
        Err.Raise vbObjectError + 1017, "libRangeMap", "empty text input is invalid by default"
    End If

    If StrComp(mode, "codepoint", vbTextCompare) = 0 Then
        ReDim output(0 To Len(value) - 1)
        For i = 1 To Len(value)
            charCode = AscW(Mid$(value, i, 1))
            If charCode < 0 Then charCode = charCode + 65536
            If clip Then
                If charCode < 0 Then charCode = 0
                If charCode > 65535 Then charCode = 65535
            ElseIf charCode < 0 Or charCode > 65535 Then
                Err.Raise vbObjectError + 1018, "libRangeMap", "codepoint out of range"
            End If
            output(i - 1) = outputMin + ((charCode / 65535#) * (outputMax - outputMin))
        Next i
        MapTextValue = output
        Exit Function
    End If

    If StrComp(mode, "alphabet", vbTextCompare) = 0 Then
        If Len(alphabet) < 2 Then
            Err.Raise vbObjectError + 1019, "libRangeMap", "alphabet must contain at least two unique characters"
        End If
        tokenCount = Len(alphabet)
        For i = 1 To tokenCount
            candidate = Mid$(alphabet, i, 1)
            If InStr(i + 1, alphabet, candidate, vbBinaryCompare) > 0 Then
                Err.Raise vbObjectError + 1020, "libRangeMap", "alphabet must contain unique characters"
            End If
        Next i

        ReDim output(0 To Len(value) - 1)
        For i = 1 To Len(value)
            candidate = Mid$(value, i, 1)
            index = InStr(1, alphabet, candidate, vbBinaryCompare)
            If index = 0 Then
                Err.Raise vbObjectError + 1021, "libRangeMap", "unknown categorical token"
            End If
            index = index - 1
            If tokenCount = 1 Then
                current = (outputMin + outputMax) / 2#
            Else
                current = outputMin + ((index / (tokenCount - 1)) * (outputMax - outputMin))
            End If
            output(i - 1) = current
        Next i
        MapTextValue = output
        Exit Function
    End If

    Err.Raise vbObjectError + 1022, "libRangeMap", "mode must be codepoint or alphabet"
End Function

Public Function MapBytesValue(ByVal value As Variant, Optional ByVal outputMin As Double = -1#, _
                              Optional ByVal outputMax As Double = 1#, _
                              Optional ByVal clip As Boolean = False, _
                              Optional ByVal allowEmpty As Boolean = False) As Variant
    Dim lowerBound As Long
    Dim upperBound As Long
    Dim i As Long
    Dim current As Double
    Dim output() As Double

    If outputMin <> outputMin Or outputMax <> outputMax Then
        Err.Raise vbObjectError + 1011, "libRangeMap", "output range endpoints must be finite"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If
    If Not IsArray(value) Then
        Err.Raise vbObjectError + 1012, "libRangeMap", "value must be a byte array"
    End If

    lowerBound = LBound(value)
    upperBound = UBound(value)
    If upperBound < lowerBound Then
        If allowEmpty Then
            MapBytesValue = Array()
            Exit Function
        End If
        Err.Raise vbObjectError + 1013, "libRangeMap", "empty bytes input is invalid by default"
    End If

    ReDim output(0 To upperBound - lowerBound)
    For i = lowerBound To upperBound
        If IsNumeric(value(i)) = False Then
            Err.Raise vbObjectError + 1014, "libRangeMap", "bytes values must be numeric"
        End If
        If value(i) <> Fix(value(i)) Then
            Err.Raise vbObjectError + 1015, "libRangeMap", "bytes values must be integers"
        End If
        current = CDbl(value(i))
        If clip Then
            If current < 0# Then current = 0#
            If current > 255# Then current = 255#
        ElseIf current < 0# Or current > 255# Then
            Err.Raise vbObjectError + 1016, "libRangeMap", "byte value out of range"
        End If
        output(i - lowerBound) = outputMin + ((current / 255#) * (outputMax - outputMin))
    Next i

    MapBytesValue = output
End Function

Public Function MapCategoricalValue(ByVal value As Variant, ByVal tokens As Variant, Optional ByVal outputMin As Double = -1#, _
                                    Optional ByVal outputMax As Double = 1#) As Double
    Dim i As Long
    Dim tokenCount As Long
    Dim index As Long
    Dim tokenValue As Variant

    If outputMin <> outputMin Or outputMax <> outputMax Then
        Err.Raise vbObjectError + 1011, "libRangeMap", "output range endpoints must be finite"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If
    If Not IsArray(tokens) Then
        Err.Raise vbObjectError + 1012, "libRangeMap", "tokens must be an array"
    End If

    On Error GoTo EmptyTokens
    tokenCount = UBound(tokens) - LBound(tokens) + 1
    On Error GoTo 0

    If tokenCount <= 0 Then
        Err.Raise vbObjectError + 1013, "libRangeMap", "tokens must not be empty"
    End If

    For i = LBound(tokens) To UBound(tokens)
        tokenValue = tokens(i)
        If i < UBound(tokens) Then
            Dim j As Long
            For j = i + 1 To UBound(tokens)
                If TokensEqual(tokenValue, tokens(j)) Then
                    Err.Raise vbObjectError + 1014, "libRangeMap", "tokens must be unique"
                End If
            Next j
        End If
        If TokensEqual(tokenValue, value) Then
            index = i - LBound(tokens)
        End If
    Next i

    If index = 0 And Not TokensEqual(tokens(LBound(tokens)), value) Then
        Err.Raise vbObjectError + 1015, "libRangeMap", "unknown categorical token"
    End If

    If tokenCount = 1 Then
        MapCategoricalValue = (outputMin + outputMax) / 2#
        Exit Function
    End If

    MapCategoricalValue = outputMin + ((index / (tokenCount - 1)) * (outputMax - outputMin))
    Exit Function

EmptyTokens:
    Err.Raise vbObjectError + 1013, "libRangeMap", "tokens must not be empty"
End Function

Public Function MapIntegerSequenceValue(ByVal values As Variant, ByVal inputMin As Long, ByVal inputMax As Long, _
                                        Optional ByVal outputMin As Double = -1#, _
                                        Optional ByVal outputMax As Double = 1#, _
                                        Optional ByVal clip As Boolean = False) As Variant
    Dim lowerBound As Long
    Dim upperBound As Long
    Dim i As Long
    Dim output() As Variant

    If Not IsArray(values) Then
        Err.Raise vbObjectError + 1023, "libRangeMap", "values must be an array"
    End If

    On Error GoTo EmptyValues
    lowerBound = LBound(values)
    upperBound = UBound(values)
    On Error GoTo 0

    If upperBound < lowerBound Then
        Err.Raise vbObjectError + 1024, "libRangeMap", "empty sequence input is invalid by default"
    End If

    ReDim output(0 To upperBound - lowerBound)
    For i = lowerBound To upperBound
        If IsArray(values(i)) Then
            output(i - lowerBound) = MapIntegerNestedSequenceValue(values(i), inputMin, inputMax, outputMin, outputMax, clip)
        Else
            output(i - lowerBound) = MapIntegerValue(CLng(values(i)), inputMin, inputMax, outputMin, outputMax, clip)
        End If
    Next i

    MapIntegerSequenceValue = output
    Exit Function

EmptyValues:
    Err.Raise vbObjectError + 1024, "libRangeMap", "empty sequence input is invalid by default"
End Function

Public Function MapIntegerNestedSequenceValue(ByVal values As Variant, ByVal inputMin As Long, ByVal inputMax As Long, _
                                              Optional ByVal outputMin As Double = -1#, _
                                              Optional ByVal outputMax As Double = 1#, _
                                              Optional ByVal clip As Boolean = False) As Variant
    Dim lowerBound As Long
    Dim upperBound As Long
    Dim i As Long
    Dim output() As Variant

    If Not IsArray(values) Then
        Err.Raise vbObjectError + 1023, "libRangeMap", "values must be an array"
    End If

    On Error GoTo EmptyValues
    lowerBound = LBound(values)
    upperBound = UBound(values)
    On Error GoTo 0

    If upperBound < lowerBound Then
        Err.Raise vbObjectError + 1024, "libRangeMap", "empty sequence input is invalid by default"
    End If

    ReDim output(0 To upperBound - lowerBound)
    For i = lowerBound To upperBound
        output(i - lowerBound) = MapIntegerSequenceValue(values(i), inputMin, inputMax, outputMin, outputMax, clip)
    Next i

    MapIntegerNestedSequenceValue = output
    Exit Function

EmptyValues:
    Err.Raise vbObjectError + 1024, "libRangeMap", "empty sequence input is invalid by default"
End Function

Public Function MapObjectValue(ByVal values As Variant, ByVal schema As Variant, _
                              Optional ByVal outputMin As Double = -1#, _
                              Optional ByVal outputMax As Double = 1#, _
                              Optional ByVal clip As Boolean = False, _
                              Optional ByVal allowMissing As Boolean = False, _
                              Optional ByVal allowUnknownFields As Boolean = False) As Variant
    Dim valuesMap As Object
    Dim schemaMap As Object
    Dim mappedValues As Object
    Dim i As Long
    Dim outputKeys As Variant
    Dim valueKeys As Variant
    Dim requiredKey As String
    Dim fieldSpec As Variant

    If outputMin <> outputMin Or outputMax <> outputMax Then
        Err.Raise vbObjectError + 1011, "libRangeMap", "output range endpoints must be finite"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If

    Set valuesMap = AssertObjectMap(values, "value")
    Set schemaMap = AssertObjectMap(schema, "schema")

    outputKeys = SortVariantKeys(schemaMap.Keys)
    If UBound(outputKeys) < LBound(outputKeys) Then
        Err.Raise vbObjectError + 1031, "libRangeMap", "schema must not be empty"
    End If

    If Not allowUnknownFields Then
        If valuesMap.Count > 0 Then
            valueKeys = valuesMap.Keys
            For i = LBound(valueKeys) To UBound(valueKeys)
                requiredKey = CStr(valueKeys(i))
                If Not schemaMap.Exists(requiredKey) Then
                    Err.Raise vbObjectError + 1032, "libRangeMap", "unknown field '" & requiredKey & "' without schema mapping"
                End If
            Next i
        End If
    End If
    Set mappedValues = CreateObject("Scripting.Dictionary")

    For i = LBound(outputKeys) To UBound(outputKeys)
        requiredKey = CStr(outputKeys(i))
        If Not valuesMap.Exists(requiredKey) Then
            If allowMissing Then
                mappedValues.Add requiredKey, Empty
            Else
                Err.Raise vbObjectError + 1033, "libRangeMap", "missing required field '" & requiredKey & "'"
            End If
            GoTo ContinueFieldLoop
        End If

        fieldSpec = schemaMap(requiredKey)
        If Not IsArray(fieldSpec) Then
            Err.Raise vbObjectError + 1034, "libRangeMap", "schema for field '" & requiredKey & "' must be an array spec"
        End If
        mappedValues.Add requiredKey, MapObjectFieldValue(valuesMap(requiredKey), fieldSpec, outputMin, outputMax, clip)

ContinueFieldLoop:
    Next i

    Set MapObjectValue = mappedValues
    Exit Function
End Function

Private Function MapObjectFieldValue(ByVal value As Variant, ByVal fieldSpec As Variant, _
                                    Optional ByVal outputMin As Double = -1#, _
                                    Optional ByVal outputMax As Double = 1#, _
                                    Optional ByVal clip As Boolean = False) As Variant
    Dim family As String
    Dim lowerBound As Long
    Dim upperBound As Long
    Dim i As Long
    Dim elementSpec As Variant
    Dim sequenceOutput() As Variant
    Dim falseValue As Double
    Dim trueValue As Double
    Dim inMin As Double
    Dim inMax As Double
    Dim currentClip As Boolean
    Dim allowEmpty As Boolean
    Dim tokenDict As Variant
    Dim mapMode As String
    Dim modeAlphabet As String
    Dim localOutputMin As Double
    Dim localOutputMax As Double
    Dim localClipValue As Boolean
    Dim fieldSpecLower As Long

    If Not IsArray(fieldSpec) Then
        Err.Raise vbObjectError + 1035, "libRangeMap", "field spec must be an array"
    End If

    fieldSpecLower = LBound(fieldSpec)
    On Error GoTo InvalidFieldSpec
    family = LCase$(CStr(fieldSpec(fieldSpecLower)))
    On Error GoTo 0

    localOutputMin = outputMin
    localOutputMax = outputMax
    localClipValue = clip

    Select Case family
        Case "integer"
            If (UBound(fieldSpec) - fieldSpecLower + 1) < 3 Then
                Err.Raise vbObjectError + 1036, "libRangeMap", "integer field spec must include [family, inputMin, inputMax]"
            End If
            If IsNumeric(fieldSpec(fieldSpecLower + 1)) = False Or IsNumeric(fieldSpec(fieldSpecLower + 2)) = False Then
                Err.Raise vbObjectError + 1037, "libRangeMap", "integer field spec bounds must be numeric"
            End If
            inMin = CDbl(fieldSpec(fieldSpecLower + 1))
            inMax = CDbl(fieldSpec(fieldSpecLower + 2))
            currentClip = clip
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 4 Then
                currentClip = CBool(fieldSpec(fieldSpecLower + 3))
            End If
            If IsAllowedNumericValue(value) = False Then
                Err.Raise vbObjectError + 1038, "libRangeMap", "integer field value must be a numeric scalar"
            End If
            If localOutputMin <> localOutputMin Or localOutputMax <> localOutputMax Then
                Err.Raise vbObjectError + 1040, "libRangeMap", "output range endpoints must be finite"
            End If
            MapObjectFieldValue = MapIntegerValue(CLng(value), CLng(inMin), CLng(inMax), localOutputMin, localOutputMax, currentClip)

        Case "float"
            If (UBound(fieldSpec) - fieldSpecLower + 1) < 3 Then
                Err.Raise vbObjectError + 1036, "libRangeMap", "float field spec must include [family, inputMin, inputMax]"
            End If
            If IsNumeric(fieldSpec(fieldSpecLower + 1)) = False Or IsNumeric(fieldSpec(fieldSpecLower + 2)) = False Then
                Err.Raise vbObjectError + 1037, "libRangeMap", "float field spec bounds must be numeric"
            End If
            inMin = CDbl(fieldSpec(fieldSpecLower + 1))
            inMax = CDbl(fieldSpec(fieldSpecLower + 2))
            currentClip = clip
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 4 Then
                currentClip = CBool(fieldSpec(fieldSpecLower + 3))
            End If
            MapObjectFieldValue = MapFloatValue(CDbl(RequireFiniteNumericValue(value, "object field value")), inMin, inMax, localOutputMin, localOutputMax, currentClip)

        Case "boolean"
            falseValue = localOutputMin
            trueValue = localOutputMax
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 3 Then
                falseValue = CDbl(fieldSpec(fieldSpecLower + 1))
                trueValue = CDbl(fieldSpec(fieldSpecLower + 2))
            End If
            If VarType(value) <> vbBoolean Then
                Err.Raise vbObjectError + 1039, "libRangeMap", "boolean field value must be Boolean"
            End If
            If falseValue <> falseValue Or trueValue <> trueValue Then
                Err.Raise vbObjectError + 1040, "libRangeMap", "boolean field policy must be finite"
            End If
            MapObjectFieldValue = MapBooleanValue(CBool(value), localOutputMin, localOutputMax, falseValue, trueValue)

        Case "text"
            mapMode = "codepoint"
            modeAlphabet = ""
            allowEmpty = False
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 2 Then
                mapMode = CStr(fieldSpec(fieldSpecLower + 1))
            End If
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 3 Then
                modeAlphabet = CStr(fieldSpec(fieldSpecLower + 2))
            End If
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 4 Then
                allowEmpty = CBool(fieldSpec(fieldSpecLower + 3))
            End If
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 5 Then
                currentClip = CBool(fieldSpec(fieldSpecLower + 4))
            Else
                currentClip = clip
            End If
            If VarType(value) <> vbString Then
                Err.Raise vbObjectError + 1041, "libRangeMap", "text field value must be a string"
            End If
            MapObjectFieldValue = MapTextValue(CStr(value), localOutputMin, localOutputMax, mapMode, modeAlphabet, currentClip, allowEmpty)

        Case "bytes"
            allowEmpty = False
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 2 Then
                localClipValue = CBool(fieldSpec(fieldSpecLower + 1))
            End If
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 3 Then
                allowEmpty = CBool(fieldSpec(fieldSpecLower + 2))
            End If
            MapObjectFieldValue = MapBytesValue(value, localOutputMin, localOutputMax, localClipValue, allowEmpty)

        Case "sequence"
            If (UBound(fieldSpec) - fieldSpecLower + 1) < 2 Then
                Err.Raise vbObjectError + 1042, "libRangeMap", "sequence field spec must include [family, elementSpec]"
            End If
            If Not IsArray(value) Then
                Err.Raise vbObjectError + 1043, "libRangeMap", "sequence field value must be an array"
            End If
            elementSpec = fieldSpec(fieldSpecLower + 1)
            allowEmpty = False
            If (UBound(fieldSpec) - fieldSpecLower + 1) >= 3 Then
                allowEmpty = CBool(fieldSpec(fieldSpecLower + 2))
            End If
            lowerBound = LBound(value)
            upperBound = UBound(value)
            If upperBound < lowerBound Then
                If allowEmpty Then
                    MapObjectFieldValue = Array()
                    Exit Function
                End If
                Err.Raise vbObjectError + 1024, "libRangeMap", "empty sequence input is invalid by default"
            End If

            ReDim sequenceOutput(0 To upperBound - lowerBound)

            For i = lowerBound To upperBound
                sequenceOutput(i - lowerBound) = MapObjectFieldValue(value(i), elementSpec, localOutputMin, localOutputMax, clip)
            Next i
            MapObjectFieldValue = sequenceOutput

        Case "categorical"
            If (UBound(fieldSpec) - fieldSpecLower + 1) < 2 Then
                Err.Raise vbObjectError + 1044, "libRangeMap", "categorical field spec must include [family, tokens]"
            End If
            tokenDict = fieldSpec(fieldSpecLower + 1)
            If Not IsArray(tokenDict) Then
                Err.Raise vbObjectError + 1045, "libRangeMap", "categorical field spec tokens must be an array"
            End If
            MapObjectFieldValue = MapCategoricalValue(value, tokenDict, localOutputMin, localOutputMax)

        Case "object"
            If (UBound(fieldSpec) - fieldSpecLower + 1) < 2 Then
                Err.Raise vbObjectError + 1046, "libRangeMap", "object field spec must include [family, nestedSchema]"
            End If
            MapObjectFieldValue = MapObjectValue(value, fieldSpec(fieldSpecLower + 1), localOutputMin, localOutputMax, clip)

        Case Else
            Err.Raise vbObjectError + 1047, "libRangeMap", "unsupported object field family '" & family & "'"
    End Select

    Exit Function

InvalidFieldSpec:
    Err.Raise vbObjectError + 1035, "libRangeMap", "field spec must be a non-empty array"
End Function

Private Function SortVariantKeys(ByVal keys As Variant) As Variant
    Dim i As Long
    Dim j As Long
    Dim sortedKeys() As String
    Dim value As String
    Dim temp As String
    Dim lowerBound As Long
    Dim upperBound As Long

    On Error GoTo InvalidDictionary
    lowerBound = LBound(keys)
    upperBound = UBound(keys)
    On Error GoTo 0

    ReDim sortedKeys(lowerBound To upperBound)
    For i = lowerBound To upperBound
        sortedKeys(i) = CStr(keys(i))
    Next i

    For i = lowerBound To upperBound - 1
        For j = i + 1 To upperBound
            If StrComp(sortedKeys(j), sortedKeys(i), vbTextCompare) < 0 Then
                temp = sortedKeys(i)
                sortedKeys(i) = sortedKeys(j)
                sortedKeys(j) = temp
            End If
        Next j
    Next i

    SortVariantKeys = sortedKeys
    Exit Function

InvalidDictionary:
    Err.Raise vbObjectError + 1031, "libRangeMap", "schema must be an array of mappings"
End Function

Private Function AssertObjectMap(ByVal value As Variant, ByVal label As String) As Object
    Dim asObject As Object

    If Not IsObject(value) Then
        Err.Raise vbObjectError + 1030, "libRangeMap", label & " must be a Scripting.Dictionary-like object"
    End If
    Set asObject = value
    If TypeName(asObject) <> "Dictionary" Then
        Err.Raise vbObjectError + 1030, "libRangeMap", label & " must be a Scripting.Dictionary-like object"
    End If
    Set AssertObjectMap = asObject
End Function

Private Function RequireFiniteNumericValue(ByVal value As Variant, ByVal label As String) As Double
    If IsAllowedNumericValue(value) = False Then
        Err.Raise vbObjectError + 1048, "libRangeMap", label & " must be a finite number"
    End If
    RequireFiniteNumericValue = CDbl(value)
    If RequireFiniteNumericValue <> RequireFiniteNumericValue Then
        Err.Raise vbObjectError + 1048, "libRangeMap", label & " must be a finite number"
    End If
End Function

Private Function IsAllowedNumericValue(ByVal value As Variant) As Boolean
    Select Case VarType(value)
        Case vbByte, vbInteger, vbLong, vbSingle, vbDouble, vbCurrency, vbDecimal
            IsAllowedNumericValue = True
        Case Else
            IsAllowedNumericValue = False
    End Select
End Function

Public Function MapImageValue(ByVal values As Variant, Optional ByVal outputMin As Double = -1#, _
                              Optional ByVal outputMax As Double = 1#, _
                              Optional ByVal clip As Boolean = False, _
                              Optional ByVal allowEmpty As Boolean = False) As Variant
    Dim lowerBound As Long
    Dim upperBound As Long
    Dim i As Long
    Dim output() As Variant

    If outputMin <> outputMin Or outputMax <> outputMax Then
        Err.Raise vbObjectError + 1011, "libRangeMap", "output range endpoints must be finite"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If
    If Not IsArray(values) Then
        Err.Raise vbObjectError + 1023, "libRangeMap", "values must be an array"
    End If

    On Error GoTo EmptyImage
    lowerBound = LBound(values)
    upperBound = UBound(values)
    On Error GoTo 0

    If upperBound < lowerBound Then
        If allowEmpty Then
            MapImageValue = Array()
            Exit Function
        End If
        Err.Raise vbObjectError + 1024, "libRangeMap", "empty image input is invalid by default"
    End If

    ReDim output(0 To upperBound - lowerBound)
    For i = lowerBound To upperBound
        output(i - lowerBound) = MapBytesValue(values(i), outputMin, outputMax, clip, False)
    Next i

    MapImageValue = output
    Exit Function

EmptyImage:
    Err.Raise vbObjectError + 1024, "libRangeMap", "empty image input is invalid by default"
End Function

Private Function TokensEqual(ByVal leftValue As Variant, ByVal rightValue As Variant) As Boolean
    If IsNull(leftValue) Or IsNull(rightValue) Then
        TokensEqual = IsNull(leftValue) And IsNull(rightValue)
        Exit Function
    End If

    If IsEmpty(leftValue) Or IsEmpty(rightValue) Then
        TokensEqual = IsEmpty(leftValue) And IsEmpty(rightValue)
        Exit Function
    End If

    Select Case VarType(leftValue)
        Case vbString
            TokensEqual = (VarType(rightValue) = vbString And CStr(leftValue) = CStr(rightValue))
        Case vbBoolean
            TokensEqual = (VarType(rightValue) = vbBoolean And CBool(leftValue) = CBool(rightValue))
        Case vbByte, vbInteger, vbLong, vbSingle, vbDouble, vbCurrency, vbDecimal
            If IsNumeric(rightValue) Then
                TokensEqual = (CDbl(leftValue) = CDbl(rightValue))
            Else
                TokensEqual = False
            End If
        Case Else
            TokensEqual = False
    End Select
End Function

Public Function MapTemporalValue(ByVal value As Double, ByVal inputMin As Double, ByVal inputMax As Double, _
                                 Optional ByVal outputMin As Double = -1#, _
                                 Optional ByVal outputMax As Double = 1#, _
                                 Optional ByVal clip As Boolean = False) As Double
    Dim boundedValue As Double

    If value <> value Or inputMin <> inputMin Or inputMax <> inputMax Or outputMin <> outputMin Or outputMax <> outputMax Then
        Err.Raise vbObjectError + 1011, "libRangeMap", "range endpoints must be finite"
    End If
    If inputMin >= inputMax Then
        Err.Raise vbObjectError + 1001, "libRangeMap", "input_min must be less than input_max"
    End If
    If outputMin >= outputMax Then
        Err.Raise vbObjectError + 1002, "libRangeMap", "output_min must be less than output_max"
    End If

    boundedValue = value
    If clip Then
        If boundedValue < inputMin Then boundedValue = inputMin
        If boundedValue > inputMax Then boundedValue = inputMax
    Else
        If boundedValue < inputMin Or boundedValue > inputMax Then
            Err.Raise vbObjectError + 1003, "libRangeMap", "value out of range"
        End If
    End If

    MapTemporalValue = outputMin + ((boundedValue - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin)
End Function
