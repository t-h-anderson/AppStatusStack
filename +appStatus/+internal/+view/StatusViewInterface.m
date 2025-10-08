classdef (Abstract) StatusViewInterface < matlab.mixin.SetGet
    %StatusVIEWINTERFACE View a status Stack

    properties (Abstract, SetAccess = protected)
        StatusStack appStatus.internal.stack.StatusStackInterface
        StatusStackListener event.listener
    end

    properties (SetAccess = protected)
        IncomingStatus (1,1) appStatus.Status = appStatus.Status
        PreviousStatus (1,1) appStatus.Status = appStatus.Status
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
                obj (1,1)
            end

            if ~obj.isVisible()
                return
            end

            stack = obj.StatusStack;

            %Get the latest Condition
            latestStatus = stack.CurrentStatus;
            latestCondition = latestStatus.Condition;

            % Save the status in case this is needed for a view
            obj.PreviousStatus = obj.IncomingStatus;
            obj.IncomingStatus = latestStatus;

            obj.beforeDisplay();

            % Display a pop-up
            switch latestCondition
                case appStatus.Condition.Running
                    obj.displayRunning_(latestStatus, false);
                case appStatus.Condition.RunningCancellable
                    obj.displayRunning_(latestStatus, true);
                case appStatus.Condition.Error
                    obj.displayError_(latestStatus);
                case appStatus.Condition.Warning
                    obj.displayWarning_(latestStatus);
                case appStatus.Condition.Success
                    obj.displaySuccess_(latestStatus);
                case appStatus.Condition.Idle
                    obj.displayIdle_(latestStatus);
                otherwise
                    error("Unknow Condition");
            end % switch

            

        end % standardDisplay

        function setStack(obj, stack)

            updateStatusFn = @(src, event)obj.standardDisplay();
            obj.StatusStack = stack;
            obj.StatusStackListener = listener(stack, "StatusUpdated", updateStatusFn);
            
        end

    end

    methods (Access = protected)
        function displayRunning_(obj, status, cancellable)
            if obj.ShowRunning
                obj.displayRunning(status, cancellable);
            end
        end

        function displayError_(obj, status)
            if obj.ShowErrors
                obj.displayError(status);
            end
        end

        function displayWarning_(obj, status)
            if obj.ShowWarnings
                obj.displayWarning(status);
            end
        end

        function displaySuccess_(obj, status)
            if obj.ShowSuccess
                obj.displaySuccess(status);
            end
        end

        function displayIdle_(obj, status)
            if obj.ShowIdle
                obj.displayIdle(status);
            end
        end

        function beforeDisplay(obj)
            % Overload to do something before each display trigger
        end

    end

    methods (Abstract)

        tf = isVisible(obj)

    end

    methods (Abstract, Access = protected)

        displayRunning(obj, status, cancellable)

        displayError(obj, status)

        displayWarning(obj, status)

        displaySuccess(obj, status)

        displayIdle(obj, status)

    end

end % classdef

