# Ecosystem Service Flow Models

## Overview

This repository contains a collection of specialized models for analyzing ecosystem service flows using the SPAN (Service Path Attribution Networks) framework. The models are implemented in MATLAB and are designed to work together to provide comprehensive ecosystem service assessments.

## Models

### Core Models

1. **Service Flow Network**
   - Network structure analysis for ecosystem services
   - Flow path attribution
   - Centrality analysis
   - Network metrics calculation
   - [Documentation](docs/ServiceFlowNetwork.md)

2. **SPAN Model**
   - Base model for service flow analysis
   - Integration of specialized flow models
   - Service path calculation
   - Flow aggregation
   - [Documentation](docs/SpanModel.md)

### Specialized Flow Models

1. **Carbon Flow Model**
   - Carbon sequestration analysis
   - Carbon storage assessment
   - Fixation efficiency calculation
   - [Documentation](docs/CarbonFlowModel.md)

2. **Flood Water Flow Model**
   - Flood propagation simulation
   - Inundation mapping
   - Flow accumulation
   - [Documentation](docs/FloodWaterFlowModel.md)

3. **Surface Water Flow Model**
   - Surface runoff analysis
   - Flow direction calculation
   - Water accumulation
   - [Documentation](docs/SurfaceWaterFlowModel.md)

4. **Sediment Transport Model**
   - Sediment movement analysis
   - Erosion and deposition
   - Transport capacity
   - [Documentation](docs/SedimentTransportModel.md)

5. **Line of Sight Model**
   - Visibility analysis
   - Viewshed calculation
   - Observer-target relationships
   - [Documentation](docs/LineOfSightModel.md)

6. **Proximity Analysis Model**
   - Spatial accessibility assessment
   - Cost distance calculation
   - Service area delineation
   - [Documentation](docs/ProximityAnalysisModel.md)

7. **Coastal Storm Protection Model**
   - Storm surge protection
   - Coastal vulnerability assessment
   - Protection effectiveness
   - [Documentation](docs/CoastalStormProtectionModel.md)

8. **Subsistence Fisheries Model**
   - Fish population dynamics
   - Fishing effort analysis
   - Sustainability assessment
   - [Documentation](docs/SubsistenceFisheriesModel.md)

## Installation

1. Clone the repository:

```bash
git clone https://github.com/chenxingqiang/ecosystem-service-flow.git
```

2. Add the repository directory and all subdirectories to your MATLAB path:

```matlab
addpath(genpath('ecosystem-service-flow'));
```

3. Verify installation by running the test script:

```matlab
cd tests
RunSpanModels
```

## Dependencies

- MATLAB R2019b or later
- Mapping Toolbox
- Statistics and Machine Learning Toolbox
- Image Processing Toolbox
- Parallel Computing Toolbox (optional, for improved performance)

## Usage

### Basic Usage

```matlab
% Initialize SPAN model
model = SpanModel();

% Load your data
source_data = load('source_data.mat');
sink_data = load('sink_data.mat');
flow_data = load('flow_data.mat');

% Run the model
results = model.runModel(source_data, sink_data, flow_data);

% Visualize results
model.visualizeResults(results);
```

### Using Specialized Models

```matlab
% Example with Carbon Flow Model
carbon_model = CarbonFlowModel(vegetation_data, climate_data, soil_data);
carbon_results = carbon_model.calculateFlow();

% Example with Flood Water Model
flood_model = FloodWaterFlowModel(dem_data, precipitation_data, landuse_data);
flood_results = flood_model.simulateFloodPropagation();
```

## Testing

Run the comprehensive test suite:
```matlab
cd tests
RunSpanModels
```

Individual model tests:
```matlab
TestCarbonFlow
TestFloodWater
TestSurfaceWater
% etc...
```

## Documentation

Each model has detailed documentation in the `docs` directory:

- Model overview
- Class structure
- Methods and parameters
- Example usage
- Implementation details
- Limitations and future improvements

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use these models in your research, please cite:

```bibtex
@software{ecosystem_service_flow,
  title = {Ecosystem Service Flow Models},
  author = {Your Name},
  year = {2024},
  url = {https://github.com/chenxingqiang/ecosystem-service-flow},
  version = {1.0.0}
}
```

## Contact

Your Name - your.email@example.com

Project Link: [https://github.com/chenxingqiang/ecosystem-service-flow](https://github.com/chenxingqiang/ecosystem-service-flow)

## Acknowledgments

- SPAN model framework developers
- Contributors to ecosystem service modeling
- MATLAB community for toolbox support
