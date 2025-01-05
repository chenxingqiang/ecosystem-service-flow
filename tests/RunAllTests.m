%% RunAllTests.m
% Main test script that runs all individual test scripts for the ecosystem
% service flow models

%% Setup
clear;
clc;

% Create output directory if it doesn't exist
if ~exist('output/test_results', 'dir')
    mkdir('output/test_results');
end

% Add source directory to path
addpath(genpath('../src'));

%% Run Tests
fprintf('Starting test suite execution...\n\n');

% Store test results
test_results = struct();

try
    %% Run Carbon Flow Test
    fprintf('Running Carbon Flow Model tests...\n');
    tic;
    run('TestCarbonFlow.m');
    test_results.carbon_flow.time = toc;
    test_results.carbon_flow.status = 'Passed';
    fprintf('Carbon Flow Model tests completed.\n\n');
catch ME
    test_results.carbon_flow.status = 'Failed';
    test_results.carbon_flow.error = ME.message;
    fprintf('Error in Carbon Flow Model tests: %s\n\n', ME.message);
end

try
    %% Run Flood Water Flow Test
    fprintf('Running Flood Water Flow Model tests...\n');
    tic;
    run('TestFloodWater.m');
    test_results.flood_water.time = toc;
    test_results.flood_water.status = 'Passed';
    fprintf('Flood Water Flow Model tests completed.\n\n');
catch ME
    test_results.flood_water.status = 'Failed';
    test_results.flood_water.error = ME.message;
    fprintf('Error in Flood Water Flow Model tests: %s\n\n', ME.message);
end

try
    %% Run Surface Water Flow Test
    fprintf('Running Surface Water Flow Model tests...\n');
    tic;
    run('TestSurfaceWater.m');
    test_results.surface_water.time = toc;
    test_results.surface_water.status = 'Passed';
    fprintf('Surface Water Flow Model tests completed.\n\n');
catch ME
    test_results.surface_water.status = 'Failed';
    test_results.surface_water.error = ME.message;
    fprintf('Error in Surface Water Flow Model tests: %s\n\n', ME.message);
end

try
    %% Run Sediment Transport Test
    fprintf('Running Sediment Transport Model tests...\n');
    tic;
    run('TestSedimentTransport.m');
    test_results.sediment_transport.time = toc;
    test_results.sediment_transport.status = 'Passed';
    fprintf('Sediment Transport Model tests completed.\n\n');
catch ME
    test_results.sediment_transport.status = 'Failed';
    test_results.sediment_transport.error = ME.message;
    fprintf('Error in Sediment Transport Model tests: %s\n\n', ME.message);
end

try
    %% Run Line of Sight Test
    fprintf('Running Line of Sight Model tests...\n');
    tic;
    run('TestLineOfSight.m');
    test_results.line_of_sight.time = toc;
    test_results.line_of_sight.status = 'Passed';
    fprintf('Line of Sight Model tests completed.\n\n');
catch ME
    test_results.line_of_sight.status = 'Failed';
    test_results.line_of_sight.error = ME.message;
    fprintf('Error in Line of Sight Model tests: %s\n\n', ME.message);
end

try
    %% Run Proximity Analysis Test
    fprintf('Running Proximity Analysis Model tests...\n');
    tic;
    run('TestProximityAnalysis.m');
    test_results.proximity_analysis.time = toc;
    test_results.proximity_analysis.status = 'Passed';
    fprintf('Proximity Analysis Model tests completed.\n\n');
catch ME
    test_results.proximity_analysis.status = 'Failed';
    test_results.proximity_analysis.error = ME.message;
    fprintf('Error in Proximity Analysis Model tests: %s\n\n', ME.message);
end

try
    %% Run Coastal Storm Protection Test
    fprintf('Running Coastal Storm Protection Model tests...\n');
    tic;
    run('TestCoastalStormProtection.m');
    test_results.coastal_protection.time = toc;
    test_results.coastal_protection.status = 'Passed';
    fprintf('Coastal Storm Protection Model tests completed.\n\n');
catch ME
    test_results.coastal_protection.status = 'Failed';
    test_results.coastal_protection.error = ME.message;
    fprintf('Error in Coastal Storm Protection Model tests: %s\n\n', ME.message);
end

try
    %% Run Subsistence Fisheries Test
    fprintf('Running Subsistence Fisheries Model tests...\n');
    tic;
    run('TestSubsistenceFisheries.m');
    test_results.subsistence_fisheries.time = toc;
    test_results.subsistence_fisheries.status = 'Passed';
    fprintf('Subsistence Fisheries Model tests completed.\n\n');
catch ME
    test_results.subsistence_fisheries.status = 'Failed';
    test_results.subsistence_fisheries.error = ME.message;
    fprintf('Error in Subsistence Fisheries Model tests: %s\n\n', ME.message);
end

%% Generate Test Summary
fprintf('Generating test summary...\n\n');

% Calculate overall statistics
total_time = 0;
passed_tests = 0;
failed_tests = 0;
model_names = fieldnames(test_results);

% Print summary table header
fprintf('Test Results Summary:\n');
fprintf('%-25s %-10s %-15s %s\n', 'Model', 'Status', 'Time (s)', 'Error Message');
fprintf('%-25s %-10s %-15s %s\n', repmat('-', 1, 25), repmat('-', 1, 10), ...
    repmat('-', 1, 15), repmat('-', 1, 40));

% Print results for each model
for i = 1:length(model_names)
    model = model_names{i};
    result = test_results.(model);
    
    % Update statistics
    if strcmp(result.status, 'Passed')
        passed_tests = passed_tests + 1;
        total_time = total_time + result.time;
        error_msg = '';
    else
        failed_tests = failed_tests + 1;
        error_msg = result.error;
    end
    
    % Format model name for display
    display_name = strrep(model, '_', ' ');
    display_name = [upper(display_name(1)) display_name(2:end)];
    
    % Print result row
    if strcmp(result.status, 'Passed')
        fprintf('%-25s %-10s %-15.3f %s\n', display_name, result.status, ...
            result.time, error_msg);
    else
        fprintf('%-25s %-10s %-15s %s\n', display_name, result.status, ...
            'N/A', error_msg);
    end
end

% Print summary footer
fprintf('%-25s %-10s %-15s %s\n', repmat('-', 1, 25), repmat('-', 1, 10), ...
    repmat('-', 1, 15), repmat('-', 1, 40));
fprintf('\nTest Suite Summary:\n');
fprintf('Total Tests: %d\n', length(model_names));
fprintf('Passed: %d\n', passed_tests);
fprintf('Failed: %d\n', failed_tests);
fprintf('Total Time: %.2f seconds\n', total_time);

% Save test results
save('output/test_results/test_suite_results.mat', 'test_results');

fprintf('\nTest suite execution completed.\n'); 