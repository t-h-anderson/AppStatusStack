classdef Status < matlab.mixin.SetGet
    %STATUS settings for models
   
    properties (SetAccess = protected)
        Identifier (1,1) string = "" % Semantic identified, for filtering/suppression
        Type (1,1) statusMgr.StatusType = statusMgr.StatusType.Idle
        Message (1,1) string = ""
        Title (1,1) string = ""
        MessageShort (1,1) string = string(NaN)
        Value (1,1) double = NaN
        Data = [] % Pocket to store data
        Timestamp (1,1) datetime
        User (1,1) string = ""

        IsTemporary (1,1) logical = false % Remove when next status added
        IsComplete (1,1) logical = false % Has the status been completed
        CompletionFcn (1,:) function_handle {mustBeScalarOrEmpty}
    end

    properties (SetObservable)
        IsVisible (1,1) logical = true
    end

    properties (SetAccess = protected, Hidden)
        ID (1,1) string = "" % unique ID
    end

    events (NotifyAccess = protected)
        Completed % When the status is removed/cleared
    end

    methods
        function obj = Status(condition, message, nvp)
            %STATUS Construct an instance of this class

            arguments
                condition (1,1) statusMgr.StatusType = statusMgr.StatusType.Idle
                message (1,1) string = ""
                nvp.Title (1,1) string = ""
                nvp.Identifier (1,1) string = ""
                nvp.Value (1,1) double = NaN
                nvp.IsVisible (1,1) logical = true
                nvp.IsTemporary (1,1) logical = false
                nvp.Data
                nvp.MessageShort (1,1) string = string(NaN)
                nvp.CompletionFcn (1,:) function_handle {mustBeScalarOrEmpty} = function_handle.empty(1,0)
            end

            % Random string for ID
            obj.ID = statusMgr.util.uuid();

            % Capture who and when the status was created.
            obj.Timestamp = datetime("now");
            user = getenv("USER");
            if isempty(user)
                user = getenv("USERNAME");
            end
            obj.User = string(user);

            obj.Type = condition;
            obj.Message = message;
            set(obj, nvp);
        end

        function updateMessage(objs, message)
            arguments
                objs (1,:) statusMgr.Status
                message (1,1) string
            end
            [objs.Message] = deal(message);
        end

        function updateValue(objs, value)
            arguments
                objs (1,:) statusMgr.Status
                value (1,1) double
            end
            [objs.Value] = deal(value);
        end

        function transitionInputState(obj, newType, value)
            % Transition status type for the input request protocol.
            % RequestingInput -> AwaitingInput -> ValueSupplied
            arguments
                obj (1,1) statusMgr.Status
                newType (1,1) statusMgr.StatusType
                value (1,1) string = ""
            end
            validTargets = [statusMgr.StatusType.AwaitingInput, statusMgr.StatusType.ValueSupplied];
            if ~ismember(newType, validTargets)
                error("statusMgr:Status:invalidTransition", ...
                    "transitionInputState only accepts AwaitingInput or ValueSupplied.");
            end
            obj.Type = newType;
            if newType == statusMgr.StatusType.ValueSupplied
                obj.Message = value;
            end
        end

        function complete(objs)
            idx = ~[objs.IsComplete];
            toComplete = (objs(idx));

            if ~isempty(toComplete)
                [toComplete.IsComplete] = deal(true);

                % Call any completion functions
                for i = 1:numel(toComplete)
                    this = toComplete(i);
                    if ~isempty(this.CompletionFcn)
                        this.CompletionFcn(this);
                    end
                end

                notify(toComplete, "Completed");
            end
        end

        function tbl = table(objs)

            ID = string([objs.ID])';
            Timestamp = [objs.Timestamp]';
            User = string([objs.User])';
            IsVisible = [objs.IsVisible]';
            Type = string([objs.Type])';
            Message = string([objs.Message])';
            Value = [objs.Value]';
            Data = {objs.Data}';
            IsTemporary = [objs.IsTemporary]';
            IsComplete = [objs.IsComplete]';

            tbl = table(ID, Timestamp, User, IsVisible, Type, Message, Value, Data, IsTemporary, IsComplete);
        end

        function delete(objs)
            % Complete valid statuses
            % isvalid is unreliable inside delete — MATLAB may begin
            % invalidating handles before the user-defined delete runs.
            idx = ~isDeleted(objs);
            objs = objs(idx);
            
            % IsComplete is a plain property, always readable here, and
            % correctly identifies statuses not yet cleaned up via complete().
            idx = ~[objs.IsComplete];
            objs = objs(idx);
            if ~isempty(objs)
                notify(objs, "Completed");
            end
        end

        function val = get.MessageShort(obj)
            if ismissing(obj.MessageShort)
                val = obj.Message;
            else
                val = obj.MessageShort;
            end
        end

        function idx = isDeleted(objs)
            idx = false(size(objs));
            for i = 1:numel(objs)
                try
                    objs(i).ID;
                catch
                    idx(i) = true;
                end
            end
        end

    end % methods

end % classdef

