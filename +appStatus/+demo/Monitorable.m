classdef Monitorable < appStatus.monitorable.Monitorable
    
    methods
        
        function showError(obj)
            status = appStatus.Status("Error", "Showing error");
            obj.setStatus(status);
        end
    end
end