package body LibrangeMap is

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
end LibrangeMap;
