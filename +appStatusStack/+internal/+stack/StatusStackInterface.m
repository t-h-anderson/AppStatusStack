classdef (Abstract) StatusStackInterface < handle
    %STATUSStack
    % Use example:
    % statusStack = appStatusStack.stack.StatusStack();
    % [newStatus, cleanObj] = statusStack.addStatus(appStatusStack.State.Running, "Initialising");
    % updateStatusMessage(obj, status, message)

    properties (Abstract, SetAccess = protected)
        Statuses(:,1) appStatusStack.Status
    end

    properties (Dependent)
        CurrentStatus appStatusStack.Status
    end

    events (NotifyAccess = protected)
        StatusUpdated
    end

    methods (Abstract)

        clearStack(obj)
           
        updateStatusMessage(obj, status, message)
            
        [newStatus, cleanupObj] = addError(obj, error)

        [newStatus, cleanupObj] = addStatus(obj, nvp)

        currentStatus = removeStatus(objs, status)

        currentStatus = removeLastStatus(obj)

    end

    methods
        %% Methods for those who are used to stack language
        function [newStatus, cleanupObj] = push(obj, status)
            % Push a premade status to the stack
            arguments
                obj(1,1) appStatusStack.internal.stack.StatusStackInterface
                status(1,1) appStatusStack.Status
            end

            if nargout == 2
                [newStatus, cleanupObj] = obj.addStatus("Status", status);
            else
                newStatus = obj.addStatus("Status", status);
            end

        end

        function pop(obj)
            % Pop the last status from the stack

            arguments
                obj(1,1) appStatusStack.internal.stack.StatusStackInterface
            end

            % Remove the last status
            if ~isempty(obj.Statuses)
                obj.Statuses(end) = [];
            end

            % Make sure state not empty
            obj.check();

            notify(obj, "StatusUpdated");
        end

        function value = top(obj)
            % Get the top of the stack
            value = obj.CurrentStatus;
        end

        % Get the latest status
        function value = get.CurrentStatus(obj)
            if ~isempty(obj.Statuses)
                value = obj.Statuses(end);
            else
                value = obj.Statuses;
            end
        end

    end % methods

    methods (Access = protected)
        function check(obj)
            if isempty(obj.Statuses)
                obj.addStatus("State", appStatusStack.State.Idle, "Message", "Idle");
            end
        end % check
    end
end

