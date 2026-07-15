function [trainingTable, testingTable] = split_dataset( ...
    inputData, trainingRatio)
%SPLIT_DATASET Splits labelled data into training and testing tables.

    if nargin < 2
        trainingRatio = 0.80;
    end

    if trainingRatio <= 0 || trainingRatio >= 1
        error("trainingRatio must be between 0 and 1.");
    end

    % Convert an old-style dataset object to a modern MATLAB table.
    if isa(inputData, 'dataset')
        fprintf("Converting dataset object to MATLAB table...\n");
        inputData = dataset2table(inputData);
    end

    if ~istable(inputData)
        error( ...
            "Input must be a MATLAB table. Received class: %s", ...
            class(inputData));
    end

    variableNames = inputData.Properties.VariableNames;

    if ~ismember('Label', variableNames)
        error("The input table must contain a Label column.");
    end

    % Ensure Label is categorical.
    if ~iscategorical(inputData.Label)
        inputData.Label = categorical(inputData.Label);
    end

    classNames = categories(inputData.Label);
    trainingMask = false(height(inputData), 1);

    for classIndex = 1:numel(classNames)

        currentClass = classNames{classIndex};

        classIndexes = find( ...
            inputData.Label == currentClass);

        % Shuffle samples belonging to the current class.
        classIndexes = classIndexes( ...
            randperm(numel(classIndexes)));

        numberOfTrainingRows = round( ...
            trainingRatio * numel(classIndexes));

        % Keep at least one sample for training and testing.
        if numel(classIndexes) > 1
            numberOfTrainingRows = max( ...
                1, ...
                min(numberOfTrainingRows, ...
                    numel(classIndexes) - 1));
        else
            numberOfTrainingRows = 1;
        end

        selectedIndexes = ...
            classIndexes(1:numberOfTrainingRows);

        trainingMask(selectedIndexes) = true;
    end

    trainingTable = inputData(trainingMask, :);
    testingTable = inputData(~trainingMask, :);

    % Shuffle the final tables.
    if height(trainingTable) > 1
        trainingTable = trainingTable( ...
            randperm(height(trainingTable)), :);
    end

    if height(testingTable) > 1
        testingTable = testingTable( ...
            randperm(height(testingTable)), :);
    end
end