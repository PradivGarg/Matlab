%% main.m
% FULL-ADDER FAULT CLASSIFICATION PROJECT
%
% Required files:
%   generate_dataset.m
%   train_classifier.m
%   evaluate_classifier.m
%
% Workflow:
%   1. Generate a labelled full-adder fault dataset
%   2. Validate the dataset
%   3. Split it into training and testing data
%   4. Train a decision-tree classifier
%   5. Evaluate the classifier
%   6. Save the model, datasets, and evaluation results

clear;
clc;
close all;

fprintf('====================================================\n');
fprintf('     FULL-ADDER FAULT CLASSIFICATION PROJECT\n');
fprintf('====================================================\n\n');


%% ---------------------------------------------------------------
% Configuration
% ---------------------------------------------------------------

samplesPerClass = 1000;
noiseProbability = 0.01;

testFraction = 0.20;
randomSeed = 42;

outputFolder = 'output';

datasetFile = fullfile( ...
    outputFolder, ...
    'full_adder_fault_dataset.csv');

trainingFile = fullfile( ...
    outputFolder, ...
    'training_dataset.csv');

testingFile = fullfile( ...
    outputFolder, ...
    'testing_dataset.csv');

modelFile = fullfile( ...
    outputFolder, ...
    'full_adder_fault_classifier.mat');

summaryFile = fullfile( ...
    outputFolder, ...
    'classifier_summary.csv');

metricsFile = fullfile( ...
    outputFolder, ...
    'classifier_class_metrics.csv');

predictionFile = fullfile( ...
    outputFolder, ...
    'sample_predictions.csv');


%% ---------------------------------------------------------------
% Create output directory
% ---------------------------------------------------------------

if ~isfolder(outputFolder)
    mkdir(outputFolder);
    fprintf('Created output folder: %s\n\n', outputFolder);
end


%% ---------------------------------------------------------------
% Check required project files
% ---------------------------------------------------------------

requiredFunctions = { ...
    'generate_dataset', ...
    'train_classifier', ...
    'evaluate_classifier'};

for functionIndex = 1:numel(requiredFunctions)

    functionName = requiredFunctions{functionIndex};

    if exist(functionName, 'file') ~= 2
        error( ...
            'Required function file "%s.m" was not found.', ...
            functionName);
    end
end

fprintf('Required project files found successfully.\n');


%% ---------------------------------------------------------------
% Check required MATLAB toolbox functions
% ---------------------------------------------------------------

requiredToolboxFunctions = { ...
    'cvpartition', ...
    'fitctree', ...
    'confusionmat'};

for functionIndex = 1:numel(requiredToolboxFunctions)

    functionName = requiredToolboxFunctions{functionIndex};

    if exist(functionName, 'file') ~= 2
        error( ...
            ['Required MATLAB function "%s" was not found. ' ...
             'Install the Statistics and Machine Learning Toolbox.'], ...
            functionName);
    end
end

fprintf('Required toolbox functions are available.\n\n');


%% ---------------------------------------------------------------
% Display configuration
% ---------------------------------------------------------------

fprintf('Project configuration\n');
fprintf('---------------------\n');
fprintf('Samples per class : %d\n', samplesPerClass);
fprintf('Noise probability : %.4f\n', noiseProbability);
fprintf('Test fraction     : %.2f\n', testFraction);
fprintf('Random seed       : %d\n\n', randomSeed);


%% ---------------------------------------------------------------
% Step 1: Generate dataset
% ---------------------------------------------------------------

fprintf('Step 1: Generating dataset...\n');

dataset = generate_dataset( ...
    samplesPerClass, ...
    noiseProbability, ...
    datasetFile);

if ~istable(dataset)
    error('generate_dataset must return a MATLAB table.');
end

if height(dataset) == 0
    error('The generated dataset is empty.');
end

fprintf('Dataset generated successfully.\n');
fprintf('Total samples    : %d\n', height(dataset));
fprintf('Total variables  : %d\n\n', width(dataset));


%% ---------------------------------------------------------------
% Validate dataset structure
% ---------------------------------------------------------------

variableNames = dataset.Properties.VariableNames;

if ~ismember('Label', variableNames)
    error('The generated dataset must contain a column named Label.');
end

if width(dataset) < 2
    error( ...
        ['The dataset must contain at least one predictor column ' ...
         'and one Label column.']);
end


%% ---------------------------------------------------------------
% Remove rows containing missing values
% ---------------------------------------------------------------

initialRowCount = height(dataset);

dataset = rmmissing(dataset);

removedRowCount = initialRowCount - height(dataset);

if removedRowCount > 0
    warning( ...
        '%d rows containing missing values were removed.', ...
        removedRowCount);
end

if height(dataset) == 0
    error('No valid rows remain after removing missing values.');
end


%% ---------------------------------------------------------------
% Convert Label into categorical form
% ---------------------------------------------------------------

dataset.Label = categorical(string(dataset.Label));

if any(ismissing(dataset.Label))
    error('The Label column contains missing or invalid values.');
end

classNames = categories(dataset.Label);
numberOfClasses = numel(classNames);

if numberOfClasses < 2
    error('At least two fault classes are required.');
end


%% ---------------------------------------------------------------
% Display complete dataset class distribution
% ---------------------------------------------------------------

fprintf('Detected fault classes\n');
fprintf('----------------------\n');

for classIndex = 1:numberOfClasses

    currentClass = classNames{classIndex};

    classCount = sum( ...
        dataset.Label == currentClass);

    fprintf( ...
        '%-22s : %d samples\n', ...
        currentClass, ...
        classCount);
end

fprintf('\n');


%% ---------------------------------------------------------------
% Identify predictor columns
% ---------------------------------------------------------------

initialPredictorNames = variableNames;
initialPredictorNames(strcmp(initialPredictorNames, 'Label')) = [];

if isempty(initialPredictorNames)
    error('No predictor columns were found in the dataset.');
end

fprintf('Predictor columns\n');
fprintf('-----------------\n');

for predictorIndex = 1:numel(initialPredictorNames)
    fprintf('  %s\n', initialPredictorNames{predictorIndex});
end

fprintf('\n');


%% ---------------------------------------------------------------
% Step 2: Split dataset
% ---------------------------------------------------------------

fprintf('Step 2: Splitting dataset into training and testing sets...\n');

rng(randomSeed, 'twister');

partition = cvpartition( ...
    dataset.Label, ...
    'HoldOut', ...
    testFraction);

trainingIndices = training(partition);
testingIndices = test(partition);

trainingTable = dataset(trainingIndices, :);
testTable = dataset(testingIndices, :);

if height(trainingTable) == 0
    error('The training dataset is empty.');
end

if height(testTable) == 0
    error('The testing dataset is empty.');
end

fprintf('Dataset split completed successfully.\n');
fprintf('Training samples : %d\n', height(trainingTable));
fprintf('Testing samples  : %d\n\n', height(testTable));


%% ---------------------------------------------------------------
% Display split class distribution
% ---------------------------------------------------------------

fprintf('Class distribution after splitting\n');
fprintf('----------------------------------\n');

fprintf( ...
    '%-22s %-12s %-12s\n', ...
    'Class', ...
    'Training', ...
    'Testing');

fprintf( ...
    '%-22s %-12s %-12s\n', ...
    repmat('-', 1, 20), ...
    repmat('-', 1, 10), ...
    repmat('-', 1, 10));

for classIndex = 1:numberOfClasses

    currentClass = classNames{classIndex};

    trainingCount = sum( ...
        trainingTable.Label == currentClass);

    testingCount = sum( ...
        testTable.Label == currentClass);

    fprintf( ...
        '%-22s %-12d %-12d\n', ...
        currentClass, ...
        trainingCount, ...
        testingCount);
end

fprintf('\n');


%% ---------------------------------------------------------------
% Save training and testing datasets
% ---------------------------------------------------------------

writetable(trainingTable, trainingFile);
writetable(testTable, testingFile);

fprintf('Training dataset saved to:\n');
fprintf('  %s\n', trainingFile);

fprintf('Testing dataset saved to:\n');
fprintf('  %s\n\n', testingFile);


%% ---------------------------------------------------------------
% Step 3: Train classifier
% ---------------------------------------------------------------

fprintf('Step 3: Training classifier...\n');

[model, predictorNames] = train_classifier( ...
    trainingTable, ...
    modelFile);

if isempty(model)
    error('train_classifier returned an empty model.');
end

if isempty(predictorNames)
    error('train_classifier returned no predictor names.');
end

% Ensure predictor names are stored as a cell array of character vectors.
predictorNames = cellstr(string(predictorNames));

fprintf('Classifier trained successfully.\n');
fprintf('Model saved to:\n');
fprintf('  %s\n\n', modelFile);


%% ---------------------------------------------------------------
% Validate predictor names
% ---------------------------------------------------------------

testVariableNames = testTable.Properties.VariableNames;

missingPredictors = setdiff( ...
    predictorNames, ...
    testVariableNames);

if ~isempty(missingPredictors)

    error( ...
        'Testing data is missing predictor columns: %s', ...
        strjoin(missingPredictors, ', '));
end


%% ---------------------------------------------------------------
% Step 4: Evaluate classifier
% ---------------------------------------------------------------

fprintf('Step 4: Evaluating classifier...\n');

[summaryTable, metricsTable] = evaluate_classifier( ...
    model, ...
    testTable, ...
    predictorNames);

if ~istable(summaryTable)
    error('evaluate_classifier must return summaryTable as a table.');
end

if ~istable(metricsTable)
    error('evaluate_classifier must return metricsTable as a table.');
end

fprintf('Classifier evaluation completed successfully.\n\n');


%% ---------------------------------------------------------------
% Save evaluation tables
% ---------------------------------------------------------------

writetable(summaryTable, summaryFile);
writetable(metricsTable, metricsFile);

fprintf('Evaluation results saved successfully.\n');

fprintf('Summary file:\n');
fprintf('  %s\n', summaryFile);

fprintf('Class metrics file:\n');
fprintf('  %s\n\n', metricsFile);


%% ---------------------------------------------------------------
% Display evaluation results
% ---------------------------------------------------------------

fprintf('====================================================\n');
fprintf('              CLASSIFIER SUMMARY\n');
fprintf('====================================================\n');

disp(summaryTable);

fprintf('====================================================\n');
fprintf('              PER-CLASS METRICS\n');
fprintf('====================================================\n');

disp(metricsTable);


%% ---------------------------------------------------------------
% Direct prediction verification
% ---------------------------------------------------------------

fprintf('Performing direct prediction verification...\n');

testPredictors = testTable(:, predictorNames);

predictedLabels = predict( ...
    model, ...
    testPredictors);

% Convert both label arrays to string column vectors.
actualLabelText = string(testTable.Label);
predictedLabelText = string(predictedLabels);

actualLabelText = actualLabelText(:);
predictedLabelText = predictedLabelText(:);

if numel(actualLabelText) ~= numel(predictedLabelText)

    error( ...
        ['The number of actual labels does not match the ' ...
         'number of predicted labels.']);
end

correctPredictionMask = ...
    actualLabelText == predictedLabelText;

directAccuracy = mean(correctPredictionMask);

fprintf( ...
    'Direct test accuracy: %.4f or %.2f%%\n\n', ...
    directAccuracy, ...
    directAccuracy * 100);


%% ---------------------------------------------------------------
% Create complete prediction results table
% ---------------------------------------------------------------

testSampleNumber = (1:numel(actualLabelText))';

testSampleNumber = testSampleNumber(:);
actualLabelText = actualLabelText(:);
predictedLabelText = predictedLabelText(:);
correctPredictionMask = correctPredictionMask(:);

predictionResultsTable = table( ...
    testSampleNumber, ...
    actualLabelText, ...
    predictedLabelText, ...
    correctPredictionMask, ...
    'VariableNames', { ...
        'SampleNumber', ...
        'ActualLabel', ...
        'PredictedLabel', ...
        'CorrectPrediction'});

writetable( ...
    predictionResultsTable, ...
    predictionFile);

fprintf('Complete prediction results saved to:\n');
fprintf('  %s\n\n', predictionFile);


%% ---------------------------------------------------------------
% Display sample predictions
% ---------------------------------------------------------------

numberOfExamples = min(10, height(predictionResultsTable));

samplePredictionTable = ...
    predictionResultsTable(1:numberOfExamples, :);

fprintf('Sample predictions\n');
fprintf('------------------\n');

disp(samplePredictionTable);


%% ---------------------------------------------------------------
% Display incorrect prediction count
% ---------------------------------------------------------------

incorrectPredictionCount = sum(~correctPredictionMask);
correctPredictionCount = sum(correctPredictionMask);

fprintf('Prediction verification\n');
fprintf('-----------------------\n');
fprintf('Correct predictions   : %d\n', correctPredictionCount);
fprintf('Incorrect predictions : %d\n', incorrectPredictionCount);
fprintf('Total predictions     : %d\n\n', numel(actualLabelText));


%% ---------------------------------------------------------------
% Display incorrectly classified examples
% ---------------------------------------------------------------

incorrectIndices = find(~correctPredictionMask);

if isempty(incorrectIndices)

    fprintf('No incorrect predictions were detected.\n\n');

else

    numberOfIncorrectExamples = min(10, numel(incorrectIndices));

    selectedIncorrectIndices = ...
        incorrectIndices(1:numberOfIncorrectExamples);

    incorrectPredictionTable = ...
        predictionResultsTable(selectedIncorrectIndices, :);

    fprintf('Example incorrect predictions\n');
    fprintf('-----------------------------\n');

    disp(incorrectPredictionTable);
end


%% ---------------------------------------------------------------
% Project completion
% ---------------------------------------------------------------

fprintf('====================================================\n');
fprintf('        PROJECT COMPLETED SUCCESSFULLY\n');
fprintf('====================================================\n');

fprintf('Generated output files are available in:\n');
fprintf('  %s\n\n', outputFolder);

fprintf('Generated files:\n');
fprintf('  1. %s\n', datasetFile);
fprintf('  2. %s\n', trainingFile);
fprintf('  3. %s\n', testingFile);
fprintf('  4. %s\n', modelFile);
fprintf('  5. %s\n', summaryFile);
fprintf('  6. %s\n', metricsFile);
fprintf('  7. %s\n', predictionFile);