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
