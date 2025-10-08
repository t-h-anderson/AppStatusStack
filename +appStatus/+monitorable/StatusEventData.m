classdef StatusEventData < event.EventData
    properties
        Status (1,1) appStatus.Status
    end

    methods
        function data = StatusEventData(status)
            data.Status = status;
        end
    end

end