classdef (Abstract) StatusStackInterface < handle
    %STATUSStack
    % Use example:
    % statusStack = appStatus.StatusStack();
    % [newStatus, cleanObj] = statusStack.addStatus(appStatus.Condition.Running, "Initialising");
    % updateStatusMessage(obj, status, message)

    properties (Abstract, SetAccess = protected)
        Statuses(1,:) appStatus.Status
        StatusListeners (1,:) event.listener
        StatusStackMonitorableListeners (1,:) event.listener
    end

    properties (Abstract, Hidden)
        ID (1,1) string
    end

    properties (Abstract, Dependent)
        CurrentStatus appStatus.Status
    end

    events (NotifyAccess = protected)
        StatusUpdated
    end

    methods (Abstract)
        
        % Adding
        [status, cleanupObj] = addCondition(objs, condition, nvp)

        [newStatus, cleanupObj] = addStatus(obj, nvp)

        [newStatus, cleanupObj] = addError(obj, error)

        % Updating
        updateStatusMessage(obj, status, message)

        % Removal
        removeStatus(objs, status)

        removeLastStatus(obj)

        removeAllStatuses(obj)

        % Monitoring
        monitor(obj, montorable)

        run(obj, fcnHandle)

        % Util
        tbl = table(obj)
    end

end

