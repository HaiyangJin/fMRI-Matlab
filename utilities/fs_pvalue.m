function pOutput = fs_pvalue(pInput, outputType)
% pOutput = fs_pvalue(pInput, outputType)
%
% This function converts between the real p-values ['p'] (e.g., 0.01) between the
% p-values used in FreeSurfer ['fsp'] (negative log(10) p-values).
%
% Inputs:
%     pInput         <array of numeric> an numeric array for input
%                     p-values.
%     outputType     <numeric> or <string> the output can be the real
%                     p-values [1, 'p'] or FreeSurfer p-values [2, 
%                     'fsp']. By default, the output is FreeSurfer
%                     p-values.
%
% Output:
%     pOutput        <array of numeric> for output p-values.
%
% Created by Haiyang Jin (27-March-2020)

if nargin < 2 || isempty(outputType)
    outputCode = 2;
elseif ischar(outputType)
    outputCode = find(strcmp(outputType, {'p', 'fsp'}));
    assert(~isempty(outputCode), 'Can not recognize the outputType (''%s'').',...
        outputType);
else
    outputCode = outputType;
    assert(ismember(outputCode, [1, 2]), ...
        'Can not recognize the outputType (''%d'').', outputType);
end

%% identify the input type
% p ~ (0, 1)
% fsp ~ (0, +unlimited)
isPosi = pInput > 0;
isP = isPosi & pInput < 1;

if all(isP(:))
    inputCode = 1; % real p-values
elseif any(~isPosi(:))
    error('pInput has to be positive values.');
else
    inputCode = 2; % FreeSurfer p-values
end

%% convert the p-values if necessary
if inputCode == outputCode
    % keep it the same
    pOutput = pInput;
else
    % conver the p-values
    switch outputCode
        case 1
            % converting FreeSurfer p-values to real p-values
            pOutput = arrayfun(@(x) 10^(-x), pInput);
            
        case 2
            % converting real p-values to FreeSurfer p-values
            pOutput = arrayfun(@(x) -log10(x), pInput);
    end

end