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
