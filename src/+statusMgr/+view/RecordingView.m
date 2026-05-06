classdef RecordingView < statusMgr.internal.view.StatusViewBase
    %RECORDINGVIEW Capture every status update from a Stack.
    %
    % A non-rendering view that simply appends every Status it sees
    % into RecordedStatuses. Useful for:
    %   * tests that want to assert on what was published rather than
    %     poking at internal stack state, and
    %   * apps that want to keep a history (e.g. an "activity log"
    %     panel populated from RecordedStatuses).
    %
    % The Show* / HandleInputRequests flags inherited from the base
    % control which status types are recorded — set ShowIdle=true to
    % include Idle statuses (off by default).
    %
    % Example:
    %
    %   stack = statusMgr.Stack();
    %   recorder = statusMgr.view.RecordingView(stack);
    %
    %   stack.addStatus("Info", Message="hello");
    %   stack.addStatus("Warning", Message="oops");
    %
    %   recorder.RecordedStatuses(2).Message  % "oops"

    properties (SetAccess = protected)
        RecordedStatuses (1,:) statusMgr.Status = statusMgr.Status.empty(1,0)
    end

    methods

        function obj = RecordingView(stack, nvp)
            arguments
                stack = statusMgr.Stack
                nvp.ShowInfo (1,1) logical = true
                nvp.ShowWarnings (1,1) logical = true
                nvp.ShowErrors (1,1) logical = true
                nvp.ShowRunning (1,1) logical = true
                nvp.ShowSuccess (1,1) logical = true
                nvp.ShowIdle (1,1) logical = false
                % HandleInputRequests defaults to true on the recorder
                % because the override below only records — it never
                % claims (no transitionInputState call), so it's safe
                % to fire even when other claim-capable views are also
                % attached.
                nvp.HandleInputRequests (1,1) logical = true
                nvp.IncludeIdentifiers (1,:) string = string.empty(1,0)
                nvp.ExcludeIdentifiers (1,:) string = string.empty(1,0)
            end
            obj.setStack(stack);
            set(obj, nvp);
        end

        function tf = isVisible(~)
            tf = true;
        end

        function clear(obj)
            % Empty the recorded history. Useful between phases of a
            % test that wants to assert only on what comes next.
            obj.RecordedStatuses = statusMgr.Status.empty(1,0);
        end

    end

    methods (Access = protected)

        function record(obj, status)
            obj.RecordedStatuses(end+1) = status;
        end

        function displayInfo(obj, status);     obj.record(status); end %#ok<*MANU>
        function displayRunning(obj, status, ~); obj.record(status); end
        function displayError(obj, status);    obj.record(status); end
        function displayWarning(obj, status);  obj.record(status); end
        function displaySuccess(obj, status);  obj.record(status); end
        function displayIdle(obj, status);     obj.record(status); end
        function handleInputRequest(obj, status); obj.record(status); end

    end

end
