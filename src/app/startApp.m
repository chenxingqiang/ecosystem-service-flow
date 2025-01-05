% startApp.m
% 启动生态系统服务流分析系统

function startApp()
    % Start the Yellow River ESF Analysis App
    
    % Add required paths
    addpath(genpath('../src'));
    
    % Create and start the app
    app = YellowRiverESFApp();
end 