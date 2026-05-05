classdef MockCommandWindow < statusMgr.view.CommandWindow
    % CommandWindow subclass that returns a queued response from
    % readUserInput instead of blocking on stdin. Lets tests cover
    % handleInputRequest deterministically.

    properties
        Responses (1,:) string = string.empty(1,0)
    end

    methods
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
