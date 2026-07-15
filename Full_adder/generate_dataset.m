function dataset = generate_dataset( ...
    samplesPerClass, noiseProbability, outputFile)
%GENERATE_DATASET Creates a labelled full-adder fault dataset.
%
% Inputs:
%   samplesPerClass  - Samples generated for every fault class
%   noiseProbability - Probability of randomly flipping an output bit
%   outputFile       - Optional CSV output path
%
% Output:
%   dataset          - Generated labelled MATLAB table

    if nargin < 1
        samplesPerClass = 1000;
    end

    if nargin < 2
        noiseProbability = 0.01;
    end

    if nargin < 3
        outputFile = "";
    end

    if samplesPerClass < 1 || fix(samplesPerClass) ~= samplesPerClass
        error("samplesPerClass must be a positive integer.");
    end

    if noiseProbability < 0 || noiseProbability > 1
        error("noiseProbability must be between 0 and 1.");
    end

    faultClasses = [
        "NORMAL"
        "SUM_STUCK_0"
        "SUM_STUCK_1"
        "COUT_STUCK_0"
        "COUT_STUCK_1"
    ];

    % Generate all eight possible input combinations:
    % 000, 001, 010, 011, 100, 101, 110, 111
    inputVectors = dec2bin(0:7, 3) - '0';

    [correctSum, correctCout] = full_adder( ...
        inputVectors(:, 1), ...
        inputVectors(:, 2), ...
        inputVectors(:, 3));

    % Obtain one valid feature row and the feature names.
    [exampleFeatures, featureNames] = ...
        extract_signature_features( ...
            correctSum, ...
            correctCout);

    % Force consistent row-vector shapes.
    exampleFeatures = reshape(exampleFeatures, 1, []);
    featureNames = reshape(featureNames, 1, []);

    % IMPORTANT:
    % numel returns 34, whereas size(featureNames,1) would return only 1.
    numberOfFeatures = numel(exampleFeatures);
    numberOfClasses = numel(faultClasses);
    numberOfRows = samplesPerClass * numberOfClasses;

    fprintf("Number of features: %d\n", numberOfFeatures);
    fprintf("Number of dataset rows: %d\n", numberOfRows);

    % This must create an N-by-34 matrix.
    featureMatrix = zeros(numberOfRows, numberOfFeatures);
    labels = strings(numberOfRows, 1);

    rowNumber = 1;

    for classIndex = 1:numberOfClasses
        currentFault = faultClasses(classIndex);

        for sampleIndex = 1:samplesPerClass

            [observedSum, observedCout] = inject_fault( ...
                correctSum, ...
                correctCout, ...
                currentFault, ...
                noiseProbability);

            currentFeatures = extract_signature_features( ...
                observedSum, ...
                observedCout);

            % Ensure the function result is a 1-by-34 row vector.
            currentFeatures = reshape(currentFeatures, 1, []);

            % Defensive check for easier debugging.
            if numel(currentFeatures) ~= numberOfFeatures
                error( ...
                    "Feature count changed at row %d. Expected %d, received %d.", ...
                    rowNumber, ...
                    numberOfFeatures, ...
                    numel(currentFeatures));
            end

            featureMatrix(rowNumber, :) = currentFeatures;
            labels(rowNumber) = currentFault;

            rowNumber = rowNumber + 1;
        end
    end

    % Convert the numeric feature matrix into a table.
    dataset = array2table( ...
        featureMatrix, ...
        'VariableNames', featureNames);

    dataset.Label = categorical(labels);

    % Keep the classes in a predictable order.
    dataset.Label = reordercats( ...
        dataset.Label, ...
        cellstr(faultClasses));

    % Shuffle the dataset rows.
    shuffledIndexes = randperm(height(dataset));
    dataset = dataset(shuffledIndexes, :);

    % Save the dataset when an output path is supplied.
    if strlength(string(outputFile)) > 0

        outputFile = string(outputFile);
        outputFolder = fileparts(outputFile);
    

        % Create a directory only when a directory name is present.
        if strlength(outputFolder) > 0 && ~isfolder(outputFolder)
            mkdir(outputFolder);
        end

        writetable(dataset, outputFile);

        fprintf("Dataset saved to:\n%s\n", outputFile);
    end
end