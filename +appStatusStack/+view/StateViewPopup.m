classdef StateViewPopup < appStatusStack.internal.view.StateViewInterface
    %STATEVIEW View a status Stack

    properties
        Parent % Graphics object
    end

    properties (SetAccess = protected)
        StatusStack = appStatusStack.stack.StatusStack.empty(1,0)
        StatusStackListener 
        CancelListener event.listener
        CancelTimer % Due to know bug - see below
    end

    properties (SetAccess = protected)
        ProgressDlg matlab.ui.dialog.ProgressDialog
        ProgressDlgStatus (1,:) appStatusStack.Status

        BlockingDialogues (1,1) logical = true
    end

    properties (Dependent)
        Figure
    end

    methods

        function obj = StateViewPopup(parent, statusStack, nvp)
            arguments
                parent = uifigure
                statusStack (1,1) appStatusStack.internal.stack.StatusStackInterface = appStatusStack.stack.StatusStack
                nvp.BlockingDialogues (1,1) logical = true
            end

            % Set view parent and stack properties
            obj.Parent = parent;
            obj.BlockingDialogues = nvp.BlockingDialogues;

            % Add listener to stack
            obj.setStack(statusStack);

            obj.standardDisplay();

        end

        function tf = isVisible(obj)
            tf = ~isempty(obj.Figure) && isvalid(obj.Figure);
        end

        function value = get.Figure(obj)
            % Get the handle for the parent's figure
            value = ancestor(obj.Parent, "figure");
        end

    end

    methods (Access = protected)
        % These methods can be overloaded to tailor the view behaviour

        function displayRunning(obj, status, stack, cancellable)
            % displayRunning: displays a uiwaitbar in the main window

            arguments
                obj
                status appStatusStack.Status
                stack appStatusStack.internal.stack.StatusStackInterface %#ok<INUSA> 
                cancellable (1,1) logical = false
            end % arguments

            if ~status.IsVisible || ~obj.ShowRunning
                % Delete because not visible
                obj.deleteProgressDlg();
            else

                % Check figure exists and is visible
                if isvalid(obj.Figure) && obj.Figure.Visible == "on"

                    if isempty(obj.ProgressDlg) || ~isvalid(obj.ProgressDlg)
                        % No progress dlg, so create
                        obj.createProgressDlg(status, cancellable);

                    else
                        % Exists so update
                        obj.ProgressDlgStatus = status;

                        if ~strcmp(obj.ProgressDlg.Message, status.Message)
                            obj.ProgressDlg.Message = status.Message;
                        end

                        if obj.ProgressDlg.Cancelable ~= cancellable
                            obj.ProgressDlg.Cancelable = cancellable;
                        end

                        if ~(isempty(status.Value) || ismissing(status.Value))
                            obj.ProgressDlg.Value = status.Value;

                            if ~strcmp(obj.ProgressDlg.Indeterminate, 'off')
                                obj.ProgressDlg.Indeterminate = 'off';
                            end

                        else
                            if ~strcmp(obj.ProgressDlg.Indeterminate, 'on')
                                obj.ProgressDlg.Indeterminate = 'on';
                            end
                        end

                    end % progress dlg status

                end % figure exists

            end % is visible

        end % displayProgress

        function displayError(obj, status, stack)
            if obj.ShowErrors
                obj.popupAlert(status, stack, "Error", "error");
            end
        end

        function displayWarning(obj, status, stack)
            if obj.ShowWarnings
                obj.popupAlert(status, stack, "Warning", "warning");
            end
        end

        function displaySuccess(obj, status, stack)
            if obj.ShowSuccess
                obj.popupAlert(status, stack, "Success", "success");
            end
        end

        function displayIdle(obj, varargin)
            if obj.ShowIdle
                % Do nothing
            end
            obj.deleteProgressDlg();
        end

        function popupAlert(obj, status, stack, title, icon)
            % popupAlert displays a popup in the main window

            arguments
                obj
                status appStatusStack.Status
                stack appStatusStack.internal.stack.StatusStackInterface
                title = "Error"
                icon = "error"
            end % arguments

            obj.checkProgressDlg();

            if status.IsVisible && obj.BlockingDialogues
                obj.deleteProgressDlg();

                % Display the alert
                if isvalid(obj.Figure)

                    removeStatusFn = @(src, event) stack.removeStatus(status);
                    uialert(obj.Figure, ...
                        status.Message, ...
                        title, ...
                        "Icon", icon, ...
                        "CloseFcn", removeStatusFn);

                    % Set visibility to false so popup isn't recreated
                    status.IsVisible = false;

                end

                while status.IsBlocking && stack.CurrentStatus == status
                    % Wait till user clicks ok
                    drawnow
                end
            end


        end % popupAlert

        function checkProgressDlg(obj)
            statuses = obj.StatusStack.Statuses;
            states = [statuses.State];
            idx = ismember(states, appStatusStack.State.Running) ...
               | ismember(states, appStatusStack.State.RunningCancellable);

            isVisible = [statuses(idx).IsVisible];

            if ~any(isVisible)
                obj.deleteProgressDlg();
            end
        end

        function notifyStackOfCancel(obj)
            if obj.ProgressDlg.CancelRequested
                stopTimer(obj.CancelTimer);
                status = obj.ProgressDlgStatus;
                obj.StatusStack.removeStatus(status);
            end
        end

        function deleteProgressDlg(obj)
            delete(obj.ProgressDlg);
            delete(obj.CancelListener);
        end

        function createProgressDlg(obj, status, cancellable)

            % Doesnt exit, so create
            defaultProps = struct("Title", "Running", "Message", status.Message, 'Indeterminate','on', "Cancelable", cancellable);
            defaultProps = namedargs2cell(defaultProps);
            if isempty(status.Value) || ismissing(status.Value)
                obj.ProgressDlg = uiprogressdlg(obj.Figure, 'Indeterminate','on', defaultProps{:});
            else
                obj.ProgressDlg = uiprogressdlg(obj.Figure, 'Indeterminate','off', "Value", status.Value, defaultProps{:});
            end

            obj.ProgressDlgStatus = status;

            % This doesn't work - Known bug https://komodo.mathworks.com/main/gecko/view?Record=2984852
            % obj.CancelListener = addlistener(obj.ProgressDlg, "CancelRequested", "PostSet", @(src, event) obj.notifyStackOfCancel());

            stopTimer(obj.CancelTimer);
            warning("off", "MATLAB:timer:deleterunning");
            obj.CancelTimer = timer("TimerFcn", @(~,~)obj.notifyStackOfCancel(), "Period", 1, "TasksToExecute", inf, "ExecutionMode", "fixedSpacing");
            obj.CancelTimer.start();

        end


    end % methods

end % classdef

function stopTimer(timer)

try
    stop(timer);
    delete(dimer)
catch
end

end
