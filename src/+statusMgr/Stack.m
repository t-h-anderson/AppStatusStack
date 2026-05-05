classdef Stack < statusMgr.internal.StackInterface
    %STACK
    % Use example:
    % statusStack = statusMgr.Stack();
    % [newStatus, cleanObj] = statusStack.addStatus(statusMgr.StatusType.Running, "Initialising");
    % updateStatusMessage(obj, status, message)

    properties (SetAccess = protected)
        Statuses = statusMgr.Status("Idle")
        StatusListeners
        StackMonitorableListeners
    end

    properties
        SuppressedIdentifiers (1,:) string = string.empty(1,0)
    end

    properties (Hidden)
        ID
    end

    properties (Dependent)
        CurrentStatus
    end

    methods
        function obj = Stack()
            obj.ID = matlab.lang.internal.uuid();
        end

        function delete(obj)
            delete(obj.StatusListeners);
            delete(obj.StackMonitorableListeners);
        end
    end

    methods % get/set

        function set.Statuses(obj, val)
            obj.Statuses = val;
            obj.StatusListeners = event.listener(obj.Statuses, "Completed", @(s,e) obj.onStatusCompleted(s,e)); %#ok<MCSUP>
        end

        % Ensure there is always an idle status
        function val = get.Statuses(obj)
            if isempty(obj.Statuses)
                val = statusMgr.Status("Idle");
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

        function [status, cleanupObj] = addStatus(objs, type, nvp)
            % Push a new Status of the given type to the stack
            % [status, cleanupObj] = addStatus(StatusType, nvp)
            % cleanupObj is an optional output that creates a cleanup object
            % Name value pairs:
            %   Message (Running) - set the Status message
            %   IsVisible (true) - set the Status visibility
            %   Value (double) - Used for setting progress bar values
            %   Data (Status data) - Store data in the Status
            %   Silent (logical) - whether to notify the Status has
            %   changed
            arguments
                objs (1,:) statusMgr.Stack
                type (1,1) statusMgr.StatusType = statusMgr.StatusType.Info
                nvp.Identifier (1,1) string = ""
                nvp.Message (1,1) string = ""
                nvp.Title (1,1) string = ""
                nvp.MessageShort(1,1) string = string(nan)
                nvp.IsVisible (1,1) logical = true
                nvp.IsTemporary (1,:) logical {mustBeScalarOrEmpty} = false
                nvp.Value (1,1) double = NaN
                nvp.Data = []
                nvp.Silent (1,1) logical = false
                nvp.CreateCleanupObj (1,1) logical = true
                nvp.CompletionFcn (1,:) function_handle {mustBeScalarOrEmpty} = function_handle.empty(1,0)
            end

            if nargout < 2
                nvp.CreateCleanupObj = false;
            end

            newStatus = statusMgr.Status(type, nvp.Message, ...
                "Title", nvp.Title, ...
                "Identifier", nvp.Identifier, ...
                "MessageShort", nvp.MessageShort, ...
                "IsVisible", nvp.IsVisible, ...
                "Value", nvp.Value, ...
                "IsTemporary", nvp.IsTemporary, ...
                "Data", nvp.Data, ...
                "CompletionFcn", nvp.CompletionFcn);

            [status, cleanupObj] = objs.add(newStatus, ...
                "Silent", nvp.Silent, ...
                "CreateCleanupObj", nvp.CreateCleanupObj);

        end

        function [newStatus, cleanupObj] = add(objs, newStatus, nvp)
            % Push a new status to the stack
            % [newStatus, cleanupObj] = add(args, newStatus)
            % cleanupObj is an optional output that creates a cleanup object
            % Name value pairs:
            %   Silent (logical) - whether to notify the Status has
            %   changed
            arguments
                objs (1,:) statusMgr.Stack
                newStatus (1,1) statusMgr.Status
                nvp.Silent (1,1) logical = false
                nvp.CreateCleanupObj (1,1) logical = true
            end

            if nargout < 2
                nvp.CreateCleanupObj = false;
            end

            % Distribute call to each stack
            if numel(objs) > 1
                nvpCell = namedargs2cell(nvp);
                cleanupObj = cell(numel(objs), 1);
                for i = 1:numel(objs)
                    [newStatus, cleanupObj{i}] = objs(i).add(newStatus, nvpCell{:});
                end
                % newStatus = [newStatus{:}];
                cleanupObj = [cleanupObj{:}];
                return
            elseif isempty(objs)
                newStatus = statusMgr.Status.empty(1,0);
                cleanupObj = onCleanup.empty(1,0);
                return
            end

            objs.appendStatus(newStatus);

            % Create cleanup object for second argument
            if nvp.CreateCleanupObj
                removeStatusFn = @() objs.removeStatus(newStatus);
                cleanupObj = onCleanup(removeStatusFn);
            else
                cleanupObj = onCleanup.empty(1,0);
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
                nvp.CreateCleanupObj (1,1) logical = true
            end

            % Remove test infrastructure
            messageShort = err.message;

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
            [newStatus, cleanupObj] = objs.addStatus("Error", ...
                "Identifier", err.identifier, ...
                "Data", err, ...
                "Message", message, ...
                "MessageShort", messageShort, ...
                nvpCell{:});

        end

    end

    methods % Updating

        function updateStatus(objs, status, nvp)
            arguments
                objs (1,:) statusMgr.Stack
                status (1,1) statusMgr.Status
                nvp.Message (1,1) string
                nvp.Value (1,1) double
            end

            % Distribute to each stack
            if isempty(objs)
                return
            elseif numel(objs) > 1
                for i = 1:numel(objs)
                    obj = objs(i);
                    nvpCell = namedargs2cell(nvp);
                    obj.updateStatus(status, nvpCell{:});
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
                if isfield(nvp, "Message")
                    obj.CurrentStatus.updateMessage(nvp.Message);
                end
                if isfield(nvp, "Value")
                    obj.CurrentStatus.updateValue(nvp.Value);
                end
                if isfield(nvp, "Message") || isfield(nvp, "Value")
                    notify(obj, "StatusUpdated");
                end
            else
                % Otherwise find it in the stack. Note we don't issue the
                % StatusUpdated event in this case because the view
                % listeners update the views based on the latest status.
                idx = ([obj.Statuses.ID] == status.ID);
                if isfield(nvp, "Message")
                    obj.Statuses(idx).updateMessage(nvp.Message);
                end
                if isfield(nvp, "Value")
                    obj.Statuses(idx).updateValue(nvp.Value);
                end
            end

        end

    end

    methods % Removing

        function removeStatus(objs, toRemove, nvp)
            % Remove a status from the stack
            % - doesn't have to be top of the stack!

            arguments
                objs (1,:) statusMgr.Stack
                toRemove (1,:) statusMgr.Status
                nvp.Silent (1,1) logical = false
            end

            for ii = 1:numel(objs)
                obj = objs(ii);

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
                obj (1,1) statusMgr.Stack
                nvp.Silent (1,1) logical = false
            end

            obj.removeStatus(obj.CurrentStatus, Silent=nvp.Silent);

        end

        function removeAllStatuses(obj)
            arguments
                obj (1,:) statusMgr.Stack
            end

            % Remove all the statuses
            statuses = [obj.Statuses];
            obj.removeStatus(statuses);
        end

    end

    methods % Monitoring

        function monitor(obj, monitorable)
            arguments
                obj (1,1) statusMgr.Stack
                monitorable (1,1) statusMgr.monitorable.Monitorable
            end
            obj.StackMonitorableListeners(end+1) = event.listener(monitorable, "StatusChanged", @(s,e) obj.onMonitorableStatusChanged(s,e));
        end

        function varargout = run(obj, fcnHandle, varargin)
            arguments
                obj (1,1) statusMgr.Stack
                fcnHandle (1,1) function_handle
            end
            arguments (Repeating)
                varargin
            end

            % Store warning state and clear lastwarn
            s = warning();

            % Turn the warning back to the original state. NOTE: Assumes
            % that the function handle didn't change the warn state
            cObj = onCleanup(@() warning(s));

            warning("off");
            warning(statusMgr.util.uuid, statusMgr.util.uuid);
            [w0, c0] = lastwarn;

            % Run the code in a try catch block to capture any errors
            try
                fcnCallStr = eraseBetween(func2str(fcnHandle), textBoundary, ")", "Boundaries","inclusive");
                [~, c]= obj.addStatus("Running", ...
                    "Message", "Running: " + fcnCallStr); %#ok<ASGLU>
                if nargout > 0
                    varargout = cell(1, nargout);
                    [varargout{:}] = fcnHandle(varargin{:});
                else
                    fcnHandle(varargin{:});
                end
            catch me
                obj.addError(me);
            end

            % See if a warning was thrown by the function
            [w1, c1] = lastwarn;
            if (~strcmp(w0, w1) || ~strcmp(c0, c1)) ...
                    && ~strcmp(c1, "MATLAB:callback:error") % Remove "errors" inside callback
                obj.addStatus("Warning", "Message", w1);
            end

        end

    end

    methods % User input

        function value = requestInput(obj, prompt, nvp)
            % Block until a view supplies user input, or return DefaultValue
            % after Timeout seconds if no view claims the request.
            %
            % value = requestInput(prompt)
            % value = requestInput(prompt, DefaultValue="fallback", Timeout=5, Title="...")
            arguments
                obj (1,1) statusMgr.Stack
                prompt (1,1) string = ""
                nvp.DefaultValue (1,1) string = ""
                nvp.Title (1,1) string = "Input Required"
                nvp.Timeout (1,1) double {mustBePositive} = 0.5
            end

            % Push RequestingInput. Listeners fire synchronously here, so
            % a view may have already claimed (or even completed) the
            % request by the time addStatus returns.
            status = obj.addStatus(statusMgr.StatusType.RequestingInput, ...
                Message=prompt, ...
                Title=nvp.Title, ...
                Data=nvp.DefaultValue);
            cleanupStatus = onCleanup(@() obj.removeStatus(status)); %#ok<NASGU>

            % Poll until a view claims the request or the timeout expires.
            t = tic;
            while status.Type == statusMgr.StatusType.RequestingInput ...
                    && toc(t) < nvp.Timeout
                drawnow;
                pause(0.05);
            end

            % Nobody claimed it in time — return the default.
            if status.Type == statusMgr.StatusType.RequestingInput
                value = nvp.DefaultValue;
                return;
            end

            % A view claimed it; wait indefinitely for ValueSupplied.
            % Also exit if the status is forcibly removed (IsComplete=true)
            % to avoid an infinite loop when no ValueSupplied transition occurs.
            while status.Type == statusMgr.StatusType.AwaitingInput && ~status.IsComplete
                drawnow;
                pause(0.05);
            end

            if status.Type == statusMgr.StatusType.ValueSupplied
                value = status.Message;
            else
                value = nvp.DefaultValue;
            end
        end

    end

    methods % Suppression

        function suppressIdentifier(obj, id)
            arguments
                obj (1,1) statusMgr.Stack
                id (1,1) string
            end
            if ~ismember(id, obj.SuppressedIdentifiers)
                obj.SuppressedIdentifiers(end+1) = id;
            end
        end

        function unsuppressIdentifier(obj, id)
            arguments
                obj (1,1) statusMgr.Stack
                id (1,1) string
            end
            obj.SuppressedIdentifiers(obj.SuppressedIdentifiers == id) = [];
        end

    end

    methods % Util

        function tbl = table(obj)
            arguments
                obj (1,1) statusMgr.Stack
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

            % Hide status if its identifier is suppressed
            if newStatus.Identifier ~= "" && ismember(newStatus.Identifier, obj.SuppressedIdentifiers)
                newStatus.IsVisible = false;
            end

            % Add the status
            obj.Statuses = [obj.Statuses, newStatus];
        end

        function onStatusCompleted(obj, s, e)
            idx = isvalid(obj);
            obj = obj(idx);
            obj.removeStatus(s);
        end

        function onMonitorableStatusChanged(obj, s, e)
            status = e.Status;
            obj.add(status);
        end

    end

end

