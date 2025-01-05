# Coastal Storm Protection Model Documentation

## Overview

The `CoastalStormProtectionModel` is designed to evaluate coastal protection services against storms and flooding. It integrates multiple factors including terrain, vegetation, coastal structures, and storm characteristics to assess protection levels and inundation risks.

## Class Structure

```matlab
classdef CoastalStormProtectionModel < handle
    properties
        % Input data layers
        dem              % Digital Elevation Model
        bathymetry      % Bathymetry data
        landcover       % Land cover data
        coastal_type    % Coastal type data
        
        % Grid parameters
        cell_width      % Cell width (m)
        cell_height     % Cell height (m)
        
        % Storm parameters
        storm_intensity   % Storm intensity (1-5)
        storm_duration    % Storm duration (h)
        storm_surge      % Storm surge height (m)
        wave_height      % Wave height (m)
        wind_speed       % Wind speed (m/s)
        wind_direction   % Wind direction (degrees)
        
        % Protection parameters
        vegetation_factors    % Vegetation protection factors
        coastal_structures    % Coastal protection structures
        protection_threshold  % Protection threshold
    end
end
```

## Constructor

```matlab
model = CoastalStormProtectionModel(dem_data, bathymetry_data, landcover_data, ...
    coastal_type_data, ...
    'storm_intensity', 4, ...
    'storm_surge', 5, ...
    'wave_height', 8);
```

### Required Parameters
- `dem_data`: Digital Elevation Model (2D numeric matrix)
- `bathymetry_data`: Bathymetry data (2D numeric matrix)
- `landcover_data`: Land cover classification (2D numeric matrix)
- `coastal_type_data`: Coastal type classification (2D numeric matrix)

### Optional Parameters
- `cell_width`: Grid cell width in meters (default: 30)
- `cell_height`: Grid cell height in meters (default: 30)
- `storm_intensity`: Storm intensity on 1-5 scale (default: 3)
- `storm_duration`: Storm duration in hours (default: 24)
- `storm_surge`: Storm surge height in meters (default: 3)
- `wave_height`: Wave height in meters (default: 5)
- `wind_speed`: Wind speed in m/s (default: 30)
- `wind_direction`: Wind direction in degrees (default: 90)

## Main Methods

### Calculate Protection
```matlab
[protection_level, inundation_risk] = model.calculateProtection()
```

Calculates protection levels and inundation risks based on environmental and storm factors.

#### Returns
- `protection_level`: Protection level matrix [0,1]
- `inundation_risk`: Inundation risk matrix [0,1]

### Calculate Terrain Protection
```matlab
terrain_protection = model.calculateTerrainProtection()
```

Calculates protection provided by terrain features.

#### Returns
- `terrain_protection`: Terrain protection matrix [0,1]

### Calculate Vegetation Protection
```matlab
vegetation_protection = model.calculateVegetationProtection()
```

Calculates protection provided by vegetation.

#### Returns
- `vegetation_protection`: Vegetation protection matrix [0,1]

### Calculate Structure Protection
```matlab
structure_protection = model.calculateStructureProtection()
```

Calculates protection provided by coastal structures.

#### Returns
- `structure_protection`: Structure protection matrix [0,1]

### Calculate Service Flow
```matlab
service_flow = model.calculateServiceFlow(source_strength, sink_capacity, protection_level)
```

Calculates service flow based on protection levels and capacity constraints.

#### Parameters
- `source_strength`: Source strength matrix (protection elements)
- `sink_capacity`: Sink capacity matrix (protection demand)
- `protection_level`: Protection level matrix

#### Returns
- `service_flow`: Service flow matrix

## Protection Parameters

### Vegetation Protection Factors
- Mangrove: 0.8
- Seagrass: 0.6
- Salt marsh: 0.7
- Coral reef: 0.9
- Coastal forest: 0.5
- Dune vegetation: 0.4

### Coastal Structure Types
- Seawall: 0.9
- Breakwater: 0.8
- Groin: 0.6
- Revetment: 0.7

### Protection Threshold
- Default: 0.3 (minimum protection level for risk reduction)

## Risk Assessment Components

### Exposure Calculation
1. Distance from coastline
2. Elevation relative to storm surge
3. Wind exposure based on direction
4. Terrain slope and aspect

### Vulnerability Assessment
1. Land use type vulnerability
2. Slope influence
3. Protection level consideration
4. Risk reduction factors

## Visualization

```matlab
model.visualizeResults(protection_level, inundation_risk)
```

Generates four subplots:
1. Protection level
2. Inundation risk
3. Terrain and bathymetry
4. Land cover

## Example Usage

```matlab
% Create test data
grid_size = 50;
dem = 500 + 100 * peaks(grid_size);
bathymetry = zeros(grid_size);
landcover = ones(grid_size);
coastal_type = ones(grid_size);

% Create bathymetry gradient
for i = 1:grid_size
    if i > grid_size/2
        bathymetry(i,:) = dem(i,:);
    else
        bathymetry(i,:) = -20 + i/5;
    end
end

% Create and configure model
model = CoastalStormProtectionModel(dem, bathymetry, landcover, coastal_type, ...
    'storm_intensity', 4, ...
    'storm_surge', 5, ...
    'wave_height', 8, ...
    'wind_speed', 40, ...
    'wind_direction', 90);

% Calculate protection and risk
[protection_level, inundation_risk] = model.calculateProtection();

% Create source strength and sink capacity
source_strength = zeros(grid_size);
source_strength(landcover > 0) = 100;
sink_capacity = ones(grid_size) * 50;
sink_capacity(bathymetry >= 0) = 100;

% Calculate service flow
service_flow = model.calculateServiceFlow(source_strength, sink_capacity, protection_level);

% Visualize results
model.visualizeResults(protection_level, inundation_risk);
```

## Implementation Details

### Protection Level Calculation
1. Terrain protection:
   - Elevation relative to storm surge
   - Slope protection factor
   - Aspect relative to wind direction

2. Vegetation protection:
   - Vegetation type factors
   - Density consideration
   - Health status influence

3. Structure protection:
   - Structure type efficiency
   - Location effectiveness
   - Condition assessment

### Inundation Risk Calculation
1. Exposure assessment:
   - Coastal proximity
   - Elevation vulnerability
   - Wind exposure

2. Vulnerability calculation:
   - Land use sensitivity
   - Terrain influence
   - Protection level impact

3. Risk integration:
   - Combined exposure and vulnerability
   - Protection level modification
   - Threshold application

## Performance Considerations

1. Efficient matrix operations
2. Optimized distance calculations
3. Memory management for large grids
4. Parallel processing support

## Error Handling

The model includes:
- Input data validation
- Parameter range checking
- Coordinate system verification
- Meaningful error messages

## Limitations

1. Static storm parameters
2. Simplified wave dynamics
3. Basic structure interaction
4. Limited temporal resolution

## Future Improvements

1. Enhanced modeling:
   - Dynamic storm evolution
   - Wave-structure interaction
   - Sediment transport
   - Ecosystem dynamics

2. Advanced features:
   - Time-series analysis
   - Scenario modeling
   - Uncertainty assessment
   - Cost-benefit analysis

3. Visualization enhancements:
   - 3D visualization
   - Time-lapse animation
   - Interactive plotting
   - GIS integration 