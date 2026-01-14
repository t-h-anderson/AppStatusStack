classdef FileLog < statusMgr.internal.view.StatusViewInterface
    %FILELOG Print out statuses to file

    properties (SetAccess = protected)
        Stack = statusMgr.Stack.empty(1,0)
        StackListener
    end

    properties
        IncludeTimestamp (1,1) logical = true
        IncludeIdentifier (1,1) logical = true
        IncludeValue (1,1) logical = true
        LogFolder (1,1) string
        LogFilename (1,1) string
    end

    methods

        function obj = FileLog(stack, nvp)
            arguments
                stack = statusMgr.Stack
                nvp.IncludeTimestamp (1,1) logical
                nvp.IncludeIdentifier (1,1) logical
                nvp.IncludeValue (1,1) logical
                nvp.LogFolder (1,1) string {mustBeFolder} = pwd
                nvp.LogFilename (1,1) string = "Log_" + string(datetime("now", Format="yyyyMMdd_HHmmss")) + ".txt"
                nvp.ShowInfo (1,1) logical = true
                nvp.ShowWarnings (1,1) logical = true
                nvp.ShowErrors (1,1) logical = true
                nvp.ShowRunning (1,1) logical = true
                nvp.ShowSuccess (1,1) logical = true
                nvp.ShowIdle (1,1) logical = false
            end

            % Set view parent and stack properties
            obj.setStack(stack);

            % Add listener to stack
            standardDisplayFn = @(src, event)obj.standardDisplay();
            obj.StackListener = listener(obj.Stack, ...
                "StatusUpdated", standardDisplayFn);

            set(obj, nvp);

            logfile = fullfile(obj.LogFolder, obj.LogFilename);
            if isfile(logfile)
                writelines("", logfile, WriteMode="append"); % add a new line
            end

        end

        function tf = isVisible(~)
            tf = true;
        end

    end

    methods (Access = protected)
        function displayRunning(obj, status, ~)
            arguments
                obj (1,1) statusMgr.view.FileLog
                status (1,1) statusMgr.Status
                ~ % No cancellable option for a file log
            end
            obj.writeToFile(status);            
        end

        function displayError(obj, status)
            arguments
                obj (1,1) statusMgr.view.FileLog
                status (1,1) statusMgr.Status
            end

            obj.writeToFile(status);
        end

        function displayWarning(obj, status)
            arguments
                obj (1,1) statusMgr.view.FileLog
                status (1,1) statusMgr.Status
            end
            obj.writeToFile(status);
        end

        function displaySuccess(obj, status)
            arguments
                obj (1,1) statusMgr.view.FileLog
                status (1,1) statusMgr.Status
            end
            obj.writeToFile(status);
        end

        function displayInfo(obj, status)
            arguments
                obj (1,1) statusMgr.view.FileLog
                status (1,1) statusMgr.Status
            end
            obj.writeToFile(status);
        end

        function displayIdle(obj,status)
            arguments
                obj (1,1) statusMgr.view.FileLog
                status (1,1) statusMgr.Status
            end
            obj.writeToFile(status);
        end

        function writeToFile(obj, status)
            line = "";

            if obj.IncludeTimestamp
                ts = string(datetime(status.Timestamp, Format="dd-MMM-yyyy HH:mm:ss"));
                line = line + "[" + ts + "] ";
            end

            line = line + "[" + string(status.Type) + "] ";

            if obj.IncludeIdentifier
                if ~isempty(status.Identifier) && status.Identifier ~= ""
                    line = line + "[" + status.Identifier + "] ";
                end
            end

            if obj.IncludeValue
                if ~isempty(status.Value) && ~isnan(status.Value)
                    line = line + "[Value=" + status.Value + "] ";
                end
            end

            line = line + status.Message;

            writelines(line, fullfile(obj.LogFolder, obj.LogFilename), ...
                WriteMode="append");
        end

    end % methods

end % classdef