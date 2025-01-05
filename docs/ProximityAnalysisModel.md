# Proximity Analysis Model Documentation

## Overview

The `ProximityAnalysisModel` is designed to analyze spatial accessibility and distance-based service flows in ecosystem service assessments. It considers multiple factors including terrain, land use, road networks, and barriers to calculate accessibility indices and service flows.

## Class Structure

```matlab
classdef ProximityAnalysisModel < handle
    properties
        % Input data layers
        dem              % Digital Elevation Model
        landuse         % Land use data
        road_network    % Road network data
        barriers        % Barriers data
        
        % Grid parameters
        cell_width      % Cell width (m)
        cell_height     % Cell height (m)
        
        % Accessibility parameters
        max_distance    % Maximum analysis distance (m)
        decay_function  % Distance decay function type
        decay_param     % Decay function parameter
        
        % Transport parameters
        travel_speeds   % Travel speeds for different road types
        impedance_factors % Impedance factors for different land use types
    end
end
```

## Constructor

```matlab
model = ProximityAnalysisModel(dem_data, landuse_data, road_data, barriers_data, ...
    'cell_width', 30, ...
    'cell_height', 30, ...
    'max_distance', 2000, ...
    'decay_function', 'exponential', ...
    'decay_param', 0.001);
```

### Required Parameters
- `dem_data`: Digital Elevation Model (2D numeric matrix)
- `landuse_data`: Land use classification (2D numeric matrix)
- `road_data`: Road network classification (2D numeric matrix)
- `barriers_data`: Barriers data (2D numeric matrix)

### Optional Parameters
- `cell_width`: Grid cell width in meters (default: 30)
- `cell_height`: Grid cell height in meters (default: 30)
- `max_distance`: Maximum analysis distance in meters (default: 5000)
- `decay_function`: Distance decay function type (default: 'exponential')
- `decay_param`: Decay function parameter (default: 0.001)

## Main Methods

### Calculate Accessibility
```matlab
[cost_surface, accessibility] = model.calculateAccessibility(source_points)
```

Calculates accessibility indices based on source points and environmental factors.

#### Parameters
- `source_points`: N×2 matrix of source point coordinates

#### Returns
- `cost_surface`: Accumulated cost surface matrix
- `accessibility`: Accessibility index matrix [0,1]

### Calculate Base Cost
```matlab
base_cost = model.calculateBaseCost()
```

Calculates the base cost surface considering terrain, land use, and road network.

#### Returns
- `base_cost`: Base cost matrix

### Calculate Cost Distance
```matlab
cost_distance = model.calculateCostDistance(start_x, start_y, base_cost)
```

Calculates cost distance using Dijkstra's algorithm.

#### Parameters
- `start_x`, `start_y`: Starting point coordinates
- `base_cost`: Base cost matrix

#### Returns
- `cost_distance`: Cost distance matrix

### Calculate Service Flow
```matlab
service_flow = model.calculateServiceFlow(source_strength, sink_capacity, accessibility)
```

Calculates service flow based on source strength, sink capacity, and accessibility.

#### Parameters
- `source_strength`: Source strength matrix
- `sink_capacity`: Sink capacity matrix
- `accessibility`: Accessibility index matrix

#### Returns
- `service_flow`: Service flow matrix

## Transport Parameters

### Travel Speeds (m/s)
- Highway: 30
- Primary road: 20
- Secondary road: 15
- Tertiary road: 10
- Path: 5
- Off-road: 1

### Impedance Factors
- Urban: 1.0
- Agriculture: 1.5
- Forest: 2.0
- Water: 5.0
- Wetland: 3.0
- Barren: 1.2

## Distance Decay Functions

The model supports four types of decay functions:

1. **Exponential Decay**
   ```matlab
   accessibility = exp(-decay_param * cost_surface)
   ```

2. **Linear Decay**
   ```matlab
   accessibility = max(0, 1 - decay_param * cost_surface)
   ```

3. **Power Decay**
   ```matlab
   accessibility = cost_surface.^(-decay_param)
   ```

4. **Gaussian Decay**
   ```matlab
   accessibility = exp(-(cost_surface.^2) * decay_param)
   ```

## Visualization

```matlab
model.visualizeResults(cost_surface, accessibility)
```

Generates four subplots:
1. Accumulated cost surface
2. Accessibility index
3. Road network
4. Land use

## Example Usage

```matlab
% Create test data
grid_size = 50;
dem = peaks(grid_size) * 100;
landuse = ones(grid_size);
road_network = zeros(grid_size);
barriers = zeros(grid_size);

% Create and configure model
model = ProximityAnalysisModel(dem, landuse, road_network, barriers, ...
    'cell_width', 30, ...
    'cell_height', 30, ...
    'max_distance', 2000);

% Define source points
source_points = [25 25; 40 40];

% Calculate accessibility
[cost_surface, accessibility] = model.calculateAccessibility(source_points);

% Create source strength and sink capacity
source_strength = zeros(grid_size);
source_strength(source_points(:,2), source_points(:,1)) = 100;
sink_capacity = ones(grid_size) * 50;

% Calculate service flow
service_flow = model.calculateServiceFlow(source_strength, sink_capacity, accessibility);

% Visualize results
model.visualizeResults(cost_surface, accessibility);
```

## Implementation Details

### Cost Surface Calculation
1. Calculates base cost considering:
   - Slope derived from DEM
   - Land use impedance factors
   - Road network travel speeds
   - Barriers (infinite cost)

2. Uses Dijkstra's algorithm for cost distance calculation
   - Implements priority queue for efficiency
   - Considers 8-neighborhood connectivity
   - Accounts for diagonal movement cost

### Accessibility Calculation
1. Applies selected decay function to cost surface
2. Normalizes accessibility values to [0,1] range
3. Sets inaccessible areas (cost = inf) to 0

### Service Flow Calculation
1. Calculates potential flow as product of source strength and accessibility
2. Applies sink capacity constraints
3. Returns final service flow matrix

## Performance Considerations

1. Uses efficient matrix operations where possible
2. Implements Dijkstra's algorithm with priority queue
3. Optimizes memory usage for large grids
4. Supports parallel processing for multiple source points

## Error Handling

The model includes input validation and error checking:
- Validates input data dimensions
- Checks parameter values and types
- Handles edge cases in calculations
- Provides informative error messages

## Limitations

1. Memory constraints for very large grids
2. Simplified treatment of complex terrain features
3. Basic implementation of transport modes
4. Limited consideration of temporal variations

## Future Improvements

1. Add support for:
   - Multiple transport modes
   - Temporal variations
   - Advanced decay functions
   - Complex barriers

2. Enhance performance:
   - Implement parallel processing
   - Optimize memory usage
   - Add sparse matrix support

3. Improve visualization:
   - Add interactive plots
   - Support custom colormaps
   - Include animation options 