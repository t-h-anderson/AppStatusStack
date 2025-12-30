classdef Monitorable < appStatus.monitorable.Monitorable
    
    methods
        
        function showError(obj, message)
            status = appStatus.Status("Error", message);
            obj.setStatus(status);
        end
    end
end