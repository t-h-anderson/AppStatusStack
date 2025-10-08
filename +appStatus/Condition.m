classdef Condition
    %CONDITION Enumeration of app condition
    
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

