function [observedSum, observedCout] = inject_fault( ...
    correctSum, correctCout, faultType, noiseProbability)
%INJECT_FAULT Injects a simulated full-adder output fault.
%
% Supported fault types:
%   NORMAL
%   SUM_STUCK_0
%   SUM_STUCK_1
%   COUT_STUCK_0
%   COUT_STUCK_1

    if nargin < 4
        noiseProbability = 0;
    end

    if noiseProbability < 0 || noiseProbability > 1
        error("noiseProbability must be between 0 and 1.");
    end

    observedSum = correctSum;
    observedCout = correctCout;

    % Convert strings, categorical values or character vectors into
    % a normalized character vector.
    faultType = upper(strtrim(char(string(faultType))));

    switch faultType
        case 'NORMAL'
            % Outputs remain unchanged.

        case 'SUM_STUCK_0'
            observedSum = zeros(size(correctSum));

        case 'SUM_STUCK_1'
            observedSum = ones(size(correctSum));

        case 'COUT_STUCK_0'
            observedCout = zeros(size(correctCout));

        case 'COUT_STUCK_1'
            observedCout = ones(size(correctCout));

        otherwise
            error( ...
                'Unsupported fault type: "%s"', ...
                faultType);
    end

    % Add optional transient noise.
    if noiseProbability > 0
        sumNoise = rand(size(observedSum)) < noiseProbability;
        coutNoise = rand(size(observedCout)) < noiseProbability;

        observedSum = xor(logical(observedSum), sumNoise);
        observedCout = xor(logical(observedCout), coutNoise);

        observedSum = double(observedSum);
        observedCout = double(observedCout);
    end
end