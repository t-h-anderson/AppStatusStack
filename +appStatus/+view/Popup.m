classdef Popup < appStatus.internal.view.StatusViewInterface
    %StatusVIEW View a status Stack

    properties
        Parent % Graphics object
    end

    properties (SetAccess = protected)
        StatusStack = appStatus.stack.StatusStack.empty(1,0)
        StatusStackListener 
        CancelListener event.listener
        CancelTimer % Due to know bug - see below
    end

    properties (SetAccess = protected)
        ProgressDlg matlab.ui.dialog.ProgressDialog
        ProgressDlgStatus (1,:) appStatus.Status

        BlockingDialogues (1,1) logical = true

        HasPopup (1,1) logical = false
        PopupStatusToKeep (1,:) appStatus.Status = appStatus.Status
    end

    properties (Dependent)
        Figure
    end

    methods

        function obj = Popup(parent, statusStack, nvp)
            arguments
                parent = uifigure
                statusStack (1,1) appStatus.internal.stack.StatusStackInterface = appStatus.stack.StatusStack
                nvp.BlockingDialogues (1,1) logical = true
                nvp.ShowWarnings (1,1) logical = true
                nvp.ShowErrors (1,1) logical = true
                nvp.ShowRunning (1,1) logical = true
                nvp.ShowSuccess (1,1) logical = true
                nvp.ShowIdle (1,1) logical = false
            end

            % Set view parent and stack properties
            obj.Parent = parent;
            obj.BlockingDialogues = nvp.BlockingDialogues;

            % Add listener to stack
            obj.setStack(statusStack);

            obj.standardDisplay();

        end

        function tf = isVisible(obj)
            tf = ~isempty(obj.Figure) && isvalid(obj.Figure) && obj.Figure.Visible == "on";
        end

        function value = get.Figure(obj)
            % Get the handle for the parent's figure
            value = ancestor(obj.Parent, "figure");
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
                status appStatus.Status
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

        function displayIdle(obj, varargin)
            % Do nothing
        end

    end

    methods (Access = protected)

        function popupAlert(obj, status, title, icon)
            % popupAlert displays a popup in the main window

            arguments
                obj
                status appStatus.Status
                title (1,1) string = "Error"
                icon (1,1) string = "error"
            end % arguments

            if status.IsVisible && obj.BlockingDialogues

                % Display the alert
                if isvalid(obj.Figure)

                    % First time showing the status, so increment the
                    % counter
                    numPopups = obj.numberDialogues(obj.StatusStack);
                    
                    removeStatusFn = @(src, event) obj.completeIfClicked(src, event, status);
                    
                    if numPopups == 1
                        options = "OK";
                    else
                        options = ["Close All", "OK"];
                    end

                    uiconfirm(obj.Figure, ...
                        status.Message, ...
                        title, ...
                        "Options", options, ...
                        "Icon", icon, ...
                        "CloseFcn", removeStatusFn);

                    obj.HasPopup = true;

                end

                while status.IsBlocking && stack.CurrentStatus == status
                    % Wait till user clicks ok
                    drawnow
                end
            end


        end % popupAlert

        function clearPreviousAlert(obj, f)
            % Should only ever have one uialert
            if obj.HasPopup
                tt = matlab.uitest.TestCase.forInteractiveUse;
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
                        obj.StatusStack.clear();
                end
            end
        end
    end
    % progress dlg
    methods (Access = protected)
        function deleteProgressDlg(obj)
            delete(obj.ProgressDlg);
            delete(obj.CancelListener);
        end

        function createProgressDlg(obj)

            if ~obj.hasValidProgressDlg()
                % No progress dlg, so create
                defaultProps = struct("Title", "Running");
                defaultProps = namedargs2cell(defaultProps);
                obj.ProgressDlg = uiprogressdlg(obj.Figure, 'Indeterminate','on', defaultProps{:});
                
                % This doesn't work - Known bug https://komodo.mathworks.com/main/gecko/view?Record=2984852
                % obj.CancelListener = addlistener(obj.ProgressDlg, "CancelRequested", "PostSet", @(src, event) obj.notifyStackOfCancel());
                stopTimer(obj.CancelTimer);
                warning("off", "MATLAB:timer:deleterunning");
                obj.CancelTimer = timer("TimerFcn", @(~,~)obj.checkIfCancelPressed(), "Period", 1, "TasksToExecute", inf, "ExecutionMode", "fixedSpacing");
                obj.CancelTimer.start();

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
            tf = (status.Condition == appStatus.Condition.Running || ...
                status.Condition == appStatus.Condition.RunningCancellable);
        end

        function checkProgressDlg(obj)
            status = obj.StatusStack.CurrentStatus;
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
                obj.StatusStack.removeStatus(status);
            end
        end
    end % methods

    methods (Static)

        function num = numberDialogues(stack)
            conditions = [stack.Statuses.Condition];
            popupConditions = [appStatus.Condition.Error, appStatus.Condition.Warning, appStatus.Condition.Success];
            idx = ismember(conditions, popupConditions);
            num = sum(idx);
        end

    end

end % classdef

function stopTimer(timer)

try
    stop(timer);
    delete(dimer)
catch
end

end
