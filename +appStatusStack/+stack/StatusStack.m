classdef StatusStack < appStatusStack.internal.stack.StatusStackInterface
    %STATUSStack
    % Use example:
    % statusStack = appStatusStack.stack.StatusStack();
    % [newStatus, cleanObj] = statusStack.addStatus(appStatusStack.State.Running, "Initialising");
    % updateStatusMessage(obj, status, message)

    properties (SetAccess = protected)
        Statuses = appStatusStack.Status("Idle")
    end

    methods

        function obj = StatusStack()
            % Add the default status
            obj.check();
        end

        function clearStack(obj)
            arguments
                obj(1,1) appStatusStack.stack.StatusStack
            end

            % Remove all the statuses
            obj.Statuses.complete();
            obj.Statuses = appStatusStack.Status.empty();

            % Add the default
            obj.check();

            notify(obj, "StatusUpdated");
        end

        function updateStatusMessage(objs, status, message)
            arguments
                objs (1,:) appStatusStack.stack.StatusStack
                status (1,1) appStatusStack.Status
                message (1,1) string
            end

            % Distribute to each stack
            if isempty(objs)
                return
            elseif numel(objs) > 1
                for i = 1:numel(objs)
                    obj = objs(i);
                    obj.updateStatusMessage(status, message);
                end
                return
            else
                obj = objs;
            end

            % If no current status, nothing to update
            currentStatus = obj.CurrentStatus;
            if isempty(currentStatus)
                return
            end

            if currentStatus.ID == status.ID
                % Quickest to just update the current status
                obj.Statuses(end).updateMessage(message);

                % Only update if we are at the top of the stack
                notify(obj, "StatusUpdated");
            else
                % Otherwise find it in the stack
                idx = ([obj.Statuses.ID] == status.ID);
                obj.Statuses(idx).updateMessage(message);
            end

        end

        function [newStatus, cleanupObj] = addError(objs, error, nvp)
            arguments
                objs (1,:) 
                error (1,1) MException
                nvp.IsVisible (1,1) logical = true
                nvp.IsTemporary (1,1) logical = false
                nvp.AddSilent (1,1) logical = false
                nvp.IsBlocking (1,1) logical = true
            end

            objs.Statuses(:) = [];

            nvpCell = namedargs2cell(nvp);

            switch nargout
                case 2
                    [newStatus, cleanupObj] = objs.addStatus("Data", error, "State", "Error", "Message", error.message, nvpCell{:});
                case 1
                    newStatus = objs.addStatus("Data", error, "State", "Error", "Message", error.message, nvpCell{:});
                case 0
                    objs.addStatus("Data", error, "State", "Error", "Message", error.message, nvpCell{:});
            end

        end

        function [status, cleanupObj] = addState(objs, state, nvp)
            % Push a new state to the stack
            % [status, cleanupObj] = addStatus(state, args)
            % cleanupObj is an optional output that creates a cleanup object
            % Name value pairs:
            %   Message (Running) - set the state message
            %   IsVisible (true) - set the state visibility
            %   Value (double) - Used for setting progress bar values
            %   Data (State data) - Store data in the state
            %   AddSilent (logical) - whether to notify the state has
            %   changed
            arguments
                objs (1,:) appStatusStack.stack.StatusStack
                state (1,1) appStatusStack.State = appStatusStack.State.Running
                nvp.Message (1,1) string = "Running"
                nvp.IsVisible (1,1) logical = true
                nvp.IsTemporary (1,1) logical = false
                nvp.Value (1,1) double = NaN
                nvp.Data = []
                nvp.AddSilent (1,1) logical = false
                nvp.IsBlocking (1,1) logical = false
            end

            newStatus = appStatusStack.Status(state, nvp.Message, ...
                "IsVisible", nvp.IsVisible, "Value", nvp.Value, "IsTemporary", nvp.IsTemporary, "Data", nvp.Data, "IsBlocking", nvp.IsBlocking);
            
            if nargout == 2
               [status, cleanupObj] = objs.addStatus(newStatus, "AddSilent", nvp.AddSilent);
            elseif nargout == 1
                status = objs.addStatus(newStatus, "AddSilent", nvp.AddSilent);
            else
                objs.addStatus(newStatus, "AddSilent", nvp.AddSilent);
            end
        end

        function [newStatus, cleanupObj] = addStatus(objs, newStatus, nvp)
            % Push a new status to the stack
            % [newStatus, cleanupObj] = addStatus(args, newStatus)
            % cleanupObj is an optional output that creates a cleanup object
            % Name value pairs:
            %   AddSilent (logical) - whether to notify the state has
            %   changed
            arguments
                objs (1,:) appStatusStack.stack.StatusStack
                newStatus (1,1) appStatusStack.Status
                nvp.AddSilent (1,1) logical = false
            end

            % Distribute call to each stack
            if numel(objs) > 1
                nvpCell = namedargs2cell(nvp);
                newStatus = cell(numel(objs), 1);
                cleanupObj = cell(numel(objs), 1);
                for i = 2:numel(objs)

                    if nargout == 2
                        [newStatus{i}, cleanupObj{i}] = objs(i).addStatus(nvpCell{:});
                    elseif nargout == 1
                        newStatus{i} = objs(i).addStatus(nvpCell{:});
                    else
                        objs(i).addStatus(nvpCell{:});
                    end

                end
                newStatus = [newStatus{:}];
                cleanupObj = [cleanupObj{:}];
                return
            elseif isempty(objs)
                newStatus = appStatusStack.Status.empty(1,0);
                cleanupObj = onCleanup.empty(1,0);
                return
            end

            objs.appendStatus(newStatus);
           
            % Create cleanup object for second argument
            if nargout == 2
                removeStatusFn = @() objs.removeStatus(newStatus);
                cleanupObj = onCleanup(removeStatusFn);
            end

            % Notify that the status has changed
            if ~nvp.AddSilent
                notify(objs, "StatusUpdated");
            end

        end

        function removeStatus(objs, status, nvp)
            % Remove a status from the stack
            % - doesn't have to be top of the stack!

            arguments
                objs (1,:) appStatusStack.stack.StatusStack
                status (:,1) appStatusStack.Status
                nvp.RemoveSilent (1,1) logical = false
            end

            for ii = 1:numel(objs)
                obj = objs(ii);

                % Check validity
                status(~isvalid(status)) = [];
                if isempty(obj.Statuses)
                    return
                end

                % Check if last status
                if numel(status) == 1 ...
                        && obj.Statuses(end).ID == status.ID
                    obj.pop();
                else
                    % Find matching statuses by ID
                    allIds = [obj.Statuses.ID];
                    idsToRemove = [status.ID];

                    % Remove a matching status
                    matchingIdx = matches(allIds, idsToRemove);
                    statusesToRemove = obj.Statuses(matchingIdx);
                    obj.Statuses(matchingIdx) = [];
                    statusesToRemove.complete();
                end

                % Make sure state not empty
                obj.check();
            end

            if ~nvp.RemoveSilent
                notify(obj, "StatusUpdated");
            end
        end

        function removeLastStatus(obj, nvp)
            % Remove the last status from the stack
            arguments
                obj(1,1) appStatusStack.stack.StatusStack
                nvp.RemoveSilent (1,1) logical = false
            end

            if ~nvp.RemoveSilent
                obj.pop("RemoveSilent", nvp.RemoveSilent);
            end
        end

    end

    methods (Hidden)
        %% Methods for those who are used to stack language
        function [newStatus, cleanupObj] = push(obj, status, nvp)
            % Push a premade status to the stack
            arguments
                obj (1,1) appStatusStack.stack.StatusStack
                status (1,1) appStatusStack.Status
                nvp.AddSilent (1,1) logical = false
            end

            if nargout == 2
                [newStatus, cleanupObj] = obj.addStatus("Status", status, "AddSilent", nvp.AddSilent);
            else
                newStatus = obj.addStatus("Status", status, "AddSilent", nvp.AddSilent);
            end

        end

        function pop(obj, nvp)
            % Pop the last status from the stack

            arguments
                obj(1,1) appStatusStack.stack.StatusStack
                nvp.RemoveSilent (1,1) logical = false
            end

            % Remove the last status
            if ~isempty(obj.Statuses)
                statusToRemove = obj.Statuses(end);
                obj.Statuses(end) = [];
                statusToRemove.complete();
            end

            % Make sure state not empty
            obj.check();

            if ~nvp.RemoveSilent
                notify(obj, "StatusUpdated");
            end
        end

        function value = top(obj)
            % Get the top of the stack
            value = obj.CurrentStatus;
        end

    end % methods

    methods (Access = protected)
        function check(objs)
            arguments
                objs (1,:) appStatusStack.stack.StatusStack
            end
            for i = 1:numel(objs)
                obj = objs(i);
                if isempty(obj.Statuses)
                    obj.addState(appStatusStack.State.Idle, "Message", "Idle", "AddSilent", true);
                end
            end
        end % check

        function appendStatus(obj, newStatus)

            % Remove previous status if temporary
            try
                if ~isempty(obj.CurrentStatus) ...
                        && obj.CurrentStatus.IsTemporary
                    obj.removeLastStatus();
                end
            catch me
                disp(me.message)
            end

            % Add the status
            obj.Statuses = [obj.Statuses; newStatus];
        end

    end
end

