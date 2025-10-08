classdef CommandWindow < appStatus.internal.view.StatusViewInterface
    %CommandWindow View a status Stack in the command window

    properties (SetAccess = protected)
        StatusStack = appStatus.stack.StatusStack.empty(1,0)
        StatusStackListener
        RunningTimer timer
    end

    properties
        PreviousMessage (1,1) string = ""
    end

    methods

        function obj = CommandWindow(statusStack, nvp)
            arguments
                statusStack = appStatus.stack.StatusStack
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
            obj.StatusStackListener = listener(obj.StatusStack, ...
                "StatusUpdated", standardDisplayFn);

            set(obj, nvp);
        end

        function tf = isVisible(~)
            tf = true;
        end

    end

    methods (Access = protected)
        function beforeDisplay(obj)
            obj.clearRunning();
        end

        function displayRunning(obj, status, ~)
            arguments
                obj (1,1)
                status (1,1) appStatus.Status
                ~ % No cancellable option for the terminal
            end

            message = status.Message;
            obj.writeToTerminal(message);

            s = warning();
            warning("off");
            stopTimer(obj.RunningTimer);

            warning("off", "MATLAB:timer:deleterunning");
            obj.RunningTimer = timer("TimerFcn", @(~,~)obj.writeToTerminal(message), ...
                "Period", 1, "TasksToExecute", inf, "ExecutionMode", "fixedRate");
            
            start(obj.RunningTimer);
            warning(s)
            
        end % displayRunning

        function clearRunning(obj)
            stopTimer(obj.RunningTimer);
            obj.PreviousMessage = string(NaN);
        end

        function displayError(obj, status)
            arguments
                obj (1,1)
                status (1,1) appStatus.Status
            end

            if ~isempty(status.Data) ...
                    && isa(status.Data, "MException")...
                    && status.IsBlocking
                rethrow(status.Data);
                % Error ends here
            else
                message = "Error: " + status.Message;
                if status.IsBlocking
                    error(message)
                end
                obj.writeToTerminal(message);
            end
        end

        function displayWarning(obj, status)
            arguments
                obj (1,1)
                status (1,1) appStatus.Status
            end
            warning("Warning: " + status.Message);
        end

        function displaySuccess(obj, status)
            arguments
                obj (1,1)
                status (1,1) appStatus.Status
            end
            message = status.Message;
            obj.writeToTerminal(message);
        end

        function displayIdle(obj,status)
            arguments
                obj (1,1)
                status (1,1) appStatus.Status
            end
            message = status.Message;
            obj.writeToTerminal(message);
        end

        function writeToTerminal(obj, message)
            if message ~= obj.PreviousMessage
                % Only display the message if it's different from the
                % previous one to avoid spamming
                disp(message)
            else
                % Otherwise print a dot for repeated messages to indicate 
                % a repeating message
                fprintf(".");
            end
            obj.PreviousMessage = message;
        end

    end % methods

end % classdef

function stopTimer(timer)

try
    stop(timer);
    delete(timer)
catch
end

end
