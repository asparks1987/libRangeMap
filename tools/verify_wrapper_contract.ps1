param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "ada",
        "assembly",
        "delphi",
        "matlab",
        "plsql",
        "prolog",
        "ruby",
        "scratch",
        "sql",
        "swift",
        "vb6",
        "cobol"
    )]
    [string]$Language,
    [Parameter(Mandatory = $true)]
    [string]$Artifact
)

if (-not (Test-Path $Artifact -PathType Leaf)) {
    Write-Error "Missing artifact: $Artifact"
    exit 1
}

$content = Get-Content -Raw -Path $Artifact

$checks = @{
    "ada" = @(
        "Map_Integer_Value",
        "Input_Min >= Input_Max",
        "Output_Min >= Output_Max",
        "if Clip then",
        "raise Constraint_Error",
        "return Long_Float",
        "Long_Float\\(V - Input_Min\\)",
        "Output_Min \\+ \\(Long_Float\\(V - Input_Min\\) / Den\\) \\* \\(Output_Max - Output_Min\\)"
    )
    "assembly" = @(
        "librangemap_map_integer",
        "input_min",
        "input_max",
        "output_min",
        "output_max",
        "if input_min >= input_max",
        "if clip",
        "output_min \\+ \\(\\(value - input_min\\) / \\(input_max - input_min\\)\\) \\* \\(output_max - output_min\\)"
    )
    "delphi" = @(
        "function MapIntegerValue",
        "InputMin >= InputMax",
        "OutputMin >= OutputMax",
        "if Clip then",
        "Result := OutputMin \\+ \\(\\(ClippedValue - InputMin\\) / InputSpan\\) \\* OutputSpan"
    )
    "matlab" = @(
        "function y = librangemap",
        "input_min >= input_max",
        "output_min >= output_max",
        "if clip",
        "y = output_min \\+ \\(\\(double\\(input\\) - double\\(input_min\\)\\) / double\\(input_max - input_min\\)\\) \\* \\(output_max - output_min\\)"
    )
    "plsql" = @(
        "libRangeMap_map_integer",
        "p_input_min IN NUMBER",
        "p_output_min IN NUMBER",
        "IF p_input_min >= p_input_max THEN",
        "IF p_output_min >= p_output_max THEN",
        "IF p_clip THEN",
        "RAISE_APPLICATION_ERROR",
        "RETURN p_output_min \\+ \\(\\(v_value - p_input_min\\) / \\(p_input_max - p_input_min\\)\\) \\* \\(p_output_max - p_output_min\\)"
    )
    "prolog" = @(
        "map_integer_value",
        "input_min_ok",
        "output_min_ok",
        "bound_value",
        "SpanIn is InputMax - InputMin",
        "Output is OutputMin \\+ \\(\\(Bounded - InputMin\\) / SpanIn\\) \\* SpanOut"
    )
    "ruby" = @(
        "module LibrangeMap",
        "class IntegerRangeMapper",
        "def initialize",
        "raise_native_error",
        "to_json",
        "from_json",
        "LRM_ERROR_INVALID_RANGE"
    )
    "scratch" = @(
        "libRangeMap Scratch Spec",
        "inputMin < inputMax",
        "outputMin < outputMax",
        "if not clipping and value is outside bounds",
        "outputMin \\+ \\(\\(value - inputMin\\) / \\(inputMax - inputMin\\)\\) \\* \\(outputMax - outputMin\\)",
        "Expected examples"
    )
    "sql" = @(
        "CREATE OR REPLACE FUNCTION",
        "libRangeMap_map_integer",
        "p_input_min",
        "p_input_max",
        "p_output_min",
        "p_output_max",
        "p_input_min >= p_input_max",
        "value out of range",
        "librangemap_map_integer"
    )
    "swift" = @(
        "struct IntegerRangeMapper",
        "init\\(inputMin: Int64",
        "let inputSpan = Double\\(inputMax - inputMin\\)",
        "func mapValue",
        "return outputMin + \\(Double\\(v - inputMin\\) / inputSpan\\) \\* outputSpan",
        "assert\\(mapper.mapValue\\(0\\) == -1.0\\)"
    )
    "vb6" = @(
        "Public Function MapIntegerValue",
        "inputMin >= inputMax",
        "outputMin >= outputMax",
        "If clip Then",
        "Err.Raise",
        "MapIntegerValue = outputMin \\+ \\(\\(boundedValue - inputMin\\) / \\(inputMax - inputMin\\)\\) \\* \\(outputMax - outputMin\\)"
    )
    "cobol" = @(
        "Program-id\\. librangemap",
        "input-min",
        "input-max",
        "output-max",
        "Map = outputMin \\+",
        "GOBACK"
    )
}

$patternList = $checks[$Language]
if ($null -eq $patternList) {
    Write-Error "Unsupported language for contract check: $Language"
    exit 1
}

foreach ($pattern in $patternList) {
    if (-not [regex]::IsMatch($content, $pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        Write-Error "Contract check failed for $Language: missing pattern '$pattern'"
        exit 1
    }
}

exit 0
