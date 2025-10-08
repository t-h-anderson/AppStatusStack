classdef (Abstract) Monitorable < handle
    %MONITORABLE Able to be monitored by an appStatusStack

    events
        StatusChanged
    end

    methods
        
        function setStatus(obj, status)
            arguments
                obj (1,1)
                status (1,1) appStatus.Status
            end
            statusData = appStatus.monitorable.StatusEventData(status);
            notify(obj, "StatusChanged", statusData);
        end

    end

end