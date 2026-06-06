package LibrangeMap is
   function Map_Integer_Value
     (Value      : Integer;
      Input_Min  : Integer;
      Input_Max  : Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float;
end LibrangeMap;
