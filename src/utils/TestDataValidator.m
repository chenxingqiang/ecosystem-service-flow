classdef TestDataValidator
    % TestDataValidator Validates test data for ecosystem service flow models
    
    properties (Access = private)
        RequiredFields
        DataTypes
        DimensionRules
        ValueRanges
    end
    
    methods
        function obj = TestDataValidator()
            % Initialize validation rules
            obj.RequiredFields = {
                'grid_size', 'cell_width', 'cell_height', 'time_step', ...
                'dem', 'slope', 'aspect', 'land_use', 'vegetation_cover', ...
                'temperature', 'precipitation', 'wind_speed', 'wind_direction', ...
                'soil_type', 'soil_depth', 'water_depth', 'bathymetry', ...
                'carbon_storage', 'fish_population', 'marine_habitat', ...
                'road_network', 'barriers', 'observation_points'
            };
            
            % Define expected data types
            obj.DataTypes = containers.Map();
            obj.DataTypes('grid_size') = 'double';
            obj.DataTypes('cell_width') = 'double';
            obj.DataTypes('cell_height') = 'double';
            obj.DataTypes('time_step') = 'double';
            obj.DataTypes('dem') = 'double';
            obj.DataTypes('land_use') = 'double';
            obj.DataTypes('vegetation_cover') = 'double';
            
            % Define dimension rules
            obj.DimensionRules = containers.Map();
            % Scalar fields
            obj.DimensionRules('grid_size') = [1 1];
            obj.DimensionRules('cell_width') = [1 1];
            obj.DimensionRules('cell_height') = [1 1];
            obj.DimensionRules('time_step') = [1 1];
            
            % Define value ranges
            obj.ValueRanges = containers.Map();
            obj.ValueRanges('vegetation_cover') = [0 1];
            obj.ValueRanges('soil_depth') = [0 Inf];
            obj.ValueRanges('water_depth') = [0 Inf];
            obj.ValueRanges('marine_habitat') = [0 1];
        end
        
        function [isValid, errors] = validate(obj, data)
            % Validate test data structure
            isValid = true;
            errors = {};
            
            % Check required fields
            for i = 1:length(obj.RequiredFields)
                field = obj.RequiredFields{i};
                if ~isfield(data, field)
                    isValid = false;
                    errors{end+1} = sprintf('Missing required field: %s', field);
                end
            end
            
            % Check data types
            fields = keys(obj.DataTypes);
            for i = 1:length(fields)
                field = fields{i};
                if isfield(data, field)
                    expected_type = obj.DataTypes(field);
                    actual_type = class(data.(field));
                    if ~strcmp(actual_type, expected_type)
                        isValid = false;
                        errors{end+1} = sprintf('Invalid data type for %s: expected %s, got %s', ...
                            field, expected_type, actual_type);
                    end
                end
            end
            
            % Check dimensions
            fields = keys(obj.DimensionRules);
            for i = 1:length(fields)
                field = fields{i};
                if isfield(data, field)
                    expected_dims = obj.DimensionRules(field);
                    actual_dims = size(data.(field));
                    if ~isequal(actual_dims, expected_dims) && ...
                            ~(length(expected_dims) == 1 && all(actual_dims == data.grid_size))
                        isValid = false;
                        errors{end+1} = sprintf('Invalid dimensions for %s: expected %s, got %s', ...
                            field, mat2str(expected_dims), mat2str(actual_dims));
                    end
                end
            end
            
            % Check value ranges
            fields = keys(obj.ValueRanges);
            for i = 1:length(fields)
                field = fields{i};
                if isfield(data, field)
                    range = obj.ValueRanges(field);
                    values = data.(field);
                    if any(values(:) < range(1)) || any(values(:) > range(2))
                        isValid = false;
                        errors{end+1} = sprintf('Values out of range for %s: should be between %g and %g', ...
                            field, range(1), range(2));
                    end
                end
            end
            
            % Check grid consistency
            grid_fields = {'dem', 'slope', 'aspect', 'land_use', 'vegetation_cover'};
            for i = 1:length(grid_fields)
                field = grid_fields{i};
                if isfield(data, field)
                    if ~isequal(size(data.(field)), [data.grid_size data.grid_size])
                        isValid = false;
                        errors{end+1} = sprintf('Inconsistent grid size for %s', field);
                    end
                end
            end
        end
        
        function data = preprocess(obj, data)
            % Preprocess data to ensure consistency
            
            % Ensure non-negative elevations
            if isfield(data, 'dem')
                data.dem = data.dem - min(data.dem(:));
            end
            
            % Clip vegetation cover to [0,1]
            if isfield(data, 'vegetation_cover')
                data.vegetation_cover = max(0, min(1, data.vegetation_cover));
            end
            
            % Ensure positive depths
            if isfield(data, 'water_depth')
                data.water_depth = max(0, data.water_depth);
            end
            
            % Convert any single precision to double
            fields = fieldnames(data);
            for i = 1:length(fields)
                field = fields{i};
                if isa(data.(field), 'single')
                    data.(field) = double(data.(field));
                end
            end
            
            % Ensure consistent grid dimensions
            grid_fields = {'dem', 'slope', 'aspect', 'land_use', 'vegetation_cover'};
            for i = 1:length(grid_fields)
                field = grid_fields{i};
                if isfield(data, field) && ~isequal(size(data.(field)), [data.grid_size data.grid_size])
                    data.(field) = imresize(data.(field), [data.grid_size data.grid_size]);
                end
            end
        end
    end
end 