%% RunAllTests.m
% Main test script that runs all individual test scripts for the ecosystem
% service flow models and generates a comprehensive test report

%% Setup
clear;
clc;

% Create output directory if it doesn't exist
if ~exist('output/test_results', 'dir')
    mkdir('output/test_results');
end

% Add source directory to path
addpath(genpath('../src'));

%% Initialize Test Suite
import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;
import matlab.unittest.plugins.TestReportPlugin;
import matlab.unittest.plugins.CodeCoveragePlugin;
import matlab.unittest.plugins.codecoverage.CoverageReport;

% Create test runner
runner = TestRunner.withTextOutput('Verbosity', 3);

% Add HTML report plugin
report_dir = 'output/test_results/report';
if ~exist(report_dir, 'dir')
    mkdir(report_dir);
end
runner.addPlugin(TestReportPlugin.producingHTML(report_dir));

%% Run Unit Tests
fprintf('\nRunning unit tests...\n');

% Create test suite from all test files
suite = TestSuite.fromFolder('.');
results = runner.run(suite);

%% Run Integration Tests
fprintf('\nRunning integration tests...\n');

try
    %% Test Service Flow Analyzer
    fprintf('Testing Service Flow Analyzer...\n');
    run('TestServiceFlowAnalyzer.m');
    fprintf('Service Flow Analyzer tests completed.\n\n');
catch ME
    fprintf('Error in Service Flow Analyzer tests: %s\n\n', ME.message);
end

try
    %% Test Carbon Flow Model
    fprintf('Testing Carbon Flow Model...\n');
    run('TestCarbonFlow.m');
    fprintf('Carbon Flow Model tests completed.\n\n');
catch ME
    fprintf('Error in Carbon Flow Model tests: %s\n\n', ME.message);
end

try
    %% Test Flood Water Model
    fprintf('Testing Flood Water Model...\n');
    run('TestFloodWater.m');
    fprintf('Flood Water Model tests completed.\n\n');
catch ME
    fprintf('Error in Flood Water Model tests: %s\n\n', ME.message);
end

try
    %% Test Surface Water Model
    fprintf('Testing Surface Water Model...\n');
    run('TestSurfaceWater.m');
    fprintf('Surface Water Model tests completed.\n\n');
catch ME
    fprintf('Error in Surface Water Model tests: %s\n\n', ME.message);
end

try
    %% Test Sediment Transport Model
    fprintf('Testing Sediment Transport Model...\n');
    run('TestSedimentTransport.m');
    fprintf('Sediment Transport Model tests completed.\n\n');
catch ME
    fprintf('Error in Sediment Transport Model tests: %s\n\n', ME.message);
end

try
    %% Test Line of Sight Model
    fprintf('Testing Line of Sight Model...\n');
    run('TestLineOfSight.m');
    fprintf('Line of Sight Model tests completed.\n\n');
catch ME
    fprintf('Error in Line of Sight Model tests: %s\n\n', ME.message);
end

try
    %% Test Proximity Analysis Model
    fprintf('Testing Proximity Analysis Model...\n');
    run('TestProximityAnalysis.m');
    fprintf('Proximity Analysis Model tests completed.\n\n');
catch ME
    fprintf('Error in Proximity Analysis Model tests: %s\n\n', ME.message);
end

try
    %% Test Coastal Storm Protection Model
    fprintf('Testing Coastal Storm Protection Model...\n');
    run('TestCoastalStormProtection.m');
    fprintf('Coastal Storm Protection Model tests completed.\n\n');
catch ME
    fprintf('Error in Coastal Storm Protection Model tests: %s\n\n', ME.message);
end

try
    %% Test Subsistence Fisheries Model
    fprintf('Testing Subsistence Fisheries Model...\n');
    run('TestSubsistenceFisheries.m');
    fprintf('Subsistence Fisheries Model tests completed.\n\n');
catch ME
    fprintf('Error in Subsistence Fisheries Model tests: %s\n\n', ME.message);
end

%% Run SPAN Model Integration Tests
fprintf('Running SPAN model integration tests...\n');
try
    run('RunSpanModels.m');
    fprintf('SPAN model integration tests completed.\n\n');
catch ME
    fprintf('Error in SPAN model integration tests: %s\n\n', ME.message);
end

%% Generate Test Summary
fprintf('\nTest Summary:\n');
fprintf('-------------\n');
fprintf('Total Tests: %d\n', results.TestCount);
fprintf('Passed: %d\n', results.Passed.Length);
fprintf('Failed: %d\n', results.Failed.Length);
fprintf('Incomplete: %d\n', results.Incomplete.Length);

if ~isempty(results.Failed)
    fprintf('\nFailed Tests:\n');
    for i = 1:results.Failed.Length
        fprintf('- %s: %s\n', results.Failed(i).Name, results.Failed(i).Exception.message);
    end
end

%% Save Test Results
save('output/test_results/test_results.mat', 'results');

%% Display Test Report Location
fprintf('\nDetailed test report available at: %s\n', fullfile(pwd, report_dir, 'index.html'));
% fprintf('Code coverage report available at: %s\n', fullfile(pwd, coverage_dir, 'index.html')); 