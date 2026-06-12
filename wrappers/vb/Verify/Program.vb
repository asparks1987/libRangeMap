Imports LibRangeMap

Module Program
    Private Sub AssertEqual(actual As Double, expected As Double, label As String)
        If actual <> expected Then
            Throw New InvalidOperationException($"{label} = {actual}, expected {expected}")
        End If
    End Sub

    Sub Main()
        Dim mapper = New IntegerRangeMapper(0, 100)
        AssertEqual(mapper.MapValue(0), -1.0, "MapValue(0)")
        AssertEqual(mapper.MapValue(50), 0.0, "MapValue(50)")
        AssertEqual(mapper.MapValue(100), 1.0, "MapValue(100)")

        Dim spec = mapper.Spec()
        If spec.SpecVersion <> CurrentSpecVersion Then
            Throw New InvalidOperationException($"unexpected spec version {spec.SpecVersion}")
        End If

        Dim restored = IntegerRangeMapper.FromJson(mapper.ToJson())
        AssertEqual(restored.MapValue(50), 0.0, "RoundTrip.MapValue(50)")

        Dim repeatedFirst = mapper.MapValue(50)
        Dim repeatedSecond = mapper.MapValue(50)
        AssertEqual(repeatedFirst, repeatedSecond, "Repeated MapValue(50)")

        Dim clipped = New IntegerRangeMapper(0, 10, -1.0, 1.0, True)
        AssertEqual(clipped.MapValue(-5), -1.0, "Clipped.MapValue(-5)")

        Dim strictThrew As Boolean = False
        Try
            Dim strictMapper = New IntegerRangeMapper(0, 10, -1.0, 1.0, False)
            strictMapper.MapValue(11)
        Catch ex As Exception
            strictThrew = True
        End Try
        If Not strictThrew Then
            Throw New InvalidOperationException("strict out-of-range mapping should fail")
        End If

        Dim floatMapper = New FloatRangeMapper(0.0, 1.0)
        AssertEqual(floatMapper.MapValue(0.0), -1.0, "Float.MapValue(0.0)")
        AssertEqual(floatMapper.MapValue(0.5), 0.0, "Float.MapValue(0.5)")
        AssertEqual(floatMapper.MapValue(1.0), 1.0, "Float.MapValue(1.0)")
        Dim floatRestored = FloatRangeMapper.FromJson(floatMapper.ToJson())
        AssertEqual(floatRestored.MapValue(0.5), 0.0, "Float roundtrip")
        Dim floatRepeatedFirst = floatMapper.MapValue(0.5)
        Dim floatRepeatedSecond = floatMapper.MapValue(0.5)
        AssertEqual(floatRepeatedFirst, floatRepeatedSecond, "Float repeated mapping")

        Dim booleanMapper = New BooleanRangeMapper()
        AssertEqual(booleanMapper.MapValue(False), -1.0, "Boolean false")
        AssertEqual(booleanMapper.MapValue(True), 1.0, "Boolean true")
        Dim booleanRestored = BooleanRangeMapper.FromJson(booleanMapper.ToJson())
        AssertEqual(booleanRestored.MapValue(True), 1.0, "Boolean roundtrip")
        Dim booleanRepeatedFirst = booleanMapper.MapValue(True)
        Dim booleanRepeatedSecond = booleanMapper.MapValue(True)
        AssertEqual(booleanRepeatedFirst, booleanRepeatedSecond, "Boolean repeated mapping")

        Dim textMapper = New TextRangeMapper()
        Dim textMapped = textMapper.MapValue("Ada")
        If textMapped.Length <> 3 Then
            Throw New InvalidOperationException($"text length = {textMapped.Length}, expected 3")
        End If
        Dim textRepeated = textMapper.MapValue("Ada")
        If textRepeated.Length <> textMapped.Length OrElse textRepeated(0) <> textMapped(0) OrElse textRepeated(1) <> textMapped(1) OrElse textRepeated(2) <> textMapped(2) Then
            Throw New InvalidOperationException("text repeated mapping changed output")
        End If
        Dim alphabetText = New TextRangeMapper("alphabet", "abc")
        Dim alphabetMapped = alphabetText.MapValue("abc")
        AssertEqual(alphabetMapped(0), -1.0, "Alphabet first")
        AssertEqual(alphabetMapped(1), 0.0, "Alphabet middle")
        AssertEqual(alphabetMapped(2), 1.0, "Alphabet last")
        Dim textRestored = TextRangeMapper.FromJson(textMapper.ToJson())
        Dim textRoundTrip = textRestored.MapValue("Ada")
        If textRoundTrip.Length <> textMapped.Length OrElse textRoundTrip(0) <> textMapped(0) OrElse textRoundTrip(1) <> textMapped(1) OrElse textRoundTrip(2) <> textMapped(2) Then
            Throw New InvalidOperationException("text roundtrip mapping changed output")
        End If
        Dim textFailed As Boolean = False
        Try
            alphabetText.MapValue("abd")
        Catch ex As ArgumentException
            textFailed = True
        End Try
        If Not textFailed Then
            Throw New InvalidOperationException("text unknown-token mapping should fail")
        End If

        Dim bytesMapper = New BytesRangeMapper()
        Dim bytesMapped = bytesMapper.MapValue(New Byte() {0, 127, 255})
        If bytesMapped.Length <> 3 Then
            Throw New InvalidOperationException($"bytes length = {bytesMapped.Length}, expected 3")
        End If
        AssertEqual(bytesMapped(0), -1.0, "Bytes[0]")
        AssertEqual(bytesMapped(1), ((127.0 / 255.0) * 2.0) - 1.0, "Bytes[1]")
        AssertEqual(bytesMapped(2), 1.0, "Bytes[2]")
        Dim bytesRestored = BytesRangeMapper.FromJson(bytesMapper.ToJson())
        AssertEqual(bytesRestored.MapValue(System.Text.Encoding.UTF8.GetBytes(ChrW(0)))(0), -1.0, "Bytes roundtrip")

        Dim imageMapper = New ImageRangeMapper()
        Dim imageMapped = imageMapper.MapValue(New Byte() {0, 127, 255}, 1, 1, 3)
        If imageMapped.Length <> 3 Then
            Throw New InvalidOperationException($"image length = {imageMapped.Length}, expected 3")
        End If
        AssertEqual(imageMapped(0), -1.0, "Image[0]")
        AssertEqual(imageMapped(1), ((127.0 / 255.0) * 2.0) - 1.0, "Image[1]")
        AssertEqual(imageMapped(2), 1.0, "Image[2]")
        Dim imageRepeated = imageMapper.MapValue(New Byte() {0, 127, 255}, 1, 1, 3)
        AssertEqual(imageRepeated(1), imageMapped(1), "Image repeated")
        Dim imageRestored = ImageRangeMapper.FromJson(imageMapper.ToJson())
        AssertEqual(imageRestored.MapValue(New Byte() {255}, 1, 1, 1)(0), 1.0, "Image roundtrip")
        Dim imageFailed As Boolean = False
        Try
            imageMapper.MapValue(New Byte() {0, 127, 255}, 1, 1, 2)
        Catch ex As ArgumentException
            imageFailed = True
        End Try
        If Not imageFailed Then
            Throw New InvalidOperationException("image malformed-shape mapping should fail")
        End If

        Dim sequenceMapper = New SequenceRangeMapper(Of Long, Double)(Function(value As Long) New IntegerRangeMapper(0, 100).MapValue(value))
        Dim sequenceMapped = sequenceMapper.MapValue(New Long() {0, 50, 100})
        If sequenceMapped.Length <> 3 OrElse sequenceMapped(0) <> -1.0 OrElse sequenceMapped(1) <> 0.0 OrElse sequenceMapped(2) <> 1.0 Then
            Throw New InvalidOperationException($"sequence mapping = [{String.Join(", ", sequenceMapped)}], expected [-1, 0, 1]")
        End If
        Dim sequenceRepeated = sequenceMapper.MapValue(New Long() {0, 50, 100})
        If sequenceRepeated.Length <> sequenceMapped.Length OrElse sequenceRepeated(0) <> sequenceMapped(0) OrElse sequenceRepeated(1) <> sequenceMapped(1) OrElse sequenceRepeated(2) <> sequenceMapped(2) Then
            Throw New InvalidOperationException("sequence repeated mapping changed output")
        End If
        Dim nestedSequenceMapper = New SequenceRangeMapper(Of Long(), Double())(Function(value As Long()) sequenceMapper.MapValue(value))
        Dim nestedSequenceMapped = nestedSequenceMapper.MapValue(New Long()() {New Long() {0, 50}, New Long() {100}})
        If nestedSequenceMapped.Length <> 2 OrElse nestedSequenceMapped(0).Length <> 2 OrElse nestedSequenceMapped(0)(1) <> 0.0 OrElse nestedSequenceMapped(1)(0) <> 1.0 Then
            Throw New InvalidOperationException("nested sequence mapping changed output")
        End If
        Dim sequenceFailed As Boolean = False
        Try
            sequenceMapper.MapValue(New Long() {})
        Catch ex As ArgumentException
            sequenceFailed = True
        End Try
        If Not sequenceFailed Then
            Throw New InvalidOperationException("empty sequence mapping should fail")
        End If

        Dim categoricalMapper = New CategoricalRangeMapper(New String() {"cat", "dog"})
        AssertEqual(categoricalMapper.MapValue("cat"), -1.0, "Categorical first")
        AssertEqual(categoricalMapper.MapValue("dog"), 1.0, "Categorical second")
        AssertEqual(categoricalMapper.MapValue("dog"), categoricalMapper.MapValue("dog"), "Categorical repeated")

        Dim categoricalRestored = CategoricalRangeMapper.FromJson(categoricalMapper.ToJson())
        AssertEqual(categoricalRestored.MapValue("cat"), -1.0, "Categorical roundtrip")

        Dim categoricalFailed As Boolean = False
        Try
            categoricalMapper.MapValue("missing")
        Catch ex As Exception
            categoricalFailed = True
        End Try
        If Not categoricalFailed Then
            Throw New InvalidOperationException("categorical unknown-token mapping should fail")
        End If

        Dim nestedObjectMapper = New ObjectRangeMapper(New Dictionary(Of String, Object)(StringComparer.Ordinal) From {
            {"tag", New CategoricalRangeMapper(New String() {"ok", "warn", "err"})},
            {"id", New IntegerRangeMapper(0, 1000)},
            {"active", New BooleanRangeMapper()},
            {"payload", New BytesRangeMapper()},
            {"score", New FloatRangeMapper(0.0, 1.0)}
        })
        Dim nestedMapInput As New Dictionary(Of String, Object)(StringComparer.Ordinal) From {
            {"tag", "warn"},
            {"id", 10},
            {"active", True},
            {"payload", System.Text.Encoding.UTF8.GetBytes("ab")},
            {"score", 0.25}
        }

        Dim nestedMapped = nestedObjectMapper.Map(nestedMapInput)
        If nestedMapped.Count <> 5 OrElse TypeOf nestedMapped("tag") IsNot Double Then
            Throw New InvalidOperationException("object map output shape is not as expected")
        End If

        Dim objectRepeated = nestedObjectMapper.Map(nestedMapInput)
        Dim nestedTag As Double = CDbl(objectRepeated("tag"))
        If nestedTag <> 0.0 Then
            Throw New InvalidOperationException("object map tag output value is not as expected")
        End If

        Dim objectUnknownInput As New Dictionary(Of String, Object)(StringComparer.Ordinal) From {
            {"tag", "err"},
            {"id", 1},
            {"active", False},
            {"payload", System.Text.Encoding.UTF8.GetBytes("ok")},
            {"score", 0.5},
            {"extra", "disallowed"}
        }
        Dim objectUnknown As Boolean = False
        Try
            nestedObjectMapper.Map(objectUnknownInput)
        Catch ex As ArgumentException
            objectUnknown = True
        End Try
        If Not objectUnknown Then
            Throw New InvalidOperationException("object map unknown-field rejection should fail")
        End If

        Dim objectRestored = ObjectRangeMapper.FromJson(nestedObjectMapper.ToJson())
        Dim objectRoundTrip = objectRestored.Map(nestedMapInput)
        Dim expectedId = nestedMapped("id")
        If Not CBool(DirectCast(objectRoundTrip("id"), Double) = DirectCast(expectedId, Double)) Then
            Throw New InvalidOperationException("object roundtrip changed output")
        End If

        Dim temporalMin As Long = 1700000000000L
        Dim temporalMid As Long = 1700000050000L
        Dim temporalMax As Long = 1700000100000L
        Dim temporalMapper = New TemporalRangeMapper(temporalMin, temporalMax)
        AssertEqual(temporalMapper.MapValue(temporalMin), -1.0, "Temporal lower")
        AssertEqual(temporalMapper.MapValue(temporalMid), 0.0, "Temporal mid")
        AssertEqual(temporalMapper.MapValue(DateTimeOffset.FromUnixTimeMilliseconds(temporalMid)), 0.0, "Temporal datetimeoffset")
        AssertEqual(temporalMapper.MapValue(DateTimeOffset.FromUnixTimeMilliseconds(temporalMid).UtcDateTime), 0.0, "Temporal datetime")
        AssertEqual(temporalMapper.MapValue(temporalMid), temporalMapper.MapValue(temporalMid), "Temporal repeated")

        Dim temporalRestored = TemporalRangeMapper.FromJson(temporalMapper.ToJson())
        AssertEqual(temporalRestored.MapValue(temporalMid), 0.0, "Temporal roundtrip")

        Dim temporalStrictThrew As Boolean = False
        Try
            temporalMapper.MapValue(1700000200000L)
        Catch ex As ArgumentOutOfRangeException
            temporalStrictThrew = True
        End Try
        If Not temporalStrictThrew Then
            Throw New InvalidOperationException("temporal out-of-range mapping should fail")
        End If

        Console.WriteLine("Visual Basic wrapper verification passed.")
    End Sub
End Module
