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

        Console.WriteLine("Visual Basic wrapper verification passed.")
    End Sub
End Module
