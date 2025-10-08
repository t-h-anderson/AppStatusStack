classdef (Abstract) StatusStackInterface < handle
    %STATUSStack
    % Use example:
    % statusStack = appStatus.stack.StatusStack();
    % [newStatus, cleanObj] = statusStack.addStatus(appStatus.Condition.Running, "Initialising");
    % updateStatusMessage(obj, status, message)

    properties (Abstract, SetAccess = protected)
        Statuses(:,1) appStatus.Status
    end

    properties (Dependent)
        CurrentStatus appStatus.Status
    end

    events (NotifyAccess = protected)
        StatusUpdated
    end

    methods (Abstract)

        clear(obj)
           
        updateStatusMessage(obj, status, message)
            
        [newStatus, cleanupObj] = addError(obj, error)

        [newStatus, cleanupObj] = addStatus(obj, nvp)

        currentStatus = removeStatus(objs, status)

        currentStatus = removeLastStatus(obj)

    end

    methods
        % Get the latest status
        function value = get.CurrentStatus(obj)
            if ~isempty(obj.Statuses)
                value = obj.Statuses(end);
            else
                value = obj.Statuses;
            end
        end

    end % methods

end

