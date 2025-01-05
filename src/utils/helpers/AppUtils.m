classdef AppUtils
    % AppUtils 应用工具类
    % 提供常用的辅助功能
    
    methods (Static)
        function success = checkDataFormat(data)
            % 检查数据格式是否有效
            try
                % TODO: 实现数据格式检查逻辑
                success = true;
            catch
                success = false;
            end
        end
        
        function data = preprocessData(raw_data)
            % 数据预处理
            % TODO: 实现数据预处理逻辑
            data = raw_data;
        end
        
        function saveToFile(data, filename)
            % 保存数据到文件
            try
                save(filename, 'data');
            catch e
                errordlg(['保存文件失败：' e.message], '错误');
            end
        end
        
        function data = loadFromFile(filename)
            % 从文件加载数据
            try
                loaded = load(filename);
                data = loaded.data;
            catch e
                errordlg(['加载文件失败：' e.message], '错误');
                data = [];
            end
        end
        
        function result = validateInput(input, type)
            % 验证输入数据
            switch type
                case 'numeric'
                    result = isnumeric(input);
                case 'string'
                    result = ischar(input) || isstring(input);
                case 'table'
                    result = istable(input);
                case 'matrix'
                    result = ismatrix(input);
                otherwise
                    result = false;
            end
        end
        
        function displayError(message)
            % 显示错误信息
            errordlg(message, '错误');
        end
        
        function displayWarning(message)
            % 显示警告信息
            warndlg(message, '警告');
        end
        
        function displayInfo(message)
            % 显示信息
            msgbox(message, '信息');
        end
    end
end 