classdef StateViewCommandWindow < appStatusStack.internal.view.StateViewInterface
    %StateViewCommandWindow View a status Stack in the command window

    properties (SetAccess = protected)
        StatusStack = appStatusStack.stack.StatusStack.empty(1,0)
        StatusStackListener
    end

    properties
        PreviousMessage (1,1) string = ""
    end

    methods

        function obj = StateViewCommandWindow(statusStack, nvp)
            arguments
                statusStack = appStatusStack.stack.StatusStack
                nvp.ShowWarnings (1,1) logical = true
                nvp.ShowErrors (1,1) logical = true
                nvp.ShowRunning (1,1) logical = true
                nvp.ShowSuccess (1,1) logical = true
                nvp.ShowIdle (1,1) logical = false
            end

            % Set view parent and stack properties
            obj.setStack(statusStack);

            % Add listener to stack
            standardDisplayFn = @(src, event)obj.standardDisplay();
            obj.StatusStackListener = listener(obj.StatusStack, "StatusUpdated", standardDisplayFn);

            set(obj, nvp);
        end

        function tf = isVisible(~)
            tf = true;
        end


    end

    methods (Access = protected)
        function displayRunning(obj, status, ~, ~)
            arguments
                obj (1,1)
                status (1,1) appStatusStack.Status
                ~
                ~
            end

            if obj.ShowRunning
                message = status.Message;
                obj.writeToTerminal(message);
            end

            obj.StatusStack.removeStatus(status);

        end % displayRunning

        function displayError(obj, status, ~)
            arguments
                obj (1,1)
                status (1,1) appStatusStack.Status
                ~
            end

            if obj.ShowErrors
                if ~isempty(status.Data) && isa(status.Data, "MException")

                    err = status.Data;

                    % Remove test infrastructure
                    message = getReport(err, "extended");
                    message = string(message);
                    message = strsplit(message, newline);
                    idx = find(contains(message, "matlab.unittest"), 1);
                    message(idx:end) = [];
                    message = strjoin(message, newline);

                    disp(message);

                else
                    message = "Error: " + status.Message;
                end

                obj.writeToTerminal(message);
            end

            obj.StatusStack.removeStatus(status);

        end

        function displayWarning(obj, status, ~)
            arguments
                obj (1,1)
                status (1,1) appStatusStack.Status
                ~
            end

            if obj.ShowWarnings
                warning("Warning: " + status.Message);
            end

            obj.StatusStack.removeStatus(status);
        end

        function displaySuccess(obj, status, ~)
            arguments
                obj (1,1)
                status (1,1) appStatusStack.Status
                ~
            end

            if obj.ShowSuccess
                message = status.Message;
                obj.writeToTerminal(message);
            end

            obj.StatusStack.removeStatus(status);
        end

        function displayIdle(obj,status,~)
            arguments
                obj (1,1)
                status (1,1) appStatusStack.Status
                ~
            end

            if obj.ShowIdle
                message = status.Message;
                obj.writeToTerminal(message);
            end

            if numel(obj.StatusStack.Statuses) > 1
                obj.StatusStack.removeStatus(status);
            end

        end

        function writeToTerminal(obj, message)
            if message ~= obj.PreviousMessage
                disp(message)
            else
                fprintf(".");
            end

            obj.PreviousMessage = message;
        end

    end % methods

end % classdef

