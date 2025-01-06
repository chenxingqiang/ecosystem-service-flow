classdef ServiceFlowAnalyzerTest < matlab.unittest.TestCase
    % ServiceFlowAnalyzerTest 测试ServiceFlowAnalyzer类的功能
    
    properties (Access = private)
        Analyzer
    end
    
    methods (TestMethodSetup)
        function createAnalyzer(testCase)
            testCase.Analyzer = ServiceFlowAnalyzer();
        end
    end
    
    methods (Test)
        function testInitialization(testCase)
            % 测试初始化状态
            testCase.verifyEmpty(testCase.Analyzer.getData('supply'), '供给数据应该为空');
            testCase.verifyEmpty(testCase.Analyzer.getData('demand'), '需求数据应该为空');
            testCase.verifyEmpty(testCase.Analyzer.getData('resistance'), '阻力数据应该为空');
            testCase.verifyEmpty(testCase.Analyzer.getData('flow'), '流动数据应该为空');
            testCase.verifyEmpty(testCase.Analyzer.getData('spatial'), '空间数据应该为空');
            
            % 验证默认参数值
            params = testCase.Analyzer.getParameters();
            testCase.verifyEqual(params.alpha, 0.5, '供给衰减系数应为0.5');
            testCase.verifyEqual(params.beta, 0.5, '需求衰减系数应为0.5');
            testCase.verifyEqual(params.gamma, 1.0, '阻力影响系数应为1.0');
            testCase.verifyEqual(params.max_distance, 100, '最大流动距离应为100');
        end
        
        function testDataSetting(testCase)
            % 测试数据设置功能
            testSupply = rand(10, 10);
            testDemand = rand(10, 10);
            testResistance = rand(10, 10);
            
            % 设置测试数据
            testCase.Analyzer.setData('supply', testSupply);
            testCase.Analyzer.setData('demand', testDemand);
            testCase.Analyzer.setData('resistance', testResistance);
            
            % 验证数据是否正确设置
            testCase.verifyEqual(testCase.Analyzer.getData('supply'), testSupply, '供给数据设置错误');
            testCase.verifyEqual(testCase.Analyzer.getData('demand'), testDemand, '需求数据设置错误');
            testCase.verifyEqual(testCase.Analyzer.getData('resistance'), testResistance, '阻力数据设置错误');
        end
        
        function testParameterSetting(testCase)
            % 测试参数设置功能
            newAlpha = 0.7;
            newBeta = 0.8;
            newGamma = 1.2;
            newMaxDistance = 150;
            
            % 设置新参数
            testCase.Analyzer.setParameters('alpha', newAlpha);
            testCase.Analyzer.setParameters('beta', newBeta);
            testCase.Analyzer.setParameters('gamma', newGamma);
            testCase.Analyzer.setParameters('max_distance', newMaxDistance);
            
            % 验证参数是否正确设置
            params = testCase.Analyzer.getParameters();
            testCase.verifyEqual(params.alpha, newAlpha, '供给衰减系数设置错误');
            testCase.verifyEqual(params.beta, newBeta, '需求衰减系数设置错误');
            testCase.verifyEqual(params.gamma, newGamma, '阻力影响系数设置错误');
            testCase.verifyEqual(params.max_distance, newMaxDistance, '最大流动距离设置错误');
        end
    end
end
