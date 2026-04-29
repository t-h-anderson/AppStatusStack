classdef (Abstract) StatusViewInterface < matlab.mixin.SetGet
    %StatusVIEWINTERFACE View a status Stack

    properties (Abstract, SetAccess = protected)
        Stack statusMgr.internal.StackInterface
        StackListener event.listener
    end

    properties (SetAccess = protected)
        IncomingStatus (1,1) statusMgr.Status = statusMgr.Status
        PreviousStatus (1,1) statusMgr.Status = statusMgr.Status
    end

    properties
        ShowInfo (1,1) logical = true
        ShowWarnings (1,1) logical = true
        ShowErrors (1,1) logical = true
        ShowRunning (1,1) logical = true
        ShowSuccess (1,1) logical = true
        ShowIdle (1,1) logical = false
        HandleInputRequests (1,1) logical = true
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

            stack = obj.Stack;

            %Get the latest status
            latestStatus = stack.CurrentStatus;

            if ~latestStatus.IsVisible
                return
            end

            latestType = latestStatus.Type;

            % Save the status in case this is needed for a view
            obj.PreviousStatus = obj.IncomingStatus;
            obj.IncomingStatus = latestStatus;

            obj.beforeDisplay();

            % Display a pop-up
            switch latestType
                case statusMgr.StatusType.Info
                    obj.displayInfo_(latestStatus);
                case statusMgr.StatusType.Running
                    obj.displayRunning_(latestStatus, false);
                case statusMgr.StatusType.RunningCancellable
                    obj.displayRunning_(latestStatus, true);
                case statusMgr.StatusType.Error
                    obj.displayError_(latestStatus);
                case statusMgr.StatusType.Warning
                    obj.displayWarning_(latestStatus);
                case statusMgr.StatusType.Success
                    obj.displaySuccess_(latestStatus);
                case statusMgr.StatusType.Idle
                    obj.displayIdle_(latestStatus);
                case statusMgr.StatusType.RequestingInput
                    obj.handleInputRequest_(latestStatus);
                case {statusMgr.StatusType.AwaitingInput, statusMgr.StatusType.ValueSupplied}
                    % Intermediate input states — no display action needed.
                otherwise
                    error("Unknow status type");
            end % switch

            

        end % standardDisplay

        function setStack(obj, stack)

            updateStatusFn = @(src, event)obj.standardDisplay();
            obj.Stack = stack;
            obj.StackListener = listener(stack, "StatusUpdated", updateStatusFn);
            
        end

    end

    methods (Access = protected)
        function displayInfo_(obj, status)
            if obj.ShowInfo
                obj.displayInfo(status);
            end
        end

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

        function handleInputRequest_(obj, status)
            if obj.HandleInputRequests
                obj.handleInputRequest(status);
            end
        end

    end

    methods (Abstract)

        tf = isVisible(obj)

    end

    methods (Abstract, Access = protected)

        displayInfo(obj, status)

        displayRunning(obj, status, cancellable)

        displayError(obj, status)

        displayWarning(obj, status)

        displaySuccess(obj, status)

        displayIdle(obj, status)

        % Called when a RequestingInput status is seen and HandleInputRequests
        % is true. Claim the request by calling status.transitionInputState
        % (AwaitingInput), collect input, then call transitionInputState
        % (ValueSupplied, value). Do nothing (no claim) to let it time out.
        handleInputRequest(obj, status)

    end

end % classdef

