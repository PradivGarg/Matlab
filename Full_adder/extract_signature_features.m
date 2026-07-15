function [featureRow, featureNames] = extract_signature_features( ...
    observedSum, observedCout)
%EXTRACT_SIGNATURE_FEATURES Converts full-adder outputs into AI features.
%
% Inputs:
%   observedSum  - Eight observed Sum values
%   observedCout - Eight observed Carry values
%
% Outputs:
%   featureRow   - One row containing all extracted features
%   featureNames - Names corresponding to the features

    observedSum = double(observedSum(:)');
    observedCout = double(observedCout(:)');

    if numel(observedSum) ~= 8
        error("observedSum must contain exactly eight values.");
    end

    if numel(observedCout) ~= 8
        error("observedCout must contain exactly eight values.");
    end

    if any(~ismember(observedSum, [0, 1]))
        error("observedSum must contain only zeroes and ones.");
    end

    if any(~ismember(observedCout, [0, 1]))
        error("observedCout must contain only zeroes and ones.");
    end

    % All eight possible input combinations:
    % 000, 001, 010, 011, 100, 101, 110, 111
    inputVectors = dec2bin(0:7, 3) - '0';

    [expectedSum, expectedCout] = full_adder( ...
        inputVectors(:, 1), ...
        inputVectors(:, 2), ...
        inputVectors(:, 3));

    expectedSum = double(expectedSum(:)');
    expectedCout = double(expectedCout(:)');

    % Identify incorrect outputs.
    sumErrors = double(observedSum ~= expectedSum);
    coutErrors = double(observedCout ~= expectedCout);

    % Count mismatches.
    sumMismatchCount = sum(sumErrors);
    coutMismatchCount = sum(coutErrors);

    % Create one 1-by-34 feature row.
    featureRow = [ ...
        observedSum, ...
        observedCout, ...
        sumErrors, ...
        coutErrors, ...
        sumMismatchCount, ...
        coutMismatchCount];

    % Create input-pattern labels as a row cell array.
    patterns = arrayfun( ...
        @(index) sprintf( ...
            '%d%d%d', ...
            inputVectors(index, 1), ...
            inputVectors(index, 2), ...
            inputVectors(index, 3)), ...
        1:size(inputVectors, 1), ...
        'UniformOutput', false);

    observedSumNames = strcat('ObsSum_', patterns);
    observedCoutNames = strcat('ObsCout_', patterns);
    sumErrorNames = strcat('ErrSum_', patterns);
    coutErrorNames = strcat('ErrCout_', patterns);

    featureNames = [ ...
        observedSumNames, ...
        observedCoutNames, ...
        sumErrorNames, ...
        coutErrorNames, ...
        {'SumMismatchCount', 'CoutMismatchCount'}];

    featureNames = reshape(featureNames, 1, []);

    % Internal consistency check.
    if numel(featureRow) ~= numel(featureNames)
        error( ...
            "Feature count mismatch: %d values but %d names.", ...
            numel(featureRow), ...
            numel(featureNames));
    end
end