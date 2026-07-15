function [model, predictorNames] = train_classifier( ...
    trainingTable, modelFile)
%TRAIN_CLASSIFIER Train a decision-tree fault classifier.
%
% Inputs:
%   trainingTable - Labelled training-data table containing a Label column
%   modelFile     - Optional MAT-file output path
%
% Outputs:
%   model          - Trained classification tree
%   predictorNames - Predictor-column names

    arguments
        trainingTable table
        modelFile {mustBeTextScalar} = ""
    end

    if exist("fitctree", "file") ~= 2
        error( ...
            "train_classifier:MissingToolbox", ...
            ["fitctree was not found. Install the Statistics " ...
             "and Machine Learning Toolbox."]);
    end

    if ~ismember("Label", string(trainingTable.Properties.VariableNames))
        error( ...
            "train_classifier:MissingLabel", ...
            "The training table must contain a column named Label.");
    end

    predictorNames = trainingTable.Properties.VariableNames;
    predictorNames(strcmp(predictorNames, "Label")) = [];

    if isempty(predictorNames)
        error( ...
            "train_classifier:NoPredictors", ...
            "The training table does not contain any predictor columns.");
    end

    predictors = trainingTable(:, predictorNames);
    labels = trainingTable.Label;

    model = fitctree( ...
        predictors, ...
        labels, ...
        "SplitCriterion", "gdi", ...
        "MinLeafSize", 5, ...
        "MaxNumSplits", 50, ...
        "Surrogate", "off");

    modelFile = string(modelFile);

    if strlength(modelFile) > 0
        modelFolder = string(fileparts(modelFile));

        % Do not call mkdir when modelFile contains only a filename.
        if strlength(modelFolder) > 0 && ~isfolder(modelFolder)
            mkdir(modelFolder);
        end

        if iscategorical(labels)
            faultClasses = categories(labels);
        else
            faultClasses = unique(string(labels));
        end

        save( ...
            modelFile, ...
            "model", ...
            "predictorNames", ...
            "faultClasses");
    end
end