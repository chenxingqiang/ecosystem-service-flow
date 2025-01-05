# Ecosystem Service Flow Models Test Suite

This directory contains test scripts for validating the functionality of various ecosystem service flow models implemented in the SPAN framework.

## Test Scripts

- `RunAllTests.m`: Main script to run all tests and generate a comprehensive test report
- `TestCarbonFlow.m`: Tests for the Carbon Flow Model
- `TestFloodWater.m`: Tests for the Flood Water Flow Model
- `TestSurfaceWater.m`: Tests for the Surface Water Flow Model
- `TestSedimentTransport.m`: Tests for the Sediment Transport Model
- `TestLineOfSight.m`: Tests for the Line of Sight Model
- `TestProximityAnalysis.m`: Tests for the Proximity Analysis Model
- `TestCoastalStormProtection.m`: Tests for the Coastal Storm Protection Model
- `TestSubsistenceFisheries.m`: Tests for the Subsistence Fisheries Model
- `RunSpanModels.m`: Integration tests for the SPAN model framework

## Running Tests

To run the complete test suite:

1. Open MATLAB
2. Navigate to the `tests` directory
3. Run `RunAllTests.m`

The script will:
- Execute all test scripts
- Generate test results and visualizations
- Create a detailed test report in HTML format
- Save test results in MAT format

## Test Output

Test results are saved in the `output/test_results` directory:
- `test_report.html`: HTML report with test results and statistics
- `test_suite_results.mat`: MATLAB data file containing test results
- Individual test results and visualizations for each model

## Test Coverage

Each test script validates:
- Model initialization and parameter validation
- Core calculations and algorithms
- Data flow and transformations
- Integration with the SPAN framework
- Performance metrics
- Result visualization

## Adding New Tests

To add tests for a new model:
1. Create a new test script following the existing pattern
2. Add the test execution to `RunAllTests.m`
3. Update this README to include the new test script

## Dependencies

- MATLAB R2019b or later
- Image Processing Toolbox
- Mapping Toolbox
- Statistics and Machine Learning Toolbox

## Troubleshooting

Common issues and solutions:
- Ensure all required toolboxes are installed
- Verify the source code directory is in the MATLAB path
- Check write permissions for the output directory
- Confirm input data availability and format

## Contact

For questions or issues, please contact the development team. 