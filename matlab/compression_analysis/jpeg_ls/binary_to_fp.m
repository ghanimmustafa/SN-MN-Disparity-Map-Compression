function out = binary_to_fp(in)
S = strsplit(in, '.');
intV      = S{1} - '0';
fracV     = S{2} - '0';
intValue  = intV  * (2 .^ (numel(intV)-1:-1:0).')
fracValue = fracV * (2 .^ -(1:numel(fracV)).')
% or:
            sum(fracV ./ (2 .^ (1:numel(fracV))))
% [EDITED] Typo fixed: ^  this was \ before


end