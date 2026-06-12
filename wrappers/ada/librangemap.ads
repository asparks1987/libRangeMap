with Ada.Strings.Unbounded;

package LibrangeMap is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Categorical_Token_Array is array (Positive range <>) of Unbounded_String;
   type Integer_Array is array (Positive range <>) of Integer;
   type Integer_Matrix is array (Positive range <>, Positive range <>) of Integer;
   type Long_Float_Array_Array is array (Positive range <>) of Long_Float_Array;
   type Long_Float_Array is array (Positive range <>) of Long_Float;
   type Text_Mode is (Codepoint, Byte, Alphabet);
   type Map_Field_Family is (Integer_Field, Float_Field, Boolean_Field, Text_Field, Bytes_Field, Integer_Sequence_Field, Float_Sequence_Field);

   type Map_Integer_Spec is record
      Input_Min : Integer;
      Input_Max : Integer;
      Output_Min : Long_Float;
      Output_Max : Long_Float;
      Clip : Boolean;
   end record;

   type Map_Float_Spec is record
      Input_Min : Long_Float;
      Input_Max : Long_Float;
      Output_Min : Long_Float;
      Output_Max : Long_Float;
      Clip : Boolean;
      Allow_Integer : Boolean;
   end record;

   type Map_Boolean_Spec is record
      False_Value : Long_Float;
      True_Value : Long_Float;
   end record;

   type Map_Text_Spec is record
      Alphabet : Unbounded_String;
      Output_Min : Long_Float;
      Output_Max : Long_Float;
   end record;

   type Map_Bytes_Spec is record
      Output_Min : Long_Float;
      Output_Max : Long_Float;
      Clip : Boolean;
   end record;

   type Map_Integer_Sequence_Spec is record
      Input_Min : Integer;
      Input_Max : Integer;
      Output_Min : Long_Float;
      Output_Max : Long_Float;
      Clip : Boolean;
   end record;

   type Map_Float_Sequence_Spec is record
      Input_Min : Long_Float;
      Input_Max : Long_Float;
      Output_Min : Long_Float;
      Output_Max : Long_Float;
      Clip : Boolean;
   end record;

   type Map_Object_Field_Spec (Family : Map_Field_Family := Integer_Field) is record
      Name : Unbounded_String;
      Allow_Missing : Boolean;
      Missing_Value : Long_Float;
      case Family is
         when Integer_Field =>
            Integer_Spec : Map_Integer_Spec;
         when Float_Field =>
            Float_Spec : Map_Float_Spec;
         when Boolean_Field =>
            Boolean_Spec : Map_Boolean_Spec;
         when Text_Field =>
            Text_Spec : Map_Text_Spec;
         when Bytes_Field =>
            Bytes_Spec : Map_Bytes_Spec;
         when Integer_Sequence_Field =>
            Integer_Sequence_Spec : Map_Integer_Sequence_Spec;
         when Float_Sequence_Field =>
            Float_Sequence_Spec : Map_Float_Sequence_Spec;
      end case;
   end record;

   type Map_Object_Field_Spec_Array is array (Positive range <>) of Map_Object_Field_Spec;

   type Map_Object_Field_Value (Family : Map_Field_Family := Integer_Field) is record
      Family_Provided : Map_Field_Family := Integer_Field;
      Has_Value : Boolean;
      case Family_Provided is
         when Integer_Field =>
            Integer_Value : Integer;
         when Float_Field =>
            Float_Value : Long_Float;
         when Boolean_Field =>
            Boolean_Value : Boolean;
         when Text_Field =>
            Text_Value : Unbounded_String;
         when Bytes_Field =>
            Bytes_Value : Unbounded_String;
         when Integer_Sequence_Field =>
            Integer_Sequence_Value : Integer_Array;
         when Float_Sequence_Field =>
            Float_Sequence_Value : Long_Float_Array;
      end case;
   end record;

   type Map_Object_Field_Input is record
      Name : Unbounded_String;
      Field : Map_Object_Field_Value;
   end record;

   type Map_Object_Field_Input_Array is array (Positive range <>) of Map_Object_Field_Input;

   function Map_Temporal_Value
     (Value      : Long_Long_Integer;
      Input_Min  : Long_Long_Integer;
      Input_Max  : Long_Long_Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float;

   function Map_Bytes_Value
     (Value      : String;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float_Array;

   function Map_Text_Value
     (Value      : String;
      Mode       : Text_Mode := Codepoint;
      Alphabet_Value : String := "";
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0) return Long_Float_Array;

   function Map_Integer_Value
     (Value      : Integer;
      Input_Min  : Integer;
      Input_Max  : Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float;

   function Map_Float_Value
     (Value        : Long_Float;
      Input_Min    : Long_Float;
      Input_Max    : Long_Float;
      Output_Min   : Long_Float := -1.0;
      Output_Max   : Long_Float := 1.0;
      Clip         : Boolean := False;
      Allow_Integer : Boolean := True) return Long_Float;

   function Map_Boolean_Value
     (Value      : Boolean;
      False_Value : Long_Float := -1.0;
      True_Value  : Long_Float := 1.0) return Long_Float;

   function Map_Categorical_Value
     (Value      : Unbounded_String;
      Tokens     : Categorical_Token_Array;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0) return Long_Float;

   function Map_Integer_Sequence_Value
     (Values     : Integer_Array;
      Input_Min  : Integer;
      Input_Max  : Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float_Array;

   function Map_Integer_Nested_Sequence_Value
     (Values     : Integer_Matrix;
      Input_Min  : Integer;
      Input_Max  : Integer;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float_Array_Array;

   function Map_Image_Value
     (Values     : Integer_Matrix;
      Output_Min : Long_Float := -1.0;
      Output_Max : Long_Float := 1.0;
      Clip       : Boolean := False) return Long_Float_Array_Array;

   function Map_Object_Value
     (Schema      : Map_Object_Field_Spec_Array;
      Input       : Map_Object_Field_Input_Array;
      Allow_Unknown : Boolean := False;
      Output_Min  : Long_Float := -1.0;
      Output_Max  : Long_Float := 1.0) return Long_Float_Array;

   procedure Self_Check;
end LibrangeMap;

