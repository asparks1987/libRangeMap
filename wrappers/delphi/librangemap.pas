unit librangemap;

interface

function MapIntegerValue(Value: Integer; InputMin: Integer; InputMax: Integer;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): Double;

implementation

function MapIntegerValue(Value: Integer; InputMin: Integer; InputMax: Integer;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): Double;
var
  ClippedValue: Integer;
  InputSpan: Integer;
  OutputSpan: Double;
begin
  if InputMin >= InputMax then
    raise Exception.Create('input_min must be less than input_max');
  if OutputMin >= OutputMax then
    raise Exception.Create('output_min must be less than output_max');

  ClippedValue := Value;
  if Clip then
  begin
    if ClippedValue < InputMin then ClippedValue := InputMin;
    if ClippedValue > InputMax then ClippedValue := InputMax;
  end
  else
  begin
    if (ClippedValue < InputMin) or (ClippedValue > InputMax) then
      raise Exception.Create('value out of range');
  end;

  InputSpan := InputMax - InputMin;
  OutputSpan := OutputMax - OutputMin;
  Result := OutputMin + ((ClippedValue - InputMin) / InputSpan) * OutputSpan;
end;

end.
