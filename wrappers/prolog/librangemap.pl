% librangemap integer mapping predicate

map_integer_value(Value, InputMin, InputMax, OutputMin, OutputMax, Clip, Output) :-
    (   input_min_ok(InputMin, InputMax),
        output_min_ok(OutputMin, OutputMax) ->
        bound_value(Value, InputMin, InputMax, Clip, Bounded),
        SpanIn is InputMax - InputMin,
        SpanOut is OutputMax - OutputMin,
        Output is OutputMin + ((Bounded - InputMin) / SpanIn) * SpanOut
    ).

input_min_ok(InputMin, InputMax) :-
    integer(InputMin), integer(InputMax), InputMin < InputMax.

output_min_ok(OutputMin, OutputMax) :-
    number(OutputMin), number(OutputMax), OutputMin < OutputMax.

bound_value(Value, InputMin, InputMax, true, Bounded) :-
    integer(Value), integer(InputMin), integer(InputMax),
    Bounded is min(max(Value, InputMin), InputMax).
bound_value(Value, InputMin, InputMax, false, Value) :-
    integer(Value), integer(InputMin), integer(InputMax),
    Value >= InputMin, Value =< InputMax.

% librangemap float mapping predicate

map_float_value(Value, InputMin, InputMax, OutputMin, OutputMax, Clip, Output) :-
    (   input_float_ok(InputMin, InputMax),
        output_float_ok(OutputMin, OutputMax) ->
        bound_float_value(Value, InputMin, InputMax, Clip, Bounded),
        SpanIn is InputMax - InputMin,
        SpanOut is OutputMax - OutputMin,
        Output is OutputMin + ((Bounded - InputMin) / SpanIn) * SpanOut
    ).

input_float_ok(InputMin, InputMax) :-
    number(InputMin), number(InputMax), InputMin < InputMax.

output_float_ok(OutputMin, OutputMax) :-
    number(OutputMin), number(OutputMax), OutputMin < OutputMax.

bound_float_value(Value, InputMin, InputMax, true, Bounded) :-
    number(Value),
    Bounded is min(max(Value, InputMin), InputMax).
bound_float_value(Value, InputMin, InputMax, false, Value) :-
    number(Value),
    Value >= InputMin, Value =< InputMax.

% librangemap boolean mapping predicate

map_boolean_value(false, FalseValue, _TrueValue, FalseValue).
map_boolean_value(true, _FalseValue, TrueValue, TrueValue).

% librangemap text mapping predicate

map_text_value(Value, OutputMin, OutputMax, Mode, Clip, AllowEmpty, Alphabet, Output) :-
    text_mode_ok(Mode),
    bool_ok(Clip),
    bool_ok(AllowEmpty),
    output_float_ok(OutputMin, OutputMax),
    text_units(Mode, Value, Units),
    (   Units = []
    ->  (   AllowEmpty == true
        ->  Output = []
        ;   throw(error(domain_error(non_empty_text, Value), context(map_text_value/8, 'empty text is invalid by default')))
        )
    ;   text_map_units(Mode, Units, OutputMin, OutputMax, Clip, Alphabet, Output)
    ).

text_mode_ok(codepoint).
text_mode_ok(alphabet).
text_mode_ok(byte).

bool_ok(true).
bool_ok(false).

text_units(byte, Value, Units) :- !,
    (   is_list(Value)
    ->  Units = Value
    ;   throw(error(type_error(list, Value), context(map_text_value/8, 'byte mode expects a list of integers')))
    ).
text_units(_, Value, Codes) :-
    text_string_codes(Value, Codes).

text_string_codes(Value, Codes) :-
    string(Value), !,
    string_codes(Value, Codes).
text_string_codes(Value, Codes) :-
    atom(Value), !,
    atom_codes(Value, Codes).
text_string_codes(Value, _) :-
    throw(error(type_error(text, Value), context(map_text_value/8, 'text modes expect an atom or string'))).

text_map_units(codepoint, Codes, OutputMin, OutputMax, Clip, _Alphabet, Mapped) :-
    map_codepoints(Codes, 0, 0x10FFFF, OutputMin, OutputMax, Clip, Mapped).
text_map_units(alphabet, Codes, OutputMin, OutputMax, _Clip, Alphabet, Mapped) :-
    text_alphabet_codes(Alphabet, AlphabetCodes),
    map_alphabet_codes(Codes, AlphabetCodes, OutputMin, OutputMax, Mapped).
text_map_units(byte, Values, OutputMin, OutputMax, Clip, _Alphabet, Mapped) :-
    map_bytes_value(Values, OutputMin, OutputMax, Clip, Mapped).

text_alphabet_codes(Alphabet, Codes) :-
    text_string_codes(Alphabet, Codes),
    Codes \= [],
    length(Codes, Length),
    Length >= 2,
    text_unique_codes(Codes, []).

text_unique_codes([], _Seen).
text_unique_codes([Code|Rest], Seen) :-
    \+ memberchk(Code, Seen),
    text_unique_codes(Rest, [Code|Seen]).

map_codepoints([], _, _, _, _, _, []).
map_codepoints([Code|Rest], InputMin, InputMax, OutputMin, OutputMax, Clip, [Mapped|MappedRest]) :-
    integer(Code),
    (   code_bound(Code, InputMin, InputMax, Clip, Bounded)
    ->  true
    ;   throw(error(domain_error(codepoint, Code), context(map_text_value/8, 'codepoint outside range')))
    ),
    SpanOut is OutputMax - OutputMin,
    SpanIn is InputMax - InputMin,
    Mapped is OutputMin + ((Bounded - InputMin) / SpanIn) * SpanOut,
    map_codepoints(Rest, InputMin, InputMax, OutputMin, OutputMax, Clip, MappedRest).

code_bound(Value, true, 0, 0x10FFFF, 0) :- Value < 0, !.
code_bound(Value, true, 0, 0x10FFFF, 0x10FFFF) :- Value > 0x10FFFF, !.
code_bound(Value, false, 0, 0x10FFFF, Value) :- Value >= 0, Value =< 0x10FFFF.

map_alphabet_codes([], _AlphabetCodes, _OutputMin, _OutputMax, []).
map_alphabet_codes([Code|Rest], AlphabetCodes, OutputMin, OutputMax, [Mapped|MappedRest]) :-
    (   alphabet_index(Code, AlphabetCodes, Index)
    ->  length(AlphabetCodes, Length),
        categorical_output_value(Index, Length, OutputMin, OutputMax, Mapped),
        map_alphabet_codes(Rest, AlphabetCodes, OutputMin, OutputMax, MappedRest)
    ;   throw(error(domain_error(alphabet_symbol, Code), context(map_text_value/8, 'unknown character for alphabet mode')))
    ).

alphabet_index(Code, [Code|_], 0).
alphabet_index(Code, [_|Rest], Index) :-
    alphabet_index(Code, Rest, TailIndex),
    Index is TailIndex + 1.

% librangemap categorical mapping predicate

map_categorical_value(Value, Vocabulary, OutputMin, OutputMax, Output) :-
    atomic(Value),
    is_list(Vocabulary),
    Vocabulary \= [],
    output_float_ok(OutputMin, OutputMax),
    categorical_vocab_ok(Vocabulary, []),
    (   categorical_index(Value, Vocabulary, Index, Length)
    ->  true
    ;   throw(error(domain_error(categorical_token, Value), context(map_categorical_value/5, 'unknown categorical token')))
    ),
    categorical_output_value(Index, Length, OutputMin, OutputMax, Output).

categorical_vocab_ok([], _Seen).
categorical_vocab_ok([Value|Rest], Seen) :-
    atomic(Value),
    \+ memberchk(Value, Seen),
    categorical_vocab_ok(Rest, [Value|Seen]).

categorical_index(Value, [Value|_], 0, 1).
categorical_index(Value, [Head|Tail], Index, Length) :-
    categorical_index(Value, Tail, TailIndex, TailLength),
    Index is TailIndex + 1,
    Length is TailLength + 1,
    Head \= Value.

categorical_output_value(_, 1, OutputMin, OutputMax, Output) :-
    Output is (OutputMin + OutputMax) / 2.0.
categorical_output_value(Index, Length, OutputMin, OutputMax, Output) :-
    Length > 1,
    SpanOut is OutputMax - OutputMin,
    Output is OutputMin + (Index / (Length - 1)) * SpanOut.

% librangemap sequence mapping predicate

map_sequence_integer_value(Values, InputMin, InputMax, OutputMin, OutputMax, Clip, AllowEmpty, Output) :-
    bool_ok(Clip),
    bool_ok(AllowEmpty),
    output_float_ok(OutputMin, OutputMax),
    sequence_values(Values),
    (   Values = []
    ->  (   AllowEmpty == true
        ->  Output = []
        ;   throw(error(domain_error(non_empty_sequence, Values), context(map_sequence_integer_value/8, 'empty sequence is invalid by default')))
        )
    ;   map_sequence_integer_list(Values, InputMin, InputMax, OutputMin, OutputMax, Clip, Output)
    ).

sequence_values(Value) :-
    is_list(Value), !.
sequence_values(Value) :-
    throw(error(type_error(list, Value), context(map_sequence_integer_value/8, 'sequence mapping expects a list'))).

map_sequence_integer_list([], _, _, _, _, _, []).
map_sequence_integer_list([Value|Rest], InputMin, InputMax, OutputMin, OutputMax, Clip, [Mapped|MappedRest]) :-
    (   is_list(Value)
    ->  map_sequence_integer_value(Value, InputMin, InputMax, OutputMin, OutputMax, Clip, false, Mapped)
    ;   integer(Value)
    ->  map_integer_value(Value, InputMin, InputMax, OutputMin, OutputMax, Clip, Mapped)
    ;   throw(error(type_error(integer_or_list, Value), context(map_sequence_integer_value/8, 'sequence elements must be integers or nested lists')))
    ),
    map_sequence_integer_list(Rest, InputMin, InputMax, OutputMin, OutputMax, Clip, MappedRest).

% librangemap bytes mapping predicate

map_bytes_value(Values, OutputMin, OutputMax, Clip, Mapped) :-
    bytes_ok(Values, Clip, BoundedValues),
    output_float_ok(OutputMin, OutputMax),
    map_bytes_list(BoundedValues, 0, OutputMin, OutputMax, Mapped).

bytes_ok([], _, []).
bytes_ok([Value|Rest], Clip, [Bounded|MappedRest]) :-
    integer(Value),
    (   byte_bound(Value, Clip, Bounded)
    ->  true
    ;   throw(error(domain_error(byte, Value), context(map_bytes_value/5, 'byte outside range')))
    ),
    bytes_ok(Rest, Clip, MappedRest).

byte_bound(Value, true, 0) :- Value < 0, !.
byte_bound(Value, true, 255) :- Value > 255, !.
byte_bound(Value, false, Value) :- Value >= 0, Value =< 255.

map_bytes_list([], _, _, _, []).
map_bytes_list([Value|Rest], Index, OutputMin, OutputMax, [Mapped|MappedRest]) :-
    ValueFloat is Value * 1.0,
    InputMin is 0.0,
    InputMax is 255.0,
    SpanOut is OutputMax - OutputMin,
    SpanIn is InputMax - InputMin,
    Mapped is OutputMin + ((ValueFloat - InputMin) / SpanIn) * SpanOut,
    NextIndex is Index + 1,
    map_bytes_list(Rest, NextIndex, OutputMin, OutputMax, MappedRest).

% librangemap temporal mapping predicate

map_temporal_value(Value, InputMin, InputMax, OutputMin, OutputMax, Clip, Output) :-
    input_float_ok(InputMin, InputMax),
    output_float_ok(OutputMin, OutputMax),
    number(Value),
    Temporal is Value * 1.0,
    temporal_bound(Temporal, InputMin, InputMax, Clip, Bounded),
    SpanIn is InputMax - InputMin,
    SpanOut is OutputMax - OutputMin,
    Output is OutputMin + ((Bounded - InputMin) / SpanIn) * SpanOut.

temporal_bound(Value, InputMin, InputMax, true, Bounded) :-
    Bounded is min(max(Value, InputMin), InputMax).
temporal_bound(Value, InputMin, InputMax, false, Value) :-
    Value >= InputMin, Value =< InputMax.

% librangemap map/object family

map_object_value(Object, Schema, OutputMin, OutputMax, Clip, AllowUnknown, AllowEmpty, Output) :-
    (   is_dict(Object)
    ->  true
    ;   throw(error(type_error(dict, Object), context(map_object_value/8, 'object input must be a dict')))
    ),
    (   is_dict(Schema)
    ->  true
    ;   throw(error(type_error(dict, Schema), context(map_object_value/8, 'schema input must be a dict'))
    ),
    output_float_ok(OutputMin, OutputMax),
    bool_ok(Clip),
    bool_ok(AllowUnknown),
    bool_ok(AllowEmpty),
    dict_pairs(Object, _, ObjectPairs),
    dict_pairs(Schema, _, SchemaPairs),
    (   ObjectPairs = []
    ->  (   AllowEmpty == true
        ->  Output = _{}
        ;   throw(error(domain_error(non_empty_object, Object), context(map_object_value/8, 'empty objects are invalid by default')))
        )
    ;   findall(Key,
            (   member(Key-_, ObjectPairs),
                \+ memberchk(Key-_, SchemaPairs)
            ),
            UnknownFields),
        (   UnknownFields \= []
        ->  (   AllowUnknown == true
            ->  true
            ;   throw(error(domain_error(unknown_object_field, UnknownFields), context(map_object_value/8, 'unknown object field(s)')))
            )
        ;   true),
        map_object_pairs(SchemaPairs, Object, OutputMin, OutputMax, Clip, [], OutputPairs),
        dict_pairs(Output, _, OutputPairs)
    ).

map_object_pairs([], _, _, _, _, OutputPairs, OutputPairs).
map_object_pairs([Field-Mapper|Rest], Object, OutputMin, OutputMax, Clip, Acc, OutputPairs) :-
    (   get_dict(Field, Object, Value)
    ->  map_object_field(Mapper, Value, OutputMin, OutputMax, Clip, Mapped),
        append(Acc, [Field-Mapped], NextAcc),
        map_object_pairs(Rest, Object, OutputMin, OutputMax, Clip, NextAcc, OutputPairs)
    ;   throw(error(domain_error(missing_object_field, Field), context(map_object_value/8, 'missing required object field')))
    ).

map_object_field(integer(InMin, InMax), Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_integer_value(Value, InMin, InMax, OutputMin, OutputMax, Clip, Mapped).
map_object_field(float(InMin, InMax), Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_float_value(Value, InMin, InMax, OutputMin, OutputMax, Clip, Mapped).
map_object_field(boolean, Value, OutputMin, OutputMax, _Clip, Mapped) :-
    map_boolean_value(Value, OutputMin, OutputMax, Mapped).
map_object_field(bytes, Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_bytes_value(Value, OutputMin, OutputMax, Clip, Mapped).
map_object_field(categorical(Vocabulary), Value, OutputMin, OutputMax, _Clip, Mapped) :-
    map_categorical_value(Value, Vocabulary, OutputMin, OutputMax, Mapped).
map_object_field(sequence(Mapper), Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_object_sequence_value(Value, Mapper, OutputMin, OutputMax, Clip, Mapped).
map_object_field(temporal(InMin, InMax), Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_temporal_value(Value, InMin, InMax, OutputMin, OutputMax, Clip, Mapped).
map_object_field(text(Mode), Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_text_value(Value, OutputMin, OutputMax, Mode, Clip, false, "abc", Mapped).
map_object_field(text(Mode, Alphabet), Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_text_value(Value, OutputMin, OutputMax, Mode, Clip, false, Alphabet, Mapped).
map_object_field(object(Schema), Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_object_value(Value, Schema, OutputMin, OutputMax, Clip, false, false, Mapped).
map_object_field(Spec, _Value, _OutputMin, _OutputMax, _Clip, _Mapped) :-
    throw(error(domain_error(object_mapper_spec, Spec), context(map_object_value/8, 'unsupported mapper spec'))).

map_object_sequence_value(Values, Mapper, OutputMin, OutputMax, Clip, Mapped) :-
    sequence_values(Values),
    (   Values = []
    ->  throw(error(domain_error(non_empty_sequence, Values), context(map_object_field/6, 'empty sequence is invalid by default in object mapping'))
    ;   map_object_sequence_value_list(Values, Mapper, OutputMin, OutputMax, Clip, Mapped)
    ).

map_object_sequence_value_list([], _, _, _, _, []).
map_object_sequence_value_list([Value|Rest], Mapper, OutputMin, OutputMax, Clip, [Mapped|MappedRest]) :-
    (   is_list(Value)
    ->  map_object_sequence_value(Value, Mapper, OutputMin, OutputMax, Clip, Mapped)
    ;   map_object_field(Mapper, Value, OutputMin, OutputMax, Clip, Mapped)
    ),
    map_object_sequence_value_list(Rest, Mapper, OutputMin, OutputMax, Clip, MappedRest).

% librangemap image-like mapping predicates

map_image_value(Values, OutputMin, OutputMax, Clip, AllowEmpty, Mode, Output) :-
    image_mode_ok(Mode),
    output_float_ok(OutputMin, OutputMax),
    bool_ok(Clip),
    bool_ok(AllowEmpty),
    (   is_list(Values)
    ->  (   Values = []
        ->  (   AllowEmpty == true
            ->  Output = []
            ;   throw(error(domain_error(non_empty_image, Values), context(map_image_value/7, 'empty image is invalid by default'))
            )
        ;   map_image_mode(Mode, Values, OutputMin, OutputMax, Clip, Output)
        )
    ;   throw(error(type_error(list, Values), context(map_image_value/7, 'image payload must be list-like data')))
    ).

image_mode_ok(auto).
image_mode_ok(rgb).
image_mode_ok(rgba).

map_image_mode(auto, Values, OutputMin, OutputMax, Clip, Output) :-
    map_image_recursive(Values, true, OutputMin, OutputMax, Clip, Output).
map_image_mode(rgb, Values, OutputMin, OutputMax, Clip, Output) :-
    map_image_channels(3, Values, true, OutputMin, OutputMax, Clip, Output).
map_image_mode(rgba, Values, OutputMin, OutputMax, Clip, Output) :-
    map_image_channels(4, Values, true, OutputMin, OutputMax, Clip, Output).

map_image_recursive([], _, _, _, _, []) :-
    !.
map_image_recursive([Head|Tail], _TopLevel, OutputMin, OutputMax, Clip, [Mapped|MappedTail]) :-
    (   is_list(Head)
    ->  (   Head = []
        ->  throw(error(domain_error(non_empty_image, Head), context(map_image_value/7, 'empty image sub-structure is invalid by default'))
        ;   map_image_recursive(Head, false, OutputMin, OutputMax, Clip, Mapped)
        )
    ;   map_image_scalar(Head, OutputMin, OutputMax, Clip, Mapped)
    ),
    map_image_recursive(Tail, false, OutputMin, OutputMax, Clip, MappedTail).

map_image_channels(_, [], _, _, _, _, []) :-
    !.
map_image_channels(Channels, [Head|Tail], _TopLevel, OutputMin, OutputMax, Clip, [Mapped|MappedTail]) :-
    (   is_list(Head)
    ->  (   length(Head, Channels),
            map_image_scalar_list(Head, OutputMin, OutputMax, Clip, Mapped)
        ->  true
        ;   map_image_channels(Channels, Head, false, OutputMin, OutputMax, Clip, Mapped)
        )
    ->  true
    ;   throw(error(type_error(list, Head), context(map_image_value/7, 'RGB/RGBA mapping expects channel lists at pixel boundaries'))
    ),
    map_image_channels(Channels, Tail, false, OutputMin, OutputMax, Clip, MappedTail).

map_image_scalar_list(Values, OutputMin, OutputMax, Clip, Mapped) :-
    map_bytes_value(Values, OutputMin, OutputMax, Clip, Mapped).

map_image_scalar(Value, OutputMin, OutputMax, Clip, Mapped) :-
    map_bytes_value([Value], OutputMin, OutputMax, Clip, [Mapped]).

% Smoke helper

run_self_check :-
    map_integer_value(50, 0, 100, -1.0, 1.0, false, MappedInteger),
    MappedInteger =:= 0.0,
    map_float_value(5.0, 0.0, 10.0, -1.0, 1.0, false, MappedFloat),
    MappedFloat =:= 0.0,
    map_boolean_value(true, -1.0, 1.0, MappedBool),
    MappedBool =:= 1.0,
    map_text_value('CA', -1.0, 1.0, alphabet, false, false, 'ABC', MappedText),
    MappedText = [1.0, -1.0],
    map_sequence_integer_value([0, [50], 100], 0, 100, -1.0, 1.0, false, false, MappedSequence),
    MappedSequence = [-1.0, [0.0], 1.0],
    catch(map_sequence_integer_value([], 0, 100, -1.0, 1.0, false, false, _), _, SequenceEmptyFailed = true),
    SequenceEmptyFailed == true,
    map_text_value([0, 127, 255], -1.0, 1.0, byte, false, false, _, MappedTextBytes),
    MappedTextBytes = [-1.0, -0.0039215686274509665, 1.0],
    map_bytes_value([0, 127, 255], -1.0, 1.0, false, MappedBytes),
    MappedBytes = [-1.0, -0.0039215686274509665, 1.0],
    map_temporal_value(1700000050.0, 1700000000.0, 1700000100.0, -1.0, 1.0, false, MappedTemporal),
    MappedTemporal =:= 0.0,
    map_categorical_value(cat, [cat, 1, true, null], -1.0, 1.0, MappedCategorical),
    MappedCategorical =:= -1.0,
    map_categorical_value(1, [cat, 1, true, null], -1.0, 1.0, MappedCategoricalNumber),
    MappedCategoricalNumber =:= -0.33333333333333337,
    ObjectSchema = _{
        age: integer(0, 120),
        active: boolean,
        profile: object(_{
            score: float(0.0, 100.0)
        })
    },
    map_object_value(
        _{age: 25, active: true, profile: _{score: 50}},
        ObjectSchema,
        -1.0,
        1.0,
        false,
        false,
        false,
        MappedObject
    ),
    MappedObject = _{age:-0.5833333333333334, active:1.0, profile:_{score:-0.0}},
    Object_unknown_failed = false,
    catch(
        map_object_value(
            _{age: 25, active: false, extra: 1},
            ObjectSchema,
            -1.0,
            1.0,
            false,
            false,
            false,
            _
        ),
        _,
        Object_unknown_failed = true
    ),
    Object_unknown_failed == true,
    Object_missing_failed = false,
    catch(
        map_object_value(
            _{age: 25},
            ObjectSchema,
            -1.0,
            1.0,
            false,
            false,
            false,
            _
        ),
        _,
        Object_missing_failed = true
    ),
    Object_missing_failed == true,
    map_image_value([0, 127, 255], -1.0, 1.0, false, false, auto, MappedImage),
    MappedImage = [-1.0, -0.0039215686274509665, 1.0],
    map_image_value(
        [[0, 127, 255], [64, 192, 255]],
        -1.0,
        1.0,
        false,
        false,
        rgb,
        MappedRgbImage
    ),
    MappedRgbImage = [[-1.0, -0.0039215686274509665, 1.0], [-0.4980392156862745, 0.5058823529411764, 1.0]],
    map_image_value([], -1.0, 1.0, false, true, auto, MappedEmpty),
    MappedEmpty = [],
    ImageEmptyFailed = false,
    catch(
        map_image_value([], -1.0, 1.0, false, false, auto, _),
        _,
        ImageEmptyFailed = true
    ),
    ImageEmptyFailed == true,
    NonImageFailed = false,
    catch(
        map_image_value(0, -1.0, 1.0, false, false, auto, _),
        _,
        NonImageFailed = true
    ),
    NonImageFailed == true.
