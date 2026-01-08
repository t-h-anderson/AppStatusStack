classdef Status < matlab.mixin.SetGet
    %STATUS settings for models
   
    properties (SetAccess = protected)
        Identifier (1,1) string = "" % Semantic identified, for filtering/suppression
        Type (1,1) appStatus.StatusType = appStatus.StatusType.Idle
        Message (1,1) string = ""
        MessageShort (1,1) string = string(NaN)
        Value (1,1) double = NaN
        Data = [] % Pocket to store data
        Timestamp (1,1) datetime

        IsTemporary (1,1) logical = false % Remove when next status added
        IsBlocking (1,1) logical = false % Block graphical display until status clears
        IsComplete (1,1) logical = false % Has the status been completed
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
                condition (1,1) appStatus.StatusType = appStatus.StatusType.Idle
                message (1,1) string = ""
                nvp.Identifier (1,1) string = ""
                nvp.Value (1,1) double = NaN
                nvp.IsVisible (1,1) logical = true
                nvp.IsTemporary (1,1) logical = false
                nvp.IsBlocking (1,1) logical = false
                nvp.Data
                nvp.MessageShort (1,1) string = string(NaN)
            end

            % Random string for ID
            obj.ID = appStatus.util.uuid();

            % Set timestamp at creation time.
            obj.Timestamp = datetime("now");

            obj.Type = condition;
            obj.Message = message;
            set(obj, nvp);
        end

        function updateMessage(objs, message)
            arguments
                objs (1,:) appStatus.Status
                message (1,1) string
            end
            [objs.Message] = deal(message);
        end

        function updateValue(objs, value)
            arguments
                objs (1,:) appStatus.Status
                value (1,1) double
            end
            [objs.Value] = deal(value);
        end

        function complete(objs)
            idx = [objs.IsComplete];

            if ~any(idx)
                [objs.IsComplete] = deal(true);
                notify(objs, "Completed");
            end
        end

        function tbl = table(objs)

            ID = string([objs.ID])';
            IsVisible = [objs.IsVisible]';
            Type = string([objs.Type])';
            Message = string([objs.Message])';
            Value = [objs.Value]';
            Data = {objs.Data}';
            IsTemporary = [objs.IsTemporary]';
            IsBlocking = [objs.IsBlocking]';
            IsComplete = [objs.IsComplete]';

            tbl = table(ID, IsVisible, Type, Message, Value, Data, IsTemporary, IsBlocking, IsComplete);
        end

        function delete(objs)
            % Complete valid statuses
            idx = isvalid(objs);
            objs = objs(idx);
            notify(objs, "Completed");
        end

        function val = get.MessageShort(obj)
            if ismissing(obj.MessageShort)
                val = obj.Message;
            else
                val = obj.MessageShort;
            end
        end

    end % methods

end % classdef

