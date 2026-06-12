with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body LibrangeMap is

   function Name_Equals(Left, Right : Unbounded_String) return Boolean is
   begin
      return To_String(Left) = To_String(Right);
   end Name_Equals;

   function Map_Temporal_Value
     (Value      : Long_Long_Integer;
      Input_Min  : Long_Long_Integer;
      Input_Max  : Long_Long_Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float
   is
      V   : Long_Long_Integer := Value;
      Den : Long_Float;
   begin
      if Input_Min >= Input_Max then
         raise Constraint_Error with "input_min must be less than input_max";
      end if;
      if Output_Min >= Output_Max then
         raise Constraint_Error with "output_min must be less than output_max";
      end if;

      if Clip then
         if V < Input_Min then
            V := Input_Min;
         elsif V > Input_Max then
            V := Input_Max;
         end if;
      elsif V < Input_Min or else V > Input_Max then
         raise Constraint_Error with "value out of range";
      end if;

      Den := Long_Float(Input_Max - Input_Min);
      return Output_Min + (Long_Float(V - Input_Min) / Den) * (Output_Max - Output_Min);
   end Map_Temporal_Value;

   function Map_Bytes_Value
     (Value      : String;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float_Array
   is
      Result : Long_Float_Array (1 .. Value'Length);
      Current : Integer;
   begin
      if Output_Min >= Output_Max then
         raise Constraint_Error with "output_min must be less than output_max";
      end if;
      if Value'Length = 0 then
         raise Constraint_Error with "empty bytes input is invalid by default";
      end if;

      for I in Value'Range loop
         Current := Character'Pos(Value(I));
         if Clip then
            if Current < 0 then
               Current := 0;
            elsif Current > 255 then
               Current := 255;
            end if;
         elsif Current < 0 or else Current > 255 then
            raise Constraint_Error with "byte value out of range";
         end if;
         Result(I - Value'First + 1) := Output_Min + (Long_Float(Current) / 255.0) * (Output_Max - Output_Min);
      end loop;

      return Result;
   end Map_Bytes_Value;

   function Map_Text_Value
     (Value      : String;
      Mode       : Text_Mode := Codepoint;
      Alphabet_Value : String := "";
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0) return Long_Float_Array
   is
      Index : Integer;
   begin
      if Output_Min >= Output_Max then
         raise Constraint_Error with "output_min must be less than output_max";
      end if;
      if Value'Length = 0 then
         raise Constraint_Error with "empty text input is invalid by default";
      end if;
      if Mode = Alphabet then
         if Alphabet_Value'Length = 0 then
            raise Constraint_Error with "alphabet must not be empty";
         end if;

         for I in Alphabet_Value'Range loop
            for J in Alphabet_Value'Range loop
               if I < J and then Alphabet_Value(I) = Alphabet_Value(J) then
                  raise Constraint_Error with "alphabet must be unique";
               end if;
            end loop;
         end loop;
      end if;

      declare
         Result : Long_Float_Array (1 .. Value'Length);
      begin
         for I in Value'Range loop
            case Mode is
               when Codepoint | Byte =>
                  Index := Character'Pos(Value(I));
                  Result(I - Value'First + 1) := Output_Min + (Long_Float(Index) / 255.0) * (Output_Max - Output_Min);
               when Alphabet =>
                  Index := 0;
                  for J in Alphabet_Value'Range loop
                     if Alphabet_Value(J) = Value(I) then
                        Index := J - Alphabet_Value'First + 1;
                        exit;
                     end if;
                  end loop;

                  if Index = 0 then
                     raise Constraint_Error with "unknown text token";
                  end if;

                  if Alphabet_Value'Length = 1 then
                     Result(I - Value'First + 1) := (Output_Min + Output_Max) / 2.0;
                  else
                     Result(I - Value'First + 1) := Output_Min
                       + (Long_Float(Index - 1) / Long_Float(Alphabet_Value'Length - 1))
                       * (Output_Max - Output_Min);
                  end if;
            end case;
         end loop;

         return Result;
      end;
   end Map_Text_Value;

   function Map_Integer_Value
     (Value      : Integer;
      Input_Min  : Integer;
      Input_Max  : Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float
   is
      V   : Integer := Value;
      Den : Long_Float;
   begin
      if Input_Min >= Input_Max then
         raise Constraint_Error with "input_min must be less than input_max";
      end if;
      if Output_Min >= Output_Max then
         raise Constraint_Error with "output_min must be less than output_max";
      end if;

      if Clip then
         if V < Input_Min then
            V := Input_Min;
         elsif V > Input_Max then
            V := Input_Max;
         end if;
      elsif V < Input_Min or else V > Input_Max then
         raise Constraint_Error with "value out of range";
      end if;

      Den := Long_Float(Input_Max - Input_Min);
      return Output_Min + (Long_Float(V - Input_Min) / Den) * (Output_Max - Output_Min);
   end Map_Integer_Value;

   function Map_Float_Value
     (Value        : Long_Float;
      Input_Min    : Long_Float;
      Input_Max    : Long_Float;
      Output_Min   : Long_Float := -1.0;
      Output_Max   : Long_Float := 1.0;
      Clip         : Boolean := False;
      Allow_Integer : Boolean := True) return Long_Float
   is
      V : Long_Float := Value;
   begin
      if Value /= Value then
         raise Constraint_Error with "value must be finite";
      end if;
      if not Allow_Integer and then Value = Long_Float'Floor(Value) then
         raise Constraint_Error with "integer input is disabled by policy";
      end if;
      if Input_Min >= Input_Max then
         raise Constraint_Error with "input_min must be less than input_max";
      end if;
      if Output_Min >= Output_Max then
         raise Constraint_Error with "output_min must be less than output_max";
      end if;

      if Clip then
         if V < Input_Min then
            V := Input_Min;
         elsif V > Input_Max then
            V := Input_Max;
         end if;
      elsif V < Input_Min or else V > Input_Max then
         raise Constraint_Error with "value out of range";
      end if;

      return Output_Min + ((V - Input_Min) / (Input_Max - Input_Min)) * (Output_Max - Output_Min);
   end Map_Float_Value;

   function Map_Boolean_Value
     (Value      : Boolean;
      False_Value : Long_Float := -1.0;
      True_Value  : Long_Float := 1.0) return Long_Float
   is
   begin
      if False_Value /= False_Value or else True_Value /= True_Value then
         raise Constraint_Error with "boolean outputs must be finite";
      end if;
      if Value then
         return True_Value;
      else
         return False_Value;
      end if;
   end Map_Boolean_Value;

   function Map_Categorical_Value
     (Value      : Unbounded_String;
      Tokens     : Categorical_Token_Array;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0) return Long_Float
   is
      Index : Natural := 0;
   begin
      if Output_Min >= Output_Max then
         raise Constraint_Error with "output_min must be less than output_max";
      end if;
      if Tokens'Length = 0 then
         raise Constraint_Error with "tokens must not be empty";
      end if;

      for I in Tokens'Range loop
         for J in Tokens'Range loop
            if I < J and then Tokens(I) = Tokens(J) then
               raise Constraint_Error with "tokens must be unique";
            end if;
         end loop;
      end loop;

      for I in Tokens'Range loop
         if Tokens(I) = Value then
            Index := I;
            exit;
         end if;
      end loop;

      if Index = 0 then
         raise Constraint_Error with "unknown categorical token";
      end if;

      if Tokens'Length = 1 then
         return (Output_Min + Output_Max) / 2.0;
      end if;

      return Output_Min
        + (Long_Float(Index - Tokens'First) / Long_Float(Tokens'Length - 1))
        * (Output_Max - Output_Min);
   end Map_Categorical_Value;

   function Map_Integer_Sequence_Value
     (Values     : Integer_Array;
      Input_Min  : Integer;
      Input_Max  : Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float_Array
   is
      Result : Long_Float_Array (Values'Range);
   begin
      if Values'Length = 0 then
         raise Constraint_Error with "empty sequence input is invalid by default";
      end if;

      for I in Values'Range loop
         Result(I) := Map_Integer_Value(Values(I), Input_Min, Input_Max, Output_Min, Output_Max, Clip);
      end loop;

      return Result;
   end Map_Integer_Sequence_Value;

   function Map_Integer_Nested_Sequence_Value
     (Values     : Integer_Matrix;
      Input_Min  : Integer;
      Input_Max  : Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float_Array_Array
   is
      Result : Long_Float_Array_Array (Values'Range(1));
   begin
      if Values'Length = 0 then
         raise Constraint_Error with "empty sequence input is invalid by default";
      end if;

      for Row in Values'Range(1) loop
         Result(Row) := Map_Integer_Sequence_Value(Values(Row, Values'Range(2)), Input_Min, Input_Max, Output_Min, Output_Max, Clip);
      end loop;

      return Result;
   end Map_Integer_Nested_Sequence_Value;

   function Map_Image_Value
     (Values     : Integer_Matrix;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float_Array_Array
   is
      Result : Long_Float_Array_Array (Values'Range(1));
   begin
      if Values'Length = 0 then
         raise Constraint_Error with "empty image input is invalid by default";
      end if;

      for Row in Values'Range(1) loop
         Result(Row) := Map_Integer_Sequence_Value(
           Values(Row, Values'Range(2)),
           0,
           255,
           Output_Min,
           Output_Max,
           Clip);
      end loop;

      return Result;
   end Map_Image_Value;

   function Map_Object_Value
     (Schema      : Map_Object_Field_Spec_Array;
      Input       : Map_Object_Field_Input_Array;
      Allow_Unknown : Boolean := False;
      Output_Min  : Long_Float := -1.0;
      Output_Max  : Long_Float := 1.0) return Long_Float_Array
   is
      type Index_Array is array (Positive range 1 .. Schema'Length) of Integer;
      Indexes : Index_Array;
      Output : Long_Float_Array (1 .. Schema'Length);

      function Find_Input_Index(Target : Unbounded_String) return Integer is
      begin
         for I in Input'Range loop
            if Name_Equals(Input(I).Name, Target) then
               return I;
            end if;
         end loop;
         return 0;
      end Find_Input_Index;

      function Schema_Has_Field(Target : Unbounded_String) return Boolean is
      begin
         for I in Schema'Range loop
            if Name_Equals(Schema(I).Name, Target) then
               return True;
            end if;
         end loop;
         return False;
      end Schema_Has_Field;
   begin
      if Output_Min >= Output_Max then
         raise Constraint_Error with "output bounds invalid";
      end if;
      if Schema'Length = 0 then
         raise Constraint_Error with "schema must not be empty";
      end if;

      for I in Schema'Range loop
         if To_String(Schema(I).Name) = "" then
            raise Constraint_Error with "schema field name must not be empty";
         end if;
      end loop;

      for I in Input'Range loop
         if To_String(Input(I).Name) = "" then
            raise Constraint_Error with "input field name must not be empty";
         end if;
      end loop;
      for I in Input'Range loop
         for J in I + 1 .. Input'Last loop
            if Name_Equals(Input(I).Name, Input(J).Name) then
               raise Constraint_Error with "input field names must be unique";
            end if;
         end loop;
      end loop;

      for I in Schema'First .. Schema'Last loop
         for J in I + 1 .. Schema'Last loop
            if Name_Equals(Schema(I).Name, Schema(J).Name) then
               raise Constraint_Error with "schema field names must be unique";
            end if;
         end loop;
      end loop;

      for I in 1 .. Schema'Length loop
         Indexes(I) := Schema'First + I - 1;
      end loop;

      for I in 1 .. Schema'Length loop
         for J in I + 1 .. Schema'Length loop
            if To_String(Schema(Indexes(I)).Name) > To_String(Schema(Indexes(J)).Name) then
               declare
                  Swap : Integer;
               begin
                  Swap := Indexes(I);
                  Indexes(I) := Indexes(J);
                  Indexes(J) := Swap;
               end;
            end if;
         end loop;
      end loop;

      for I in 1 .. Schema'Length loop
         declare
            Schema_Index : constant Integer := Indexes(I);
            Spec : constant Map_Object_Field_Spec := Schema(Schema_Index);
            Input_Index : constant Integer := Find_Input_Index(Spec.Name);
            Field_Length : Integer;
            Aggregated : Long_Float;
            Mapped_Value : Long_Float;
         begin
            if Input_Index = 0 then
               if Spec.Allow_Missing then
                  Output(I) := Spec.Missing_Value;
                  continue;
               end if;
               raise Constraint_Error with "missing required field";
            end if;
            if not Input(Input_Index).Field.Has_Value then
               if Spec.Allow_Missing then
                  Output(I) := Spec.Missing_Value;
                  continue;
               end if;
               raise Constraint_Error with "missing required field value";
            end if;
            if Input(Input_Index).Field.Family_Provided /= Spec.Family then
               raise Constraint_Error with "field type mismatch";
            end if;

            case Spec.Family is
               when Integer_Field =>
                  Mapped_Value := Map_Integer_Value(
                     Input(Input_Index).Field.Integer_Value,
                     Spec.Integer_Spec.Input_Min,
                     Spec.Integer_Spec.Input_Max,
                     Spec.Integer_Spec.Output_Min,
                     Spec.Integer_Spec.Output_Max,
                     Spec.Integer_Spec.Clip);
               when Float_Field =>
                  Mapped_Value := Map_Float_Value(
                     Input(Input_Index).Field.Float_Value,
                     Spec.Float_Spec.Input_Min,
                     Spec.Float_Spec.Input_Max,
                     Spec.Float_Spec.Output_Min,
                     Spec.Float_Spec.Output_Max,
                     Spec.Float_Spec.Clip,
                     Spec.Float_Spec.Allow_Integer);
               when Boolean_Field =>
                  Mapped_Value := Map_Boolean_Value(
                     Input(Input_Index).Field.Boolean_Value,
                     Spec.Boolean_Spec.False_Value,
                     Spec.Boolean_Spec.True_Value);
               when Text_Field =>
                  if To_String(Spec.Text_Spec.Alphabet) = "" then
                     declare
                        Text_Values : constant Long_Float_Array := Map_Text_Value(
                           To_String(Input(Input_Index).Field.Text_Value),
                           Codepoint,
                           "",
                           Spec.Text_Spec.Output_Min,
                           Spec.Text_Spec.Output_Max);
                        Text_Accum : Long_Float := 0.0;
                     begin
                        Field_Length := Text_Values'Length;
                        if Field_Length = 0 then
                           raise Constraint_Error with "text field produced empty output";
                        end if;
                        for J in Text_Values'Range loop
                           Text_Accum := Text_Accum + Text_Values(J);
                        end loop;
                        Mapped_Value := Text_Accum / Long_Float(Field_Length);
                     end;
                  else
                     declare
                        Text_Values : constant Long_Float_Array := Map_Text_Value(
                           To_String(Input(Input_Index).Field.Text_Value),
                           Alphabet,
                           To_String(Spec.Text_Spec.Alphabet),
                           Spec.Text_Spec.Output_Min,
                           Spec.Text_Spec.Output_Max);
                        Text_Accum : Long_Float := 0.0;
                     begin
                        Field_Length := Text_Values'Length;
                        if Field_Length = 0 then
                           raise Constraint_Error with "text field produced empty output";
                        end if;
                        for J in Text_Values'Range loop
                           Text_Accum := Text_Accum + Text_Values(J);
                        end loop;
                        Mapped_Value := Text_Accum / Long_Float(Field_Length);
                     end;
                  end if;
               when Bytes_Field =>
                  declare
                     Byte_Values : constant Long_Float_Array := Map_Bytes_Value(
                     To_String(Input(Input_Index).Field.Bytes_Value),
                     Spec.Bytes_Spec.Output_Min,
                     Spec.Bytes_Spec.Output_Max,
                     Spec.Bytes_Spec.Clip);
                     Byte_Accum : Long_Float := 0.0;
                  begin
                     Field_Length := Byte_Values'Length;
                     if Field_Length = 0 then
                        raise Constraint_Error with "bytes field produced empty output";
                     end if;
                     for J in Byte_Values'Range loop
                        Byte_Accum := Byte_Accum + Byte_Values(J);
                     end loop;
                     Mapped_Value := Byte_Accum / Long_Float(Field_Length);
                  end;
               when Integer_Sequence_Field =>
                  declare
                     Sequence_Values : constant Long_Float_Array := Map_Integer_Sequence_Value(
                        Input(Input_Index).Field.Integer_Sequence_Value,
                        Spec.Integer_Sequence_Spec.Input_Min,
                        Spec.Integer_Sequence_Spec.Input_Max,
                        Spec.Integer_Sequence_Spec.Output_Min,
                        Spec.Integer_Sequence_Spec.Output_Max,
                        Spec.Integer_Sequence_Spec.Clip);
                     Seq_Accum : Long_Float := 0.0;
                  begin
                     Field_Length := Sequence_Values'Length;
                     if Field_Length = 0 then
                        raise Constraint_Error with "sequence field produced empty output";
                     end if;
                     for J in Sequence_Values'Range loop
                        Seq_Accum := Seq_Accum + Sequence_Values(J);
                     end loop;
                     Mapped_Value := Seq_Accum / Long_Float(Field_Length);
                  end;
               when Float_Sequence_Field =>
                  if Input(Input_Index).Field.Float_Sequence_Value'Length = 0 then
                     raise Constraint_Error with "sequence field produced empty output";
                  end if;
                  Aggregated := 0.0;
                  Field_Length := Input(Input_Index).Field.Float_Sequence_Value'Length;
                  for J in Input(Input_Index).Field.Float_Sequence_Value'Range loop
                     Aggregated := Aggregated + Map_Float_Value(
                        Input(Input_Index).Field.Float_Sequence_Value(J),
                        Spec.Float_Sequence_Spec.Input_Min,
                        Spec.Float_Sequence_Spec.Input_Max,
                        Spec.Float_Sequence_Spec.Output_Min,
                        Spec.Float_Sequence_Spec.Output_Max,
                        Spec.Float_Sequence_Spec.Clip,
                        True);
                  end loop;
                  Mapped_Value := Aggregated / Long_Float(Field_Length);
            end case;

            Output(I) := Mapped_Value;
         end;
      end loop;

      if not Allow_Unknown then
         for I in Input'Range loop
            if not Schema_Has_Field(Input(I).Name) then
               raise Constraint_Error with "unknown field in object input";
            end if;
         end loop;
      end if;

      return Output;
   end Map_Object_Value;

   procedure Self_Check is
      Sample_Text : constant Long_Float_Array := Map_Text_Value("abc", Mode => Alphabet, Alphabet_Value => "abc");
      Sample_Codepoint : constant Long_Float_Array := Map_Text_Value("Ada", Mode => Codepoint);
      Sample_Sequence : constant Long_Float_Array := Map_Integer_Sequence_Value((1 => 0, 2 => 50, 3 => 100), 0, 100);
      Sample_Nested : constant Long_Float_Array_Array := Map_Integer_Nested_Sequence_Value(
        (1 => (1 => 0, 2 => 50), 2 => (1 => 100)),
        0, 100);
      Sample_Image : constant Long_Float_Array_Array := Map_Image_Value(
        (1 => (1 => 0, 2 => 127), 2 => (1 => 255)));
      Object_Schema : constant Map_Object_Field_Spec_Array := (
         1 => (
            Name => To_Unbounded_String("age"),
            Allow_Missing => False,
            Missing_Value => 0.0,
            Family => Integer_Field,
            Integer_Spec => (Input_Min => 0, Input_Max => 100, Output_Min => -1.0, Output_Max => 1.0, Clip => False)),
         2 => (
            Name => To_Unbounded_String("active"),
            Allow_Missing => False,
            Missing_Value => 0.0,
            Family => Boolean_Field,
            Boolean_Spec => (False_Value => -1.0, True_Value => 1.0)));
      Object_Input : constant Map_Object_Field_Input_Array := (
         1 => (
            Name => To_Unbounded_String("age"),
            Field => (Has_Value => True, Family_Provided => Integer_Field, Integer_Value => 0)),
         2 => (
            Name => To_Unbounded_String("active"),
            Field => (Has_Value => True, Family_Provided => Boolean_Field, Boolean_Value => True)));
      Object_Mapped : constant Long_Float_Array := Map_Object_Value(Object_Schema, Object_Input);
      Unknown_Object_Input : constant Map_Object_Field_Input_Array := (
         1 => (
            Name => To_Unbounded_String("age"),
            Field => (Has_Value => True, Family_Provided => Integer_Field, Integer_Value => 10)),
         2 => (
            Name => To_Unbounded_String("active"),
            Field => (Has_Value => True, Family_Provided => Boolean_Field, Boolean_Value => False)),
         3 => (
            Name => To_Unbounded_String("unknown"),
            Field => (Has_Value => True, Family_Provided => Integer_Field, Integer_Value => 1)));
      Missing_Object_Input : constant Map_Object_Field_Input_Array := (
         1 => (
            Name => To_Unbounded_String("active"),
            Field => (Has_Value => False, Family_Provided => Boolean_Field, Boolean_Value => False)));
      Missing_Allowed_Schema : constant Map_Object_Field_Spec_Array := (
         1 => (
            Name => To_Unbounded_String("active"),
            Allow_Missing => True,
            Missing_Value => 0.5,
            Family => Boolean_Field,
            Boolean_Spec => (False_Value => -1.0, True_Value => 1.0)));
   begin
      if Sample_Text'Length /= 3 then
         raise Program_Error with "text self-check failed";
      end if;
      if Sample_Codepoint'Length /= 3 then
         raise Program_Error with "text self-check failed";
      end if;
      if Sample_Sequence'Length /= 3 then
         raise Program_Error with "sequence self-check failed";
      end if;
      if Sample_Nested'Length /= 2 then
         raise Program_Error with "nested sequence self-check failed";
      end if;
      if Sample_Image'Length /= 2 then
         raise Program_Error with "image self-check failed";
      end if;
      if Object_Mapped'Length /= 2 then
         raise Program_Error with "object self-check failed";
      end if;
      if Object_Mapped(1) /= 1.0 or else Object_Mapped(2) /= -1.0 then
         raise Program_Error with "object ordering self-check failed";
      end if;
      begin
         Map_Object_Value(Object_Schema, Unknown_Object_Input, False);
         raise Program_Error with "object unknown field should fail";
      exception
         when Constraint_Error =>
            null;
      end;

      if Map_Object_Value(Missing_Allowed_Schema, Missing_Object_Input)(1) /= 0.5 then
         raise Program_Error with "object missing-field check failed";
      end if;

   end Self_Check;
end LibrangeMap;

