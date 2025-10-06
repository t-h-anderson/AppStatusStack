classdef State
    %STATE Enumeration of model state
    
    enumeration
        Running
        RunningCancellable
        Error
        Warning
        Success
    end

    enumeration (Hidden)
        Idle
    end
    
end

