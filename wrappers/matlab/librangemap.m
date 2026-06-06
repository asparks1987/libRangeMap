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
