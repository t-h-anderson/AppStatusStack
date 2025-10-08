classdef StatusStack < appStatus.internal.stack.StatusStackInterface
    %STATUSStack
    % Use example:
    % statusStack = appStatus.stack.StatusStack();
    % [newStatus, cleanObj] = statusStack.addStatus(appStatus.Condition.Running, "Initialising");
    % updateStatusMessage(obj, status, message)

    properties (SetAccess = protected)
        Statuses = appStatus.Status("Idle")
        StatusListeners
        StatusStackMonitorableListeners
    end

    properties (Dependent)
        CurrentStatus
    end

    methods % get/set

        function set.Statuses(obj, val)
            obj.Statuses = val;
            obj.StatusListeners = event.listener(obj.Statuses, "Completed", @(s,e) obj.onStatusCompleted(s,e)); %#ok<MCSUP>
        end

        % Ensure there is always an idle status
        function val = get.Statuses(obj)
            if isempty(obj.Statuses)
                val = appStatus.Status("Idle");
                obj.Statuses = val;
            else
                val = obj.Statuses;
            end
        end

        % Get the latest status
        function value = get.CurrentStatus(obj)
            % Note, statuses can never be empty as it will default to idle 
            % if this ever occurs, see get.Statuses
            value = obj.Statuses(end);
        end

    end

    methods % Adding

        function [status, cleanupObj] = addCondition(objs, condition, nvp)
            % Push a new Condition to the stack
            % [status, cleanupObj] = addCondition(Condition, nvp)
            % cleanupObj is an optional output that creates a cleanup object
            % Name value pairs:
            %   Message (Running) - set the Condition message
            %   IsVisible (true) - set the Condition visibility
            %   Value (double) - Used for setting progress bar values
            %   Data (Condition data) - Store data in the Condition
            %   Silent (logical) - whether to notify the Condition has
            %   changed
            arguments
                objs (1,:) appStatus.stack.StatusStack
                condition (1,1) appStatus.Condition = appStatus.Condition.Running
                nvp.Message (1,1) string = "Running"
                nvp.IsVisible (1,1) logical = true
                nvp.IsTemporary (1,:) logical {mustBeScalarOrEmpty} = false
                nvp.Value (1,1) double = NaN
                nvp.Data = []
                nvp.Silent (1,1) logical = false
                nvp.IsBlocking (1,1) logical = false
                nvp.CreateCleanupObj (1,1) logical = true
            end

            if nargout < 2
                nvp.CreateCleanupObj = false;
            end

            newStatus = appStatus.Status(condition, nvp.Message, ...
                "IsVisible", nvp.IsVisible, ...
                "Value", nvp.Value, ...
                "IsTemporary", nvp.IsTemporary, ...
                "Data", nvp.Data, ...
                "IsBlocking", nvp.IsBlocking);

            [status, cleanupObj] = objs.addStatus(newStatus, ...
                "Silent", nvp.Silent, ...
                "CreateCleanupObj", nvp.CreateCleanupObj);

        end

        function [newStatus, cleanupObj] = addStatus(objs, newStatus, nvp)
            % Push a new status to the stack
            % [newStatus, cleanupObj] = addStatus(args, newStatus)
            % cleanupObj is an optional output that creates a cleanup object
            % Name value pairs:
            %   Silent (logical) - whether to notify the Condition has
            %   changed
            arguments
                objs (1,:) appStatus.stack.StatusStack
                newStatus (1,1) appStatus.Status
                nvp.Silent (1,1) logical = false
                nvp.CreateCleanupObj (1,1) logical = true
            end

            if nargout < 2
                nvp.CreateCleanupObj = false;
            end

            % Distribute call to each stack
            if numel(objs) > 1
                nvpCell = namedargs2cell(nvp);
                newStatus = cell(numel(objs), 1);
                cleanupObj = cell(numel(objs), 1);
                for i = 2:numel(objs)
                    [newStatus{i}, cleanupObj{i}] = objs(i).addStatus(nvpCell{:});
                end
                newStatus = [newStatus{:}];
                cleanupObj = [cleanupObj{:}];
                return
            elseif isempty(objs)
                newStatus = appStatus.Status.empty(1,0);
                cleanupObj = onCleanup.empty(1,0);
                return
            end

            objs.appendStatus(newStatus);

            % Create cleanup object for second argument
            if nvp.CreateCleanupObj
                removeStatusFn = @() objs.removeStatus(newStatus);
                cleanupObj = onCleanup(removeStatusFn);
            else
                cleanupObj = {};
            end

            % Notify that the status has changed
            if ~nvp.Silent
                notify(objs, "StatusUpdated");
            end

        end

        function [newStatus, cleanupObj] = addError(objs, err, nvp)
            arguments
                objs (1,:) 
                err (1,1) MException
                nvp.IsVisible (1,1) logical = true
                nvp.IsTemporary (1,1) logical = false
                nvp.Silent (1,1) logical = false
                nvp.IsBlocking (1,1) logical = true
                nvp.CreateCleanupObj (1,1) logical = true
            end

            % Remove test infrastructure
            message = getReport(err, "extended");
            message = string(message);
            message = strsplit(message, newline);
            idx = find(contains(message, "matlab.unittest"), 1);
            message(idx:end) = [];
            message = strjoin(message, newline);

            if nargout < 2
                nvp.CreateCleanupObj = false;
            end

            nvpCell = namedargs2cell(nvp);
            [newStatus, cleanupObj] = objs.addCondition("Error", ...
                "Data", err, ...
                "Message", message, nvpCell{:});

        end

    end

    methods % Updating

        function updateStatusMessage(objs, message, status)
            arguments
                objs (1,:) appStatus.stack.StatusStack
                message (1,1) string
                status (1,1) appStatus.Status
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
                obj.CurrentStatus.updateMessage(message);

                % Only update if we are at the top of the stack
                notify(obj, "StatusUpdated");
            else
                % Otherwise find it in the stack
                idx = ([obj.Statuses.ID] == status.ID);
                obj.Statuses(idx).updateMessage(message);
            end

        end

    end

    methods % Removing

        function removeStatus(objs, toRemove, nvp)
            % Remove a status from the stack
            % - doesn't have to be top of the stack!

            arguments
                objs (1,:) appStatus.stack.StatusStack
                toRemove (1,:) appStatus.Status
                nvp.Silent (1,1) logical = false
            end

            for ii = 1:numel(objs)
                obj = objs(ii);

                % Check validity
                toRemove(~isvalid(toRemove)) = [];
                if isempty(obj.Statuses) || isempty(toRemove)
                    return
                end

                % Check if last status
                if isscalar(toRemove) ...
                        && obj.CurrentStatus.ID == toRemove.ID
                    matchingIdx = numel(obj.Statuses);
                else
                    % Find matching statuses by ID
                    allIds = string([obj.Statuses.ID]);
                    idsToRemove = string([toRemove.ID]);
                    matchingIdx = matches(allIds, idsToRemove);
                end

                toComplete = obj.Statuses(matchingIdx);
                obj.Statuses(matchingIdx) = [];
                toComplete.complete();

                if ~nvp.Silent
                    notify(obj, "StatusUpdated");
                end

            end

        end

        function removeLastStatus(obj, nvp)
            % Remove the last status from the stack
            arguments
                obj (1,1) appStatus.stack.StatusStack
                nvp.Silent (1,1) logical = false
            end

            obj.removeStatus(obj.CurrentStatus, Silent=nvp.Silent);

        end

        function removeAllStatuses(obj)
            arguments
                obj (1,:) appStatus.stack.StatusStack
            end

            % Remove all the statuses
            statuses = [obj.Statuses];
            obj.removeStatus(statuses);
        end

    end

    methods % Monitoring

        function monitor(obj, monitorable)
            arguments
                obj (1,1) appStatus.stack.StatusStack
                monitorable (1,1) appStatus.monitorable.Monitorable
            end
            obj.StatusStackMonitorableListeners(end+1) = event.listener(monitorable, "StatusChanged", @(s,e) obj.onMonitorableStatusChanged(s,e));
        end

    end

    methods % Util

        function tbl = table(obj)
            arguments
                obj (1,1) appStatus.stack.StatusStack
            end
            tbl = obj.Statuses.table();
        end

    end

    methods (Access = protected)

        function appendStatus(obj, newStatus)

            % Remove previous status if temporary
            while obj.CurrentStatus.IsTemporary
                obj.removeLastStatus(Silent=true);
            end

            % Add the status
            obj.Statuses = [obj.Statuses, newStatus];
        end

        function onStatusCompleted(obj, s, e)
            obj.removeStatus(s);
        end

        function onMonitorableStatusChanged(obj, s, e)
            status = e.Status;
            obj.addStatus(status);
        end

    end

end

