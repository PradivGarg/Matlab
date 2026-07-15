%% create_gitignore.m
% Creates a .gitignore file for the Full-Adder Fault Classifier project.

clear;
clc;

% Create the file in the folder containing this script.
scriptPath = mfilename('fullpath');

if isempty(scriptPath)
    projectFolder = pwd;
else
    projectFolder = fileparts(scriptPath);
end

gitignorePath = fullfile(projectFolder, '.gitignore');

gitignoreRules = {
    '# ============================================================'
    '# MATLAB Full-Adder Fault Classifier'
    '# ============================================================'
    ''
    '# MATLAB autosave and backup files'
    '*.asv'
    '*.m~'
    '*.autosave'
    ''
    '# Generated project output'
    'output/'
    'results/'
    'logs/'
    ''
    '# MATLAB code-generation folders'
    'codegen/'
    'slprj/'
    'sfun/'
    '*_grt_rtw/'
    '*_ert_rtw/'
    '*_rtw/'
    ''
    '# MATLAB generated and compiled/'
    '*_grt_rtw/'
    '*_ert_rtw files'
    '*.mex*'
    '*.slxc'
    '*.slx.r*'
    '*.mdl.r*'
    ''
    '# Temporary files and folders'
    'temp/'
    'tmp/'
    '*.tmp'
    '*.temp'
    ''
    '# Testing, coverage, and generated reports'
    'coverage/'
    'test-results/'
    'html/'
    'report/'
    ''
    '# Editor configuration'
    '.vscode/'
    '.idea/'
    ''
    '# Operating-system files'
    '.DS_Store'
    'Thumbs.db'
    'desktop.ini'
    ''
    '# Crash dump and diagnostic files'
    'matlab_crash_dump.*'
    'java.log.*'
    'hs_err_pid*'
    ''
};

fileID = fopen(gitignorePath, 'wt');

if fileID == -1
    error('Unable to create the file: %s', gitignorePath);
end

fileCleanup = onCleanup(@() fclose(fileID));

for ruleIndex = 1:numel(gitignoreRules)
    fprintf(fileID, '%s\n', gitignoreRules{ruleIndex});
end

fprintf('\n.gitignore created successfully:\n%s\n', gitignorePath);