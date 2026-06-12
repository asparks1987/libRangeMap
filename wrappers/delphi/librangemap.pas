unit librangemap;

interface

uses SysUtils;

function MapIntegerValue(Value: Integer; InputMin: Integer; InputMax: Integer;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): Double;

function MapFloatValue(Value: Double; InputMin: Double; InputMax: Double;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): Double;

function MapBooleanValue(Value: Boolean; OutputMin: Double = -1.0;
  OutputMax: Double = 1.0; FalseValue: Double = -1.0; TrueValue: Double = 1.0): Double;

function MapTemporalValue(Value: TDateTime; InputMin: TDateTime; InputMax: TDateTime;
  OutputMin: Double = -1.0; OutputMax: Double = 1.0; Clip: Boolean = False): Double;

function MapTextValue(Value: string; OutputMin: Double = -1.0; OutputMax: Double = 1.0;
  Mode: string = 'codepoint'; Alphabet: string = ''; Clip: Boolean = False;
  AllowEmpty: Boolean = False): TArray<Double>;

function MapBytesValue(Value: TBytes; OutputMin: Double = -1.0; OutputMax: Double = 1.0;
  Clip: Boolean = False): TArray<Double>;

function MapCategoricalValue(Value: string; Vocabulary: TArray<string>;
  OutputMin: Double = -1.0; OutputMax: Double = 1.0): Double;

function MapIntegerSequenceValue(Values: TArray<Integer>; InputMin: Integer; InputMax: Integer;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): TArray<Double>;

function MapIntegerNestedSequenceValue(Values: TArray<TArray<Integer>>; InputMin: Integer; InputMax: Integer;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): TArray<TArray<Double>>;

function MapImageRawValue(Value: TBytes; Width: Integer; Height: Integer; Channels: Integer = 1;
  OutputMin: Double = -1.0; OutputMax: Double = 1.0; Clip: Boolean = False;
  AllowEmpty: Boolean = False): TArray<Double>;

implementation

function ContainsToken(const Tokens: TArray<string>; const Token: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(Tokens) do
  begin
    if Tokens[I] = Token then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

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

function MapFloatValue(Value: Double; InputMin: Double; InputMax: Double;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): Double;
var
  BoundedValue: Double;
  InputSpan: Double;
  OutputSpan: Double;
begin
  if IsNan(Value) or IsInfinite(Value) or IsNan(InputMin) or IsInfinite(InputMin) or IsNan(InputMax) or IsInfinite(InputMax) or
     IsNan(OutputMin) or IsInfinite(OutputMin) or IsNan(OutputMax) or IsInfinite(OutputMax) then
    raise Exception.Create('value and range endpoints must be finite');
  if InputMin >= InputMax then
    raise Exception.Create('input_min must be less than input_max');
  if OutputMin >= OutputMax then
    raise Exception.Create('output_min must be less than output_max');

  BoundedValue := Value;
  if Clip then
  begin
    if BoundedValue < InputMin then BoundedValue := InputMin;
    if BoundedValue > InputMax then BoundedValue := InputMax;
  end
  else
  begin
    if (BoundedValue < InputMin) or (BoundedValue > InputMax) then
      raise Exception.Create('value out of range');
  end;

  InputSpan := InputMax - InputMin;
  OutputSpan := OutputMax - OutputMin;
  Result := OutputMin + ((BoundedValue - InputMin) / InputSpan) * OutputSpan;
end;

function MapBooleanValue(Value: Boolean; OutputMin: Double = -1.0;
  OutputMax: Double = 1.0; FalseValue: Double = -1.0; TrueValue: Double = 1.0): Double;
begin
  if IsNan(OutputMin) or IsInfinite(OutputMin) or IsNan(OutputMax) or IsInfinite(OutputMax) or
     IsNan(FalseValue) or IsInfinite(FalseValue) or IsNan(TrueValue) or IsInfinite(TrueValue) then
    raise Exception.Create('output values must be finite');
  if OutputMin >= OutputMax then
    raise Exception.Create('output_min must be less than output_max');
  if (FalseValue < OutputMin) or (FalseValue > OutputMax) or (TrueValue < OutputMin) or (TrueValue > OutputMax) then
    raise Exception.Create('false_value/true_value must be within output range');
  if FalseValue = TrueValue then
    raise Exception.Create('false_value and true_value must differ');

  if Value then
    Result := TrueValue
  else
    Result := FalseValue;
end;

function MapTemporalValue(Value: TDateTime; InputMin: TDateTime; InputMax: TDateTime;
  OutputMin: Double = -1.0; OutputMax: Double = 1.0; Clip: Boolean = False): Double;
var
  BoundedValue: TDateTime;
  InputSpan: Double;
  OutputSpan: Double;
begin
  if IsNan(Value) or IsInfinite(Value) or IsNan(InputMin) or IsInfinite(InputMin) or IsNan(InputMax) or IsInfinite(InputMax) or
     IsNan(OutputMin) or IsInfinite(OutputMin) or IsNan(OutputMax) or IsInfinite(OutputMax) then
    raise Exception.Create('value and range endpoints must be finite');
  if InputMin >= InputMax then
    raise Exception.Create('input_min must be less than input_max');
  if OutputMin >= OutputMax then
    raise Exception.Create('output_min must be less than output_max');

  BoundedValue := Value;
  if Clip then
  begin
    if BoundedValue < InputMin then BoundedValue := InputMin;
    if BoundedValue > InputMax then BoundedValue := InputMax;
  end
  else
  begin
    if (BoundedValue < InputMin) or (BoundedValue > InputMax) then
      raise Exception.Create('value out of range');
  end;

  InputSpan := InputMax - InputMin;
  OutputSpan := OutputMax - OutputMin;
  Result := OutputMin + ((BoundedValue - InputMin) / InputSpan) * OutputSpan;
end;

function MapTextValue(Value: string; OutputMin: Double = -1.0; OutputMax: Double = 1.0;
  Mode: string = 'codepoint'; Alphabet: string = ''; Clip: Boolean = False;
  AllowEmpty: Boolean = False): TArray<Double>;
var
  I: Integer;
  J: Integer;
  Index: Integer;
  OutputSpan: Double;
  Ch: Char;
  AlphabetLength: Integer;
begin
  if IsNan(OutputMin) or IsInfinite(OutputMin) or IsNan(OutputMax) or IsInfinite(OutputMax) then
    raise Exception.Create('output values must be finite');
  if OutputMin >= OutputMax then
    raise Exception.Create('output_min must be less than output_max');
  if Length(Value) = 0 then
  begin
    if AllowEmpty then
    begin
      SetLength(Result, 0);
      Exit;
    end;
    raise Exception.Create('empty text input is invalid by default');
  end;

  if SameText(Mode, 'codepoint') then
  begin
    SetLength(Result, Length(Value));
    OutputSpan := OutputMax - OutputMin;
    for I := 1 to Length(Value) do
    begin
      Ch := Value[I];
      Result[I - 1] := OutputMin + ((Ord(Ch) / 65535.0) * OutputSpan);
    end;
    Exit;
  end;

  if SameText(Mode, 'alphabet') then
  begin
    AlphabetLength := Length(Alphabet);
    if AlphabetLength < 2 then
      raise Exception.Create('alphabet must contain at least two unique characters');
    for I := 1 to AlphabetLength do
      for J := I + 1 to AlphabetLength do
        if Alphabet[I] = Alphabet[J] then
          raise Exception.Create('alphabet must contain unique characters');

    SetLength(Result, Length(Value));
    OutputSpan := OutputMax - OutputMin;
    for I := 1 to Length(Value) do
    begin
      Index := Pos(Value[I], Alphabet);
      if Index = 0 then
        raise Exception.CreateFmt('unknown categorical token %s', [Value[I]]);
      Dec(Index);
      if AlphabetLength = 1 then
        Result[I - 1] := (OutputMin + OutputMax) / 2.0
      else
        Result[I - 1] := OutputMin + ((Index / (AlphabetLength - 1)) * OutputSpan);
    end;
    Exit;
  end;

  raise Exception.Create('mode must be codepoint or alphabet');
end;

function MapBytesValue(Value: TBytes; OutputMin: Double = -1.0; OutputMax: Double = 1.0;
  Clip: Boolean = False): TArray<Double>;
var
  I: Integer;
  Current: Integer;
  OutputSpan: Double;
begin
  if IsNan(OutputMin) or IsInfinite(OutputMin) or IsNan(OutputMax) or IsInfinite(OutputMax) then
    raise Exception.Create('output values must be finite');
  if OutputMin >= OutputMax then
    raise Exception.Create('output_min must be less than output_max');
  if Length(Value) = 0 then
    raise Exception.Create('empty bytes input is invalid by default');

  SetLength(Result, Length(Value));
  OutputSpan := OutputMax - OutputMin;
  for I := 0 to High(Value) do
  begin
    Current := Value[I];
    if Clip then
    begin
      if Current < 0 then Current := 0;
      if Current > 255 then Current := 255;
    end
    else if (Current < 0) or (Current > 255) then
      raise Exception.Create('byte value out of range');

    Result[I] := OutputMin + ((Current / 255.0) * OutputSpan);
  end;
end;

function MapCategoricalValue(Value: string; Vocabulary: TArray<string>;
  OutputMin: Double = -1.0; OutputMax: Double = 1.0): Double;
var
  I: Integer;
  Index: Integer;
  OutputSpan: Double;
  Seen: TArray<string>;
begin
  if IsNan(OutputMin) or IsInfinite(OutputMin) or IsNan(OutputMax) or IsInfinite(OutputMax) then
    raise Exception.Create('output values must be finite');
  if OutputMin >= OutputMax then
    raise Exception.Create('output_min must be less than output_max');
  if Length(Vocabulary) = 0 then
    raise Exception.Create('vocabulary must not be empty');

  SetLength(Seen, 0);
  Index := -1;
  for I := 0 to High(Vocabulary) do
  begin
    if Vocabulary[I] = '' then
      raise Exception.Create('vocabulary tokens must be non-empty strings');
    if ContainsToken(Seen, Vocabulary[I]) then
      raise Exception.CreateFmt('duplicate vocabulary token %s', [Vocabulary[I]]);
    SetLength(Seen, Length(Seen) + 1);
    Seen[High(Seen)] := Vocabulary[I];
    if Vocabulary[I] = Value then
      Index := I;
  end;

  if Index < 0 then
    raise Exception.CreateFmt('unknown categorical token %s', [Value]);

  if Length(Vocabulary) = 1 then
  begin
    Result := (OutputMin + OutputMax) / 2.0;
    Exit;
  end;

  OutputSpan := OutputMax - OutputMin;
  Result := OutputMin + ((Index / (Length(Vocabulary) - 1)) * OutputSpan);
end;

function MapIntegerSequenceValue(Values: TArray<Integer>; InputMin: Integer; InputMax: Integer;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): TArray<Double>;
var
  I: Integer;
begin
  if Length(Values) = 0 then
    raise Exception.Create('empty sequence input is invalid by default');

  SetLength(Result, Length(Values));
  for I := 0 to High(Values) do
    Result[I] := MapIntegerValue(Values[I], InputMin, InputMax, OutputMin, OutputMax, Clip);
end;

function MapIntegerNestedSequenceValue(Values: TArray<TArray<Integer>>; InputMin: Integer; InputMax: Integer;
  OutputMin: Double; OutputMax: Double; Clip: Boolean = False): TArray<TArray<Double>>;
var
  I: Integer;
begin
  if Length(Values) = 0 then
    raise Exception.Create('empty sequence input is invalid by default');

  SetLength(Result, Length(Values));
  for I := 0 to High(Values) do
    Result[I] := MapIntegerSequenceValue(Values[I], InputMin, InputMax, OutputMin, OutputMax, Clip);
end;

function MapImageRawValue(Value: TBytes; Width: Integer; Height: Integer; Channels: Integer = 1;
  OutputMin: Double = -1.0; OutputMax: Double = 1.0; Clip: Boolean = False;
  AllowEmpty: Boolean = False): TArray<Double>;
var
  ExpectedLength: Integer;
begin
  if Width <= 0 then
    raise Exception.Create('image width must be positive');
  if Height <= 0 then
    raise Exception.Create('image height must be positive');
  if Channels <= 0 then
    raise Exception.Create('image channels must be positive');
  if Length(Value) = 0 then
  begin
    if AllowEmpty then
    begin
      SetLength(Result, 0);
      Exit;
    end;
    raise Exception.Create('empty image input is invalid by default');
  end;

  ExpectedLength := Width * Height * Channels;
  if ExpectedLength <> Length(Value) then
    raise Exception.Create('image payload length does not match shape metadata');

  Result := MapBytesValue(Value, OutputMin, OutputMax, Clip);
end;

procedure SelfCheck;
begin
  if Abs(MapIntegerValue(50, 0, 100, -1.0, 1.0, False)) > 1e-12 then
    raise Exception.Create('integer self-check failed');
  if Abs(MapFloatValue(0.5, 0.0, 1.0, -1.0, 1.0, False)) > 1e-12 then
    raise Exception.Create('float self-check failed');
  if Abs(MapBooleanValue(True, -1.0, 1.0, -1.0, 1.0)) > 1e-12 then
    raise Exception.Create('boolean self-check failed');
  if Abs(MapTemporalValue(0, -10, 10, -1.0, 1.0, False)) > 1e-12 then
    raise Exception.Create('temporal self-check failed');
  if Length(MapTextValue('cab', -1.0, 1.0, 'alphabet', 'abc', False, False)) <> 3 then
    raise Exception.Create('text self-check failed');
  if Length(MapBytesValue(TBytes.Create(0, 255), -1.0, 1.0, False)) <> 2 then
    raise Exception.Create('bytes self-check failed');
  if Abs(MapCategoricalValue('cat', TArray<string>.Create('cat', 'dog'), -1.0, 1.0) + 1.0) > 1e-12 then
    raise Exception.Create('categorical self-check failed');
  if Length(MapIntegerSequenceValue(TArray<Integer>.Create(0, 50, 100), 0, 100, -1.0, 1.0, False)) <> 3 then
    raise Exception.Create('sequence self-check failed');
  if Length(MapIntegerNestedSequenceValue(TArray<TArray<Integer>>.Create(TArray<Integer>.Create(0, 50), TArray<Integer>.Create(100)),
    0, 100, -1.0, 1.0, False)) <> 2 then
    raise Exception.Create('nested sequence self-check failed');
  if Length(MapImageRawValue(TBytes.Create(0, 127, 255), 3, 1, 1, -1.0, 1.0, False, False)) <> 3 then
    raise Exception.Create('image-like self-check failed');
end;

initialization
  SelfCheck;

end.
