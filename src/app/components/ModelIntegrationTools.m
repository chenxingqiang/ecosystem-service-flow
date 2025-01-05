classdef ModelIntegrationTools < YellowRiverAnalyzer
    properties (Access = private)
        % Integration components
        ModelCoupler       ModelCoupler
        DataFusion        DataFusion
        ValidationTools   ValidationTools
        ExportManager     ExportManager
    end
    
    methods
        function obj = ModelIntegrationTools(parent)
            obj@YellowRiverAnalyzer(parent);
            obj.initializeIntegrationTools();
        end
        
        function results = runIntegratedAnalysis(obj, data, parameters)
            % Run integrated analysis across all models
            try
                % Prepare data
                integrated_data = obj.DataFusion.fuseData(data);
                
                % Run models
                results.fisheries = obj.runFisheriesModel(integrated_data);
                results.flood = obj.runFloodModel(integrated_data);
                results.visibility = obj.runVisibilityModel(integrated_data);
                
                % Validate results
                obj.ValidationTools.validateResults(results);
                
                % Generate reports
                obj.generateIntegratedReports(results);
                
            catch e
                uialert(obj.MainFigure, e.message, '集成分析错误');
            end
        end
        
        function exportResults(obj, results, format)
            % Export integrated results
            try
                % Prepare export data
                export_data = obj.prepareExportData(results);
                
                % Export in specified format
                obj.ExportManager.exportData(export_data, format);
                
            catch e
                uialert(obj.MainFigure, e.message, '导出错误');
            end
        end
        
        function validateIntegration(obj, results)
            % Validate integration results
            try
                % Run validation checks
                validation = obj.ValidationTools.runValidation(results);
                
                % Generate validation report
                report = obj.ValidationTools.generateReport(validation);
                
                % Display results
                obj.displayValidationResults(report);
                
            catch e
                uialert(obj.MainFigure, e.message, '验证错误');
            end
        end
    end
    
    methods (Access = private)
        function initializeIntegrationTools(obj)
            % Initialize integration tools
            obj.ModelCoupler = ModelCoupler();
            obj.DataFusion = DataFusion();
            obj.ValidationTools = ValidationTools();
            obj.ExportManager = ExportManager();
        end
        
        function data = prepareExportData(obj, results)
            % Prepare data for export
            data = obj.ExportManager.prepareData(results);
            obj.validateExportData(data);
        end
    end
end 