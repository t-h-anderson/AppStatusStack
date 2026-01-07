classdef (Abstract) StatusStackInterface < handle
    %STATUSStack
    % Use example:
    % statusStack = appStatus.StatusStack();
    % [newStatus, cleanObj] = statusStack.addStatus(appStatus.StatusType.Running, "Initialising");
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
        [status, cleanupObj] = addStatus(objs, type, nvp)

        [newStatus, cleanupObj] = add(obj, status, nvp)

        [newStatus, cleanupObj] = addError(obj, error)

        % Updating
        updateStatus(obj, status, nvp)

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

