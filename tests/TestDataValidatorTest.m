classdef TestDataValidatorTest < matlab.unittest.TestCase
    % TestDataValidatorTest Tests for the TestDataValidator class
    
    properties
        Validator
        TestData
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.Validator = TestDataValidator();
            testCase.TestData = GenerateTestData();
        end
    end
    
    methods (Test)
        function testValidDataValidation(testCase)
            % Test validation of correctly formatted data
            [isValid, errors] = testCase.Validator.validate(testCase.TestData);
            testCase.verifyTrue(isValid, 'Valid data should pass validation');
            testCase.verifyEmpty(errors, 'No errors should be reported for valid data');
        end
        
        function testMissingFieldValidation(testCase)
            % Test validation when required field is missing
            invalid_data = testCase.TestData;
            invalid_data = rmfield(invalid_data, 'dem');
            [isValid, errors] = testCase.Validator.validate(invalid_data);
            testCase.verifyFalse(isValid, 'Missing field should fail validation');
            testCase.verifyTrue(any(contains(errors, 'Missing required field: dem')), ...
                'Error message should indicate missing field');
        end
        
        function testInvalidDataTypeValidation(testCase)
            % Test validation of incorrect data type
            invalid_data = testCase.TestData;
            invalid_data.grid_size = single(50);  % Should be double
            [isValid, errors] = testCase.Validator.validate(invalid_data);
            testCase.verifyFalse(isValid, 'Invalid data type should fail validation');
            testCase.verifyTrue(any(contains(errors, 'Invalid data type for grid_size')), ...
                'Error message should indicate invalid data type');
        end
        
        function testInvalidDimensionsValidation(testCase)
            % Test validation of incorrect dimensions
            invalid_data = testCase.TestData;
            invalid_data.dem = ones(30, 40);  % Should be grid_size x grid_size
            [isValid, errors] = testCase.Validator.validate(invalid_data);
            testCase.verifyFalse(isValid, 'Invalid dimensions should fail validation');
            testCase.verifyTrue(any(contains(errors, 'Inconsistent grid size for dem')), ...
                'Error message should indicate inconsistent dimensions');
        end
        
        function testValueRangeValidation(testCase)
            % Test validation of values outside allowed range
            invalid_data = testCase.TestData;
            invalid_data.vegetation_cover(1,1) = 1.5;  % Should be between 0 and 1
            [isValid, errors] = testCase.Validator.validate(invalid_data);
            testCase.verifyFalse(isValid, 'Out of range values should fail validation');
            testCase.verifyTrue(any(contains(errors, 'Values out of range for vegetation_cover')), ...
                'Error message should indicate out of range values');
        end
        
        function testPreprocessing(testCase)
            % Test data preprocessing
            test_data = testCase.TestData;
            
            % Modify data to need preprocessing
            test_data.dem = test_data.dem - 100;  % Create negative elevations
            test_data.vegetation_cover(1,1) = 1.5;  % Out of range
            test_data.water_depth(1,1) = -1;  % Negative depth
            
            % Preprocess data
            processed_data = testCase.Validator.preprocess(test_data);
            
            % Verify preprocessing results
            testCase.verifyGreaterThanOrEqual(min(processed_data.dem(:)), 0, ...
                'DEM should be non-negative after preprocessing');
            testCase.verifyLessThanOrEqual(max(processed_data.vegetation_cover(:)), 1, ...
                'Vegetation cover should be <= 1 after preprocessing');
            testCase.verifyGreaterThanOrEqual(min(processed_data.water_depth(:)), 0, ...
                'Water depth should be non-negative after preprocessing');
        end
        
        function testGridConsistency(testCase)
            % Test grid size consistency validation
            invalid_data = testCase.TestData;
            invalid_data.dem = ones(invalid_data.grid_size + 1);  % Inconsistent size
            [isValid, errors] = testCase.Validator.validate(invalid_data);
            testCase.verifyFalse(isValid, 'Inconsistent grid size should fail validation');
            testCase.verifyTrue(any(contains(errors, 'Inconsistent grid size')), ...
                'Error message should indicate inconsistent grid size');
        end
    end
end 