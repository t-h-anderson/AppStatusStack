classdef CommandWindow < statusMgr.internal.view.StatusViewInterface
    %CommandWindow View a status Stack in the command window

    properties (SetAccess = protected)
        Stack = statusMgr.Stack.empty(1,0)
        StackListener
        RunningTimer timer
    end

    properties
        PreviousMessage (1,1) string = string(NaN)
    end

    methods

        function obj = CommandWindow(stack, nvp)
            arguments
                stack = statusMgr.Stack
                nvp.ShowInfo (1,1) logical = true
                nvp.ShowWarnings (1,1) logical = true
                nvp.ShowErrors (1,1) logical = true
                nvp.ShowRunning (1,1) logical = true
                nvp.ShowSuccess (1,1) logical = true
                nvp.ShowIdle (1,1) logical = false
            end

            % Set view parent and stack properties
            obj.setStack(stack);
            set(obj, nvp);
        end

        function tf = isVisible(~)
            tf = true;
        end

        function delete(obj)
            % Destructor - delete any running timers before destroying.
            obj.clearRunning();
        end

    end

    methods (Access = protected)
        function beforeDisplay(obj)
            obj.clearRunning();
        end

        function displayRunning(obj, status, ~)
            arguments
                obj (1,1) statusMgr.view.CommandWindow
                status (1,1) statusMgr.Status
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
                obj (1,1) statusMgr.view.CommandWindow
                status (1,1) statusMgr.Status
            end

            if ~isempty(status.Data) ...
                    && isa(status.Data, "MException")

                rep = string(status.Data.getReport);
                rep = strrep(rep, "\", "\\");
                obj.writeToTerminal(rep, 2);
            else
                message = "Error: " + status.Message;
                obj.writeToTerminal(message, 2);
            end
        end

        function displayWarning(obj, status)
            arguments
                obj (1,1) statusMgr.view.CommandWindow
                status (1,1) statusMgr.Status
            end
            warning(status.Identifier, "Warning: " + status.Message);
        end

        function displaySuccess(obj, status)
            arguments
                obj (1,1) statusMgr.view.CommandWindow
                status (1,1) statusMgr.Status
            end
            message = status.Message;
            obj.writeToTerminal(message);
        end

        function displayInfo(obj, status)
            arguments
                obj (1,1) statusMgr.view.CommandWindow
                status (1,1) statusMgr.Status
            end
            message = status.Message;
            obj.writeToTerminal(message);
        end

        function displayIdle(obj,status)
            arguments
                obj (1,1)
                status (1,1) statusMgr.Status
            end
            message = status.Message;
            obj.writeToTerminal(message);
        end

        function writeToTerminal(obj, message, id)
            arguments
                obj (1,1)
                message (1,1) string
                id (1,1) double {mustBeMember(id, [1,2])} = 1 % 1 for normal, 2 for error
            end
            if message ~= obj.PreviousMessage
                % Only display the message if it's different from the
                % previous one to avoid spamming
                fprintf(id, message + "\n");
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
