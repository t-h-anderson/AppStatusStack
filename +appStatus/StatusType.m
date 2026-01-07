classdef StatusType
    %STATUSTYPE Enumeration of app status type
    
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

