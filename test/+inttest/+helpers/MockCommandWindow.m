classdef MockCommandWindow < statusMgr.view.CommandWindow
    % CommandWindow subclass for tests:
    %   * readUserInput returns canned responses instead of blocking on stdin
    %   * exposes writeToTerminal so tests can drive it directly without
    %     going through standardDisplay (which resets PreviousMessage in
    %     beforeDisplay and would mask the repeated-message branch).

    properties
        Responses (1,:) string = string.empty(1,0)
    end

    methods
        function callWriteToTerminal(obj, message)
            obj.writeToTerminal(message);
        end
    end

    methods (Access = protected)
        function raw = readUserInput(obj, ~)
            if isempty(obj.Responses)
                raw = "";
                return
            end
            raw = obj.Responses(1);
            obj.Responses = obj.Responses(2:end);
        end
    end
end
