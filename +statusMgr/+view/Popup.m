classdef Popup < statusMgr.internal.view.StatusViewInterface
    %StatusVIEW View a status Stack

    properties
        Parent % Graphics object
    end

    properties (SetAccess = protected)
        Stack = statusMgr.Stack.empty(1,0)
        StackListener 
        CancelListener event.listener
        CancelTimer timer % Due to know bug - see below
    end

    properties (SetAccess = protected)
        ProgressDlg matlab.ui.dialog.ProgressDialog
        ProgressDlgStatus (1,:) statusMgr.Status

        HasPopup (1,1) logical = false
        PopupStatusToKeep (1,:) statusMgr.Status = statusMgr.Status
    end

    properties (Dependent)
        Figure
    end

    properties (Access = private)
        TestCase = statusMgr.internal.view.TestCase()
    end

    methods

        function obj = Popup(parent, stack, nvp)
            arguments
                parent = uifigure
                stack (1,1) statusMgr.internal.StackInterface = statusMgr.Stack
                nvp.ShowInfo (1,1) logical = true
                nvp.ShowWarnings (1,1) logical = true
                nvp.ShowErrors (1,1) logical = true
                nvp.ShowRunning (1,1) logical = true
                nvp.ShowSuccess (1,1) logical = true
                nvp.ShowIdle (1,1) logical = false
            end

            % Set view parent and stack properties
            obj.Parent = parent;
            obj.ShowInfo = nvp.ShowInfo;
            obj.ShowWarnings = nvp.ShowWarnings;
            obj.ShowErrors = nvp.ShowErrors;
            obj.ShowRunning = nvp.ShowRunning;
            obj.ShowSuccess = nvp.ShowSuccess;
            obj.ShowIdle = nvp.ShowIdle;

            % Add listener to stack
            obj.setStack(stack);

            obj.standardDisplay();
        end

        function tf = isVisible(obj)
            tf = ~isempty(obj.Figure) && isvalid(obj.Figure) && obj.Figure.Visible == "on";
        end

        function value = get.Figure(obj)
            % Get the handle for the parent's figure
            value = ancestor(obj.Parent, "figure");
        end

        function delete(obj)
            obj.deleteProgressDlg();
        end

    end

    methods (Access = protected)
        % These methods can be overloaded to tailor the view behaviour
        function beforeDisplay(obj)
            obj.clearPreviousAlert(obj.Figure);
            obj.checkProgressDlg();
        end

        function displayRunning(obj, status, cancellable)
            % displayRunning: displays a uiwaitbar in the main window
            arguments
                obj
                status statusMgr.Status
                cancellable (1,1) logical = false
            end % arguments

            % Check figure exists and is visible
            if obj.isVisible()
                obj.createProgressDlg();
                obj.updateProgressDlg(status, cancellable);
            end % figure exists

        end % displayProgress

        function displayError(obj, status)
            obj.popupAlert(status, "Error", "error");
        end

        function displayWarning(obj, status)
            obj.popupAlert(status, "Warning", "warning");
        end

        function displaySuccess(obj, status)
            obj.popupAlert(status, "Success", "success");
        end

        function displayInfo(obj, status)
            obj.popupAlert(status, "Info", "info");
        end

        function displayIdle(obj, varargin)
            % Do nothing
        end

    end

    methods (Access = protected)

        function popupAlert(obj, status, title, icon)
            % popupAlert displays a popup in the main window

            arguments
                obj
                status statusMgr.Status
                title (1,1) string = "Error"
                icon (1,1) string = "error"
            end % arguments

            if status.IsVisible

                % Display the alert
                if isvalid(obj.Figure)

                    % First time showing the status, so increment the
                    % counter
                    numPopups = obj.numberDialogues(obj.Stack);

                    if numPopups > 1
                        title = title + " (" + numPopups + " alerts)";
                    end
                    
                    removeStatusFn = @(src, event) obj.completeIfClicked(src, event, status);
                    
                    if numPopups == 1
                        options = "OK";
                    else
                        options = ["Close All", "OK"];
                    end

                    uiconfirm(obj.Figure, ...
                        status.MessageShort, ...
                        title, ...
                        "Options", options, ...
                        "Icon", icon, ...
                        "CloseFcn", removeStatusFn);

                    obj.HasPopup = true;

                end

                while status.IsBlocking && obj.Stack.CurrentStatus == status
                    % Wait till user clicks OK
                    drawnow
                end
            end


        end % popupAlert

        function clearPreviousAlert(obj, f)
            % Should only ever have one uialert
            if obj.HasPopup
                % See g1622345.
                tt = obj.TestCase;
                obj.HasPopup = false; % Avoid triggering the complete if clicked
                tt.dismissDialog("uiconfirm", f)
                drawnow
            end
        end

    end

    methods (Access = protected)
        function completeIfClicked(obj, src, event, status)
            if obj.HasPopup
                obj.HasPopup = false;
                switch event.SelectedOption
                    case "OK"
                        status.complete();
                    case "Close All"
                        obj.Stack.removeAllStatuses();
                end
            end
        end
    end

    % progress dlg
    methods (Access = protected)
        function deleteProgressDlg(obj)
            delete(obj.ProgressDlg);
            delete(obj.CancelListener);
            stopTimer(obj.CancelTimer);
        end

        function createProgressDlg(obj)

            if ~obj.hasValidProgressDlg()
                % No progress dlg, so create
                defaultProps = struct("Title", "Running");
                defaultProps = namedargs2cell(defaultProps);
                obj.ProgressDlg = uiprogressdlg(obj.Figure, 'Indeterminate','on', defaultProps{:});
                
                % TODO: Add timer so progress dlg only made/shown after a
                % delay to avoid flashing the screen

                % This doesn't work - Known bug https://komodo.mathworks.com/main/gecko/view?Record=2984852
                % obj.CancelListener = addlistener(obj.ProgressDlg, "CancelRequested", "PostSet", @(src, event) obj.notifyStackOfCancel());
                s = warning();
                warning("off");
                stopTimer(obj.CancelTimer);
                obj.CancelTimer = timer("TimerFcn", @(~,~)obj.checkIfCancelPressed(), "Period", 1, "TasksToExecute", inf, "ExecutionMode", "fixedSpacing");
                obj.CancelTimer.start();
                warning(s)

            end

        end

        function updateProgressDlg(obj, status, cancellable)
            obj.ProgressDlgStatus = status;
            if ~strcmp(string([obj.ProgressDlg.Message]), status.Message)
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
        end

        function tf = hasValidProgressDlg(obj)
            tf = ~(isempty(obj.ProgressDlg) || ~isvalid(obj.ProgressDlg));
        end

        function tf = isProgressDlgNeeded(obj, status)
            tf = (status.Type == statusMgr.StatusType.Running || ...
                status.Type == statusMgr.StatusType.RunningCancellable);
        end

        function checkProgressDlg(obj)
            status = obj.Stack.CurrentStatus;
            if ~obj.isProgressDlgNeeded(status)
                obj.deleteProgressDlg();
            end
        end

        function checkIfCancelPressed(obj)

            if obj.hasValidProgressDlg() ...
                    && obj.ProgressDlg.CancelRequested
                stopTimer(obj.CancelTimer);
                status = obj.ProgressDlgStatus;
                status.complete();
                obj.Stack.removeStatus(status);
            end
        end
    end % methods

    methods (Static)

        function num = numberDialogues(stack)
            statusTypes = [stack.Statuses.Type];
            popupTypes = [statusMgr.StatusType.Error, statusMgr.StatusType.Warning, statusMgr.StatusType.Success];
            idx = ismember(statusTypes, popupTypes);
            num = sum(idx);
        end

    end

end % classdef

function stopTimer(timer)

try
    stop(timer);
    delete(timer)
catch
end

end
