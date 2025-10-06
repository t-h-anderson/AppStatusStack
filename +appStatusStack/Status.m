classdef Status < matlab.mixin.SetGet
    %STATUS settings for models
    
    properties
        IsVisible (1,1) logical
    end
    
    properties (SetAccess = protected)
        State(1, 1) appStatusStack.State = appStatusStack.State.Idle
        Message(1, 1) string = ""
        ID(1,1) string = ""
        Value (1,1) double = NaN
        Data

        IsTemporary (1,1) logical = false % Remove when next status added
        IsComplete (1,1) logical = false % Has the status been completed
        IsBlocking (1,1) logical = false % Block graphical display until status clears
    end

    events (NotifyAccess = protected)
        Complete % When the status is removed/cleared
    end
    
    methods
        function obj = Status(state, message, nvp)
            %STATUS Construct an instance of this class
            
            arguments
                state (1,1) appStatusStack.State
                message (1,1) string = ""
                nvp.IsVisible (1,1) logical = true
                nvp.IsTemporary (1,1) logical = false
                nvp.Value (1,1) double = NaN
                nvp.Data = []
                nvp.IsBlocking (1,1) logical = false
            end
            
            obj.State = state;
            obj.Message = message;
            
            % Random string for ID
            obj.ID = matlab.lang.internal.uuid();
            set(obj, nvp);
        end

        function updateMessage(objs, message)
            arguments
                objs (1,:) appStatusStack.Status
                message (1,1) string
            end
            [objs.Message] = deal(message);
        end

        function complete(objs)
            [objs.IsComplete] = deal(true);
            notify(objs, "Complete");
        end
        
        function delete(objs)
            notify(objs, "Complete");
        end
    end % methods
   
end % classdef

