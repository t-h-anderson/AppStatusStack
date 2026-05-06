classdef CancellationToken < handle
    %CANCELLATIONTOKEN Cooperative cancellation signal for long-running ops.
    %
    % A token is created by Stack.runCancellable and passed as the first
    % argument to the wrapped function. Cancellable views (e.g. Popup
    % progress dialog) call cancel() on the token when the user clicks
    % Cancel; the running function is expected to poll
    % IsCancellationRequested() periodically and bail out gracefully:
    %
    %   stack.runCancellable(@(token) work(token));
    %
    %   function work(token)
    %       for i = 1:N
    %           if token.IsCancellationRequested()
    %               return  % or throwIfCancellationRequested()
    %           end
    %           ... do step i ...
    %       end
    %   end
    %
    % IsCancelled is SetObservable so callers can also block on it via
    % `waitfor(token, "IsCancelled", true)` from another context.

    properties (SetAccess = protected, SetObservable)
        IsCancelled (1,1) logical = false
    end

    methods

        function cancel(obj)
            % Mark cancellation as requested. Idempotent.
            obj.IsCancelled = true;
        end

        function tf = IsCancellationRequested(obj)
            % Convenience accessor matching the .NET-style naming used
            % in user code: `if token.IsCancellationRequested(); return; end`.
            tf = obj.IsCancelled;
        end

        function throwIfCancellationRequested(obj)
            % Raise an MException with identifier statusMgr:cancelled
            % if cancellation has been requested. Lets user code bail
            % out via standard error-propagation rather than manual
            % returns.
            if obj.IsCancelled
                error("statusMgr:cancelled", ...
                    "Operation was cancelled by the user.");
            end
        end

    end

end
