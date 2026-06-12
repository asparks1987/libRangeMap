param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "ada",
        "assembly",
        "c",
        "c++",
        "cpp",
        "c#",
        "csharp",
        "delphi",
        "fortran",
        "go",
        "java",
        "javascript",
        "js",
        "matlab",
        "perl",
        "php",
        "plsql",
        "pl/sql",
        "python",
        "prolog",
        "r",
        "ruby",
        "scratch",
        "sql",
        "swift",
        "vb",
        "vb6",
        "classicvb",
        "classic vb",
        "cobol",
        "rust"
    )]
    [string]$Language,
    [Parameter(Mandatory = $true)]
    [string]$Artifact
)

if (-not (Test-Path $Artifact -PathType Leaf)) {
    Write-Error "Missing artifact: $Artifact"
    exit 1
}

$canonicalLanguage = switch -Regex ($Language.ToLowerInvariant()) {
    '^c\+\+$|^cpp$' { "cpp" }
    '^c\#$|^csharp$|^cs$' { "csharp" }
    '^(js|javascript)$' { "javascript" }
    '^(assembly)$' { "assembly" }
    '^(pl/?sql)$' { "plsql" }
    '^(classicvb|classic vb|vb6)$' { "vb6" }
    '^visual basic$|^vb$' { "vb" }
    '^python$|^py$' { "python" }
    default { $_.ToLowerInvariant() }
}

if ($canonicalLanguage -eq $null -or $canonicalLanguage -eq "") {
    Write-Error "Unknown language alias: $Language"
    exit 1
}

$content = Get-Content -Raw -Path $Artifact

if ($canonicalLanguage -eq "python") {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $initPath = Join-Path $repoRoot "librangemap\__init__.py"
    $integerPath = Join-Path $repoRoot "librangemap\integer.py"
    if (Test-Path $initPath) {
        $content += "`n" + (Get-Content -Raw -Path $initPath)
    }
    if (Test-Path $integerPath) {
        $content += "`n" + (Get-Content -Raw -Path $integerPath)
    }
}

$checks = @{
    "ada" = @(
        "map_integer_value",
        "input_min >=",
        "output_min >=",
        "return output_min +"
    )
    "assembly" = @(
        "librangemap_map_integer",
        "input_min",
        "output_min",
        "output_max",
        "return output_min + (("
    )
    "c" = @(
        "lrm_map_integer",
        "lrm_integer_range_mapper_init",
        "lrm_integer_range_mapper_map_value",
        "status"
    )
    "cpp" = @(
        "integer_range_mapper",
        "lrm_integer_range_mapper_init",
        "lrm_integer_range_mapper_map_value",
        "to_json"
    )
    "csharp" = @(
        "integerrangemapper",
        "lrm_integer_range_mapper_init",
        "mapvalue(",
        "tojson",
        "fromjson"
    )
    "delphi" = @(
        "mapintegervalue",
        "inputmin >=",
        "outputmin >= outputmax",
        "result :="
    )
    "fortran" = @(
        "module librangemap_integer",
        "map_integer_value",
        "input_min >=",
        "output_min >="
    )
    "go" = @(
        "type integerrangemapper struct",
        "func newintegerrangemapper",
        "func (m *integerrangemapper) mapvalue",
        "tojson"
    )
    "java" = @(
        "class integerrangemapper",
        "mapvalue(",
        "tojson",
        "fromjson",
        "inputmin"
    )
    "javascript" = @(
        "class integerrangemapper",
        "mapvalue(",
        "tojson()",
        "fromjson",
        "input_range"
    )
    "matlab" = @(
        "function y = librangemap",
        "input_min >=",
        "output_min >=",
        "output_min + (("
    )
    "perl" = @(
        "map_integer_value",
        "input_min >=",
        'return $output_min'
    )
    "php" = @(
        "function map_integer_value",
        "inputmin >=",
        "outputmin >=",
        'return $outputmin + (($v - $inputmin) / ($inputmax - $inputmin)) * ($outputmax - $outputmin)'
    )
    "plsql" = @(
        "create or replace function librangemap_map_integer",
        "p_input_min >= p_input_max",
        "p_output_min >= p_output_max",
        "value out of range"
    )
    "prolog" = @(
        "map_integer_value",
        "input_min_ok",
        "output_min_ok",
        "bound_value",
        "spanin is inputmax - inputmin"
    )
    "python" = @(
        "integerrangemapper",
        "from .integer import",
        "def map_value",
        "to_json",
        "from_json",
        "spec_version"
    )
    "r" = @(
        "map_integer_value <- function",
        "input_min >=",
        "output_min >=",
        "map_value <- function"
    )
    "ruby" = @(
        "module librangemap",
        "class integerrangemapper",
        "def map_value",
        "def to_json",
        "self.from_spec"
    )
    "scratch" = @(
        "librangemap scratch spec",
        "inputmin < inputmax",
        "if not clipping and value is outside bounds",
        "expected examples"
    )
    "sql" = @(
        "create or replace function librangemap_map_integer",
        "p_input_min >= p_input_max",
        "p_output_min >= p_output_max",
        "value out of range"
    )
    "swift" = @(
        "struct integerrangemapper",
        "func mapvalue",
        "func runselfcheck",
        "inputmin: int64"
    )
    "vb" = @(
        "integerrangemapper",
        "lrm_integer_range_mapper_init",
        "mapvalue(",
        "tojson",
        "fromjson"
    )
    "vb6" = @(
        "public function mapintegervalue",
        "inputmin >= inputmax",
        "outputmin >= outputmax",
        "mapintegervalue ="
    )
    "cobol" = @(
        "librangemap",
        "goback.",
        "working-storage",
        "program-id."
    )
    "rust" = @(
        "struct integerrangemapper",
        "fn map_value(",
        "to_json(",
        "from_json("
    )
}

$patternList = $checks[$canonicalLanguage]
if ($null -eq $patternList) {
    Write-Error "Unsupported language for contract check: $canonicalLanguage"
    exit 1
}

$normalizedContent = $content.ToLowerInvariant()
foreach ($pattern in $patternList) {
    if (-not $normalizedContent.Contains($pattern)) {
        Write-Error "Contract check failed for ${canonicalLanguage}: missing pattern '$pattern'"
        exit 1
    }
}

exit 0
