clear;
clc;

projectroot = fileparts(mfilename("fullpath"));

modelFile = fullfile( ...
    projectRoot, ...
    "models", ...
    "full_adder_fault_tree.mat");

%Input Order:
%000, 001, 010, 011, 100, 101, 110, 111

%SUM_STUCK_0 produces only zeroes on Sum.
observedSum = [0 0 0 0 0 0 0 0];

%Carry remains correct
observedCount = [0 0 0 1 0 1 1 1];

result = classify_manual_signature( ...
    modelFile, ...
    observedSum, ...
    observedCount);

disp(result);