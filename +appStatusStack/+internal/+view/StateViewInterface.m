classdef (Abstract) StateViewInterface < matlab.mixin.SetGet
    %STATEVIEWINTERFACE View a status Stack

    properties (Abstract, SetAccess = protected)
        StatusStack appStatusStack.internal.stack.StatusStackInterface
        StatusStackListener event.listener
    end

    properties
        ShowWarnings (1,1) logical = true
        ShowErrors (1,1) logical = true
        ShowRunning (1,1) logical = true
        ShowSuccess (1,1) logical = true
        ShowIdle (1,1) logical = false
    end

    methods

        function standardDisplay(obj)
            % Method for displaying the status supplied to the Stack manager
            arguments
                obj
            end

            if ~obj.isVisible()
                return
            end

            stack = obj.StatusStack;

            %Get the latest state
            latestStatus = stack.Statuses(end);
            latestState = latestStatus.State;

            % Display a pop-up
            switch latestState
                case appStatusStack.State.Running
                    obj.displayRunning(latestStatus, stack);
                case appStatusStack.State.RunningCancellable
                    obj.displayRunning(latestStatus, stack, true);
                case appStatusStack.State.Error
                    obj.displayError(latestStatus, stack);
                case appStatusStack.State.Warning
                    obj.displayWarning(latestStatus, stack);
                case appStatusStack.State.Success
                    obj.displaySuccess(latestStatus, stack);
                case appStatusStack.State.Idle
                    obj.displayIdle(latestStatus, stack);
                otherwise
                    error("Unknow state");
            end % switch

        end % standardDisplay

        function setStack(obj, stack)

            updateStatusFn = @(src, event)obj.standardDisplay();

            obj.StatusStack = stack;
            obj.StatusStackListener = listener(stack, "StatusUpdated", updateStatusFn);
            
        end

    end

    methods (Abstract)

        tf = isVisible(obj)

    end

    methods (Abstract, Access = protected)

        displayRunning(obj, status, stack, cancellable)

        displayError(obj, status, stack)

        displayWarning(obj, status, stack)

        displaySuccess(obj, status, stack)

        displayIdle(obj, status, stack)

    end

end % classdef

