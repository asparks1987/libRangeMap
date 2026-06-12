function y = librangemap(input, input_min, input_max, output_min, output_max, clip)
if nargin < 4 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 5 || isempty(output_max)
    output_max = 1.0;
end
if nargin < 6
    clip = false;
end

if ~(floor(input) == input)
    error('value must be integer');
end
if input_min >= input_max
    error('input_min must be less than input_max');
end
if output_min >= output_max
    error('output_min must be less than output_max');
end

if clip
    input = max(input_min, min(input, input_max));
else
    if input < input_min || input > input_max
        error('value out of range');
    end
end

y = output_min + ((double(input) - double(input_min)) / double(input_max - input_min)) * (output_max - output_min);
end

function y = librangemap_float(input, input_min, input_max, output_min, output_max, clip, allow_integer)
if nargin < 4 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 5 || isempty(output_max)
    output_max = 1.0;
end
if nargin < 6 || isempty(clip)
    clip = false;
end
if nargin < 7 || isempty(allow_integer)
    allow_integer = true;
end

if ~isscalar(input) || ~isnumeric(input) || ~isfinite(input)
    error('value must be a finite numeric scalar');
end
if ~allow_integer && floor(input) == input
    error('integer input is disabled by policy');
end
if input_min >= input_max
    error('input_min must be less than input_max');
end
if output_min >= output_max
    error('output_min must be less than output_max');
end

if clip
    input = max(input_min, min(input, input_max));
else
    if input < input_min || input > input_max
        error('value out of range');
    end
end

y = output_min + ((double(input) - double(input_min)) / double(input_max - input_min)) * (output_max - output_min);
end

function y = librangemap_boolean(input, false_value, true_value)
if nargin < 2 || isempty(false_value)
    false_value = -1.0;
end
if nargin < 3 || isempty(true_value)
    true_value = 1.0;
end

if ~isscalar(input) || ~islogical(input)
    error('value must be logical');
end
if ~isfinite(false_value) || ~isfinite(true_value)
    error('boolean outputs must be finite');
end

if input
    y = true_value;
else
    y = false_value;
end
end

function y = librangemap_text(input, mode, alphabet, output_min, output_max)
if nargin < 2 || isempty(mode)
    mode = "codepoint";
end
if nargin < 3 || isempty(alphabet)
    alphabet = "";
end
if nargin < 4 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 5 || isempty(output_max)
    output_max = 1.0;
end

if ~(isstring(input) || ischar(input))
    error('value must be a string scalar or character row vector');
end
if isstring(input)
    if ~isscalar(input)
        error('value must be a string scalar or character row vector');
    end
    input = char(input);
end
if isempty(input)
    error('empty text input is invalid by default');
end
if ~isfinite(output_min) || ~isfinite(output_max)
    error('output values must be finite');
end
if output_min >= output_max
    error('output_min must be less than output_max');
end

mode = lower(string(mode));
if mode == "alphabet"
    if ~(isstring(alphabet) || ischar(alphabet))
        error('alphabet must be a string scalar or character row vector');
    end
    if isstring(alphabet)
        if ~isscalar(alphabet)
            error('alphabet must be a string scalar or character row vector');
        end
        alphabet = char(alphabet);
    end
    if isempty(alphabet)
        error('alphabet must not be empty');
    end
    if numel(unique(cellstr(num2cell(alphabet(:))))) ~= numel(alphabet)
        error('alphabet must be unique');
    end
end

y = zeros(1, numel(input));
switch mode
    case {"codepoint", "byte"}
        for i = 1:numel(input)
            y(i) = output_min + ((double(uint16(input(i))) / 255.0) * (output_max - output_min));
        end
    case "alphabet"
        for i = 1:numel(input)
            idx = find(alphabet == input(i), 1);
            if isempty(idx)
                error('unknown text token');
            end
            if numel(alphabet) == 1
                y(i) = (output_min + output_max) / 2.0;
            else
                y(i) = output_min + ((double(idx - 1) / double(numel(alphabet) - 1)) * (output_max - output_min));
            end
        end
    otherwise
        error('unknown text mode');
end
end

function y = librangemap_temporal(input, input_min, input_max, output_min, output_max, clip)
if nargin < 4 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 5 || isempty(output_max)
    output_max = 1.0;
end
if nargin < 6 || isempty(clip)
    clip = false;
end

if ~(isscalar(input) && (isnumeric(input) || isdatetime(input)))
    error('value must be a numeric timestamp or datetime scalar');
end
if isdatetime(input)
    input = posixtime(input);
end
if ~isfinite(input) || ~isfinite(input_min) || ~isfinite(input_max) || ~isfinite(output_min) || ~isfinite(output_max)
    error('value and range endpoints must be finite');
end
if input_min >= input_max
    error('input_min must be less than input_max');
end
if output_min >= output_max
    error('output_min must be less than output_max');
end

if clip
    input = max(input_min, min(input, input_max));
else
    if input < input_min || input > input_max
        error('value out of range');
    end
end

y = output_min + ((double(input) - double(input_min)) / double(input_max - input_min)) * (output_max - output_min);
end

function y = librangemap_bytes(input, output_min, output_max, clip, allow_empty)
if nargin < 2 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 3 || isempty(output_max)
    output_max = 1.0;
end
if nargin < 4 || isempty(clip)
    clip = false;
end
if nargin < 5 || isempty(allow_empty)
    allow_empty = false;
end

if isstring(input) && isscalar(input)
    input = char(input);
end
if ischar(input)
    input = uint8(input);
end
if ~isnumeric(input) || ~isvector(input)
    error('value must be a string or numeric byte vector');
end
if any(floor(double(input)) ~= double(input))
    error('byte values must be integers');
end
if isempty(input)
    if allow_empty
        y = zeros(1, 0);
        return;
    end
    error('empty bytes input is invalid by default');
end
if ~isfinite(output_min) || ~isfinite(output_max)
    error('output values must be finite');
end
if output_min >= output_max
    error('output_min must be less than output_max');
end

input = double(input);
if clip
    input(input < 0) = 0;
    input(input > 255) = 255;
else
    if any(input < 0 | input > 255)
        error('byte value out of range');
    end
end

y = output_min + ((input ./ 255.0) * (output_max - output_min));
end

function y = librangemap_image(input, output_min, output_max, clip, allow_empty)
if nargin < 2 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 3 || isempty(output_max)
    output_max = 1.0;
end
if nargin < 4 || isempty(clip)
    clip = false;
end
if nargin < 5 || isempty(allow_empty)
    allow_empty = false;
end

if isempty(input)
    if allow_empty
        y = zeros(size(input));
        return;
    end
    error('empty image input is invalid by default');
end
if ~isnumeric(input) || ~ismatrix(input)
    error('value must be a numeric matrix');
end
if ~isfinite(output_min) || ~isfinite(output_max)
    error('output values must be finite');
end
if output_min >= output_max
    error('output_min must be less than output_max');
end

y = zeros(size(input));
for row = 1:size(input, 1)
    for col = 1:size(input, 2)
        value = double(input(row, col));
        if floor(value) ~= value
            error('image values must be integers');
        end
        if clip
            value = max(0, min(value, 255));
        else
            if value < 0 || value > 255
                error('image value out of range');
            end
        end
        y(row, col) = output_min + ((value / 255.0) * (output_max - output_min));
    end
end
end

function y = librangemap_categorical(input, tokens, output_min, output_max)
if nargin < 3 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 4 || isempty(output_max)
    output_max = 1.0;
end

if ~(isstring(input) || ischar(input))
    error('value must be a string scalar or character row vector');
end
if isstring(input)
    if ~isscalar(input)
        error('value must be a string scalar or character row vector');
    end
    input = char(input);
end
if ~(iscellstr(tokens) || isstring(tokens))
    error('tokens must be a cell array of character vectors or string array');
end
tokens = cellstr(tokens);
if isempty(tokens)
    error('tokens must not be empty');
end
if numel(unique(tokens)) ~= numel(tokens)
    error('tokens must be unique');
end
if ~isfinite(output_min) || ~isfinite(output_max)
    error('output values must be finite');
end
if output_min >= output_max
    error('output_min must be less than output_max');
end

index = find(strcmp(tokens, input), 1);
if isempty(index)
    error('unknown categorical token');
end

if numel(tokens) == 1
    y = (output_min + output_max) / 2.0;
    return;
end

y = output_min + ((double(index - 1) / double(numel(tokens) - 1)) * (output_max - output_min));
end

function y = librangemap_sequence(values, input_min, input_max, output_min, output_max, clip)
if nargin < 4 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 5 || isempty(output_max)
    output_max = 1.0;
end
if nargin < 6 || isempty(clip)
    clip = false;
end

if isempty(values)
    error('empty sequence input is invalid by default');
end
if ~isnumeric(values)
    error('values must be numeric');
end
if isvector(values)
    y = zeros(size(values));
    for i = 1:numel(values)
        y(i) = librangemap(values(i), input_min, input_max, output_min, output_max, clip);
    end
    return;
end

if ndims(values) == 2
    y = zeros(size(values));
    for row = 1:size(values, 1)
        y(row, :) = librangemap_sequence(values(row, :), input_min, input_max, output_min, output_max, clip);
    end
    return;
end

error('values must be a vector or matrix');
end

function y = librangemap_object(schema, fields, allow_unknown, output_min, output_max)
if nargin < 3 || isempty(allow_unknown)
    allow_unknown = false;
end
if nargin < 4 || isempty(output_min)
    output_min = -1.0;
end
if nargin < 5 || isempty(output_max)
    output_max = 1.0;
end

if ~isstruct(schema) || isempty(schema)
    error('schema must be a non-empty struct array');
end
if ~isstruct(fields) || isempty(fields)
    error('object input must be a non-empty struct array');
end
if ~isfinite(output_min) || ~isfinite(output_max)
    error('object output bounds must be finite');
end
if output_min >= output_max
    error('object output_min must be less than output_max');
end
if ~isfield(schema, 'name') || ~isfield(schema, 'family')
    error('schema fields require name and family');
end
if ~isfield(fields, 'name') || ~isfield(fields, 'family') || ~isfield(fields, 'value')
    error('input fields require name, family, and value');
end

schema_names = strings(1, numel(schema));
for i = 1:numel(schema)
    schema_names(i) = string(schema(i).name);
    if strlength(schema_names(i)) == 0
        error('schema field names must not be empty');
    end
end
if numel(unique(schema_names)) ~= numel(schema_names)
    error('schema field names must be unique');
end

field_names = strings(1, numel(fields));
for i = 1:numel(fields)
    field_names(i) = string(fields(i).name);
    if strlength(field_names(i)) == 0
        error('input field names must not be empty');
    end
end
if numel(unique(field_names)) ~= numel(field_names)
    error('input field names must be unique');
end

[sorted_names, order] = sort(schema_names);
sorted_schema = schema(order);
y = zeros(1, numel(sorted_schema));

for i = 1:numel(sorted_schema)
    spec = sorted_schema(i);
    input_index = find(field_names == sorted_names(i), 1);
    if isempty(input_index)
        if lrm_optional_bool(spec, 'allow_missing', false)
            y(i) = lrm_optional_double(spec, 'missing_value', 0.0);
            continue;
        end
        error('missing required field');
    end

    field = fields(input_index);
    if lrm_optional_bool(field, 'has_value', true) == false
        if lrm_optional_bool(spec, 'allow_missing', false)
            y(i) = lrm_optional_double(spec, 'missing_value', 0.0);
            continue;
        end
        error('missing required field value');
    end

    family = lower(string(spec.family));
    if lower(string(field.family)) ~= family
        error('field type mismatch');
    end

    switch family
        case "integer"
            y(i) = librangemap( ...
                field.value, ...
                lrm_required_double(spec, 'input_min'), ...
                lrm_required_double(spec, 'input_max'), ...
                lrm_optional_double(spec, 'output_min', output_min), ...
                lrm_optional_double(spec, 'output_max', output_max), ...
                lrm_optional_bool(spec, 'clip', false));
        case "float"
            y(i) = librangemap_float( ...
                field.value, ...
                lrm_required_double(spec, 'input_min'), ...
                lrm_required_double(spec, 'input_max'), ...
                lrm_optional_double(spec, 'output_min', output_min), ...
                lrm_optional_double(spec, 'output_max', output_max), ...
                lrm_optional_bool(spec, 'clip', false), ...
                lrm_optional_bool(spec, 'allow_integer', true));
        case "boolean"
            y(i) = librangemap_boolean( ...
                field.value, ...
                lrm_optional_double(spec, 'false_value', -1.0), ...
                lrm_optional_double(spec, 'true_value', 1.0));
        case "text"
            mapped = librangemap_text( ...
                field.value, ...
                lrm_optional_string(spec, 'mode', "codepoint"), ...
                lrm_optional_string(spec, 'alphabet', ""), ...
                lrm_optional_double(spec, 'output_min', output_min), ...
                lrm_optional_double(spec, 'output_max', output_max));
            if isempty(mapped)
                error('text field produced empty output');
            end
            y(i) = mean(mapped(:));
        case "bytes"
            mapped = librangemap_bytes( ...
                field.value, ...
                lrm_optional_double(spec, 'output_min', output_min), ...
                lrm_optional_double(spec, 'output_max', output_max), ...
                lrm_optional_bool(spec, 'clip', false), ...
                lrm_optional_bool(spec, 'allow_empty', false));
            if isempty(mapped)
                if lrm_optional_bool(spec, 'allow_empty', false)
                    y(i) = 0.0;
                else
                    error('bytes field produced empty output');
                end
            else
                y(i) = mean(mapped(:));
            end
        case "integer_sequence"
            mapped = librangemap_sequence( ...
                field.value, ...
                lrm_required_double(spec, 'input_min'), ...
                lrm_required_double(spec, 'input_max'), ...
                lrm_optional_double(spec, 'output_min', output_min), ...
                lrm_optional_double(spec, 'output_max', output_max), ...
                lrm_optional_bool(spec, 'clip', false));
            if isempty(mapped)
                error('sequence field produced empty output');
            end
            y(i) = mean(mapped(:));
        case "float_sequence"
            values = field.value;
            if isempty(values)
                error('sequence field produced empty output');
            end
            if ~isnumeric(values)
                error('sequence field values must be numeric');
            end
            mapped = zeros(size(values));
            for j = 1:numel(values)
                mapped(j) = librangemap_float( ...
                    values(j), ...
                    lrm_required_double(spec, 'input_min'), ...
                    lrm_required_double(spec, 'input_max'), ...
                    lrm_optional_double(spec, 'output_min', output_min), ...
                    lrm_optional_double(spec, 'output_max', output_max), ...
                    lrm_optional_bool(spec, 'clip', false), ...
                    lrm_optional_bool(spec, 'allow_integer', true));
            end
            y(i) = mean(mapped(:));
        otherwise
            error('unsupported family for object mapping');
    end
end

if ~allow_unknown
    for i = 1:numel(field_names)
        if all(field_names(i) ~= sorted_names)
            error('unknown field in object input');
        end
    end
end
end

function value = lrm_required_double(spec, name)
if ~isfield(spec, name) || isempty(spec.(name))
    error('schema field is missing required numeric metadata');
end
value = spec.(name);
if ~isscalar(value) || ~isnumeric(value) || ~isfinite(value)
    error('schema numeric metadata must be finite scalar');
end
value = double(value);
end

function value = lrm_optional_double(spec, name, default_value)
value = default_value;
if isfield(spec, name) && ~isempty(spec.(name))
    candidate = spec.(name);
    if ~isscalar(candidate) || ~isnumeric(candidate) || ~isfinite(candidate)
        error('schema numeric metadata must be finite scalar');
    end
    value = double(candidate);
end
end

function value = lrm_optional_bool(spec, name, default_value)
value = default_value;
if isfield(spec, name) && ~isempty(spec.(name))
    candidate = spec.(name);
    if ~isscalar(candidate) || ~islogical(candidate)
        error('schema boolean metadata must be logical scalar');
    end
    value = logical(candidate);
end
end

function value = lrm_optional_string(spec, name, default_value)
value = default_value;
if isfield(spec, name) && ~isempty(spec.(name))
    candidate = spec.(name);
    if ~(isstring(candidate) || ischar(candidate))
        error('schema text metadata must be string or character data');
    end
value = string(candidate);
end
end
