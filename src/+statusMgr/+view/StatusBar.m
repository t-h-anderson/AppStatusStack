classdef StatusBar < statusMgr.internal.view.StatusViewBase
    %STATUSBAR Inline non-modal status view rendered in a figure container.
    %
    % Renders the current status as a thin bar with:
    %   * A message label (colour-coded by status type) showing
    %     status.MessageShort. Clicking the label opens a Popout with
    %     the full status.Message for Error / Warning / Success types.
    %   * A linear progress indicator (visible only for Running statuses)
    %   * A Cancel button (visible only for RunningCancellable statuses)
    %   * An OK button (visible only for Error / Warning / Success
    %     statuses) that completes the status — i.e. dismisses the
    %     alert by removing it from the stack.
    %
    % Unlike Popup, no modal dialogs appear — every update happens
    % inline so user code can keep interacting with the rest of the UI.
    %
    % The bar's top-level child of `parent` is a uigridlayout, which
    % auto-resizes when its parent does (uipanel does not, which is a
    % long-standing MATLAB limitation). For a "bar at the bottom of a
    % figure" layout, give StatusBar a parent that's already sized to
    % the bar's footprint — typically a row in your own outer
    % uigridlayout:
    %
    %   fig = uifigure;
    %   outer = uigridlayout(fig, [2, 1], "RowHeight", {"1x", 28});
    %   mainContent = uipanel(outer);   % goes in row 1
    %   stack = statusMgr.Stack();
    %   bar = statusMgr.view.StatusBar(outer, stack);  % goes in row 2
    %
    % Pass any uifigure / uipanel / uigridlayout cell as the parent.
    %
    % Implementation note: the linear progress indicator and the
    % popout container are matlab.ui.control.internal.ProgressIndicator
    % and matlab.ui.container.internal.Popout — both are internal
    % Mathworks APIs. They work in current MATLAB releases but may
    % move or change without notice.

    properties (SetAccess = protected)
        Parent
        Layout matlab.ui.container.GridLayout = matlab.ui.container.GridLayout.empty(1,0)
        MessageLabel matlab.ui.control.Label = matlab.ui.control.Label.empty(1,0)
        ProgressIndicator = []  % matlab.ui.control.internal.ProgressIndicator
        CancelButton matlab.ui.control.Button = matlab.ui.control.Button.empty(1,0)
        DetailsButton matlab.ui.control.Button = matlab.ui.control.Button.empty(1,0)
        OkButton matlab.ui.control.Button = matlab.ui.control.Button.empty(1,0)
        Popout = []           % matlab.ui.container.internal.Popout
        PopoutLabel matlab.ui.control.Label = matlab.ui.control.Label.empty(1,0)
    end

    properties
        InfoColor (1,3) double = [0 0 0]
        WarningColor (1,3) double = [0.85 0.5 0]
        ErrorColor (1,3) double = [0.78 0 0]
        SuccessColor (1,3) double = [0 0.55 0]
        % Width and height of the details Popout, in pixels.
        PopoutSize (1,2) double {mustBePositive} = [400 200]
    end

    methods

        function obj = StatusBar(parent, stack, nvp)
            arguments
                parent = uifigure
                stack (1,1) statusMgr.internal.StackInterface = statusMgr.Stack
                nvp.InfoColor (1,3) double = [0 0 0]
                nvp.WarningColor (1,3) double = [0.85 0.5 0]
                nvp.ErrorColor (1,3) double = [0.78 0 0]
                nvp.SuccessColor (1,3) double = [0 0.55 0]
                nvp.PopoutSize (1,2) double {mustBePositive} = [400 200]
                nvp.ShowInfo (1,1) logical = true
                nvp.ShowWarnings (1,1) logical = true
                nvp.ShowErrors (1,1) logical = true
                nvp.ShowRunning (1,1) logical = true
                nvp.ShowSuccess (1,1) logical = true
                nvp.ShowIdle (1,1) logical = true   % default true: clears the bar
                % HandleInputRequests=true means the bar will display
                % the prompt; the override only updates the label, it
                % does not transition the status, so a claim-capable
                % view (Popup, CommandWindow) can still claim.
                nvp.HandleInputRequests (1,1) logical = true
                nvp.IncludeIdentifiers (1,:) string = string.empty(1,0)
                nvp.ExcludeIdentifiers (1,:) string = string.empty(1,0)
            end

            obj.Parent = parent;
            set(obj, nvp);
            obj.buildUI();
            obj.setStack(stack);
            obj.standardDisplay();
        end

        function tf = isVisible(obj)
            tf = ~isempty(obj.Layout) && isvalid(obj.Layout);
        end

        function delete(obj)
            delete(obj.Popout);
            delete(obj.Layout);
        end

    end

    methods (Access = protected)

        function buildUI(obj)
            % uigridlayout auto-resizes with its parent — that's why
            % we use it as the top-level child rather than a uipanel.
            % Columns: message (flex), progress, cancel, details, ok.
            obj.Layout = uigridlayout(obj.Parent, [1, 5], ...
                "ColumnWidth", {"1x", 0, 0, 0, 0}, ...
                "Padding", [6, 2, 6, 2], ...
                "ColumnSpacing", 6, ...
                "RowHeight", {"1x"});

            obj.MessageLabel = uilabel(obj.Layout, "Text", "");
            obj.MessageLabel.Layout.Column = 1;

            obj.ProgressIndicator = matlab.ui.control.internal.ProgressIndicator( ...
                "Parent", obj.Layout, ...
                "Visible", "off");
            obj.ProgressIndicator.Layout.Column = 2;

            obj.CancelButton = uibutton(obj.Layout, ...
                "Text", "Cancel", ...
                "Visible", "off", ...
                "ButtonPushedFcn", @(~,~) obj.onCancelClicked());
            obj.CancelButton.Layout.Column = 3;

            % Details button: small, opens/closes the Popout that
            % shows the full status.Message. Visible only when the
            % current status has details worth showing (Error /
            % Warning / Success). The button drives the Popout via
            % an explicit toggle callback rather than Popout's own
            % Trigger="click" mechanism — that way the test suite
            % (and any programmatic driver) can drive the open/close
            % via standard ButtonPushedFcn semantics.
            obj.DetailsButton = uibutton(obj.Layout, ...
                "Text", "...", ...
                "Visible", "off", ...
                "ButtonPushedFcn", @(~,~) obj.toggleDetailsPopout());
            obj.DetailsButton.Layout.Column = 4;

            obj.OkButton = uibutton(obj.Layout, ...
                "Text", "OK", ...
                "Visible", "off", ...
                "ButtonPushedFcn", @(~,~) obj.onOkClicked());
            obj.OkButton.Layout.Column = 5;

            % Popout for showing the full status.Message. Anchored to
            % the Details button. Trigger="manual" because the button's
            % ButtonPushedFcn opens/closes it explicitly. An explicit
            % Position is required: without it the popout's preferred
            % size depends on its content at construction time (empty
            % here) and ends up too small for typical error reports.
            obj.Popout = matlab.ui.container.internal.Popout( ...
                "Target", obj.DetailsButton, ...
                "Trigger", "manual", ...
                "Placement", "auto", ...
                "Position", [0, 0, obj.PopoutSize(1), obj.PopoutSize(2)]);
            popoutGrid = uigridlayout(obj.Popout, [1, 1], ...
                "Padding", [8, 8, 8, 8]);
            obj.PopoutLabel = uilabel(popoutGrid, ...
                "Text", "", ...
                "WordWrap", "on");
        end

        function toggleDetailsPopout(obj)
            % Open the popout if closed; close it if open. Wired to
            % the Details button's ButtonPushedFcn so a single click
            % flips the state.
            if isempty(obj.Popout) || ~isvalid(obj.Popout)
                return
            end
            if obj.Popout.IsOpen
                obj.Popout.close();
            else
                obj.Popout.open();
            end
        end

        function onCancelClicked(obj)
            % The most recent visible status is what the bar is showing;
            % completing it signals cancel to runCancellable's user code.
            s = obj.IncomingStatus;
            if isvalid(s) && ~s.IsComplete
                s.complete();
            end
        end

        function onOkClicked(obj)
            % Acknowledge an error/warning/success — completes the
            % status and removes it from the stack.
            s = obj.IncomingStatus;
            if isvalid(s) && ~s.IsComplete
                s.complete();
            end
        end

        function present(obj, message, color, progressVisible, progressValue, cancelVisible, okVisible, popoutText)
            % The listener on the Stack can fire after the bar's UI
            % has been torn down (e.g. parent figure closed, or a
            % stale instance). Guard against half-constructed /
            % half-destroyed state up front so a single dangling
            % listener doesn't error out the addStatus call.
            if ~obj.uiHandlesValid()
                return
            end
            obj.MessageLabel.Text = message;
            obj.MessageLabel.FontColor = color;
            obj.setProgress(progressVisible, progressValue);
            obj.setCancelVisible(cancelVisible);
            obj.setDetails(popoutText);
            obj.setOkVisible(okVisible);
        end

        function tf = uiHandlesValid(obj)
            tf = ~isempty(obj.MessageLabel) && isvalid(obj.MessageLabel) ...
                && ~isempty(obj.ProgressIndicator) && isvalid(obj.ProgressIndicator) ...
                && ~isempty(obj.CancelButton) && isvalid(obj.CancelButton) ...
                && ~isempty(obj.DetailsButton) && isvalid(obj.DetailsButton) ...
                && ~isempty(obj.OkButton) && isvalid(obj.OkButton) ...
                && ~isempty(obj.Popout) && isvalid(obj.Popout) ...
                && ~isempty(obj.PopoutLabel) && isvalid(obj.PopoutLabel);
        end

        function setProgress(obj, visible, value)
            if ~visible
                obj.ProgressIndicator.Visible = "off";
                obj.Layout.ColumnWidth{2} = 0;
                return
            end
            obj.ProgressIndicator.Visible = "on";
            obj.Layout.ColumnWidth{2} = 100;
            if isnan(value)
                obj.ProgressIndicator.Indeterminate = "on";
            else
                obj.ProgressIndicator.Indeterminate = "off";
                obj.ProgressIndicator.Value = value;
            end
        end

        function setCancelVisible(obj, visible)
            if visible
                obj.CancelButton.Visible = "on";
                obj.Layout.ColumnWidth{3} = 70;
            else
                obj.CancelButton.Visible = "off";
                obj.Layout.ColumnWidth{3} = 0;
            end
        end

        function setOkVisible(obj, visible)
            if visible
                obj.OkButton.Visible = "on";
                obj.Layout.ColumnWidth{5} = 50;
            else
                obj.OkButton.Visible = "off";
                obj.Layout.ColumnWidth{5} = 0;
            end
        end

        function setDetails(obj, text)
            % Show the Details button (and populate the popout) when
            % there's full text to show. Hiding the button removes
            % the only way to open the popout from the UI; if the
            % popout was open we close it explicitly so it doesn't
            % linger after the alert is gone.
            obj.PopoutLabel.Text = text;
            if text == ""
                obj.DetailsButton.Visible = "off";
                obj.Layout.ColumnWidth{4} = 0;
                if obj.Popout.IsOpen
                    obj.Popout.close();
                end
            else
                obj.DetailsButton.Visible = "on";
                obj.Layout.ColumnWidth{4} = 30;
            end
        end

        function displayInfo(obj, status)
            obj.present(status.Message, obj.InfoColor, false, NaN, false, false, "");
        end

        function displayRunning(obj, status, cancellable)
            obj.present(status.Message, obj.InfoColor, true, status.Value, cancellable, false, "");
        end

        function displayError(obj, status)
            obj.present(status.MessageShort, obj.ErrorColor, false, NaN, false, true, status.Message);
        end

        function displayWarning(obj, status)
            obj.present(status.MessageShort, obj.WarningColor, false, NaN, false, true, status.Message);
        end

        function displaySuccess(obj, status)
            obj.present(status.MessageShort, obj.SuccessColor, false, NaN, false, true, status.Message);
        end

        function displayIdle(obj, ~)
            obj.present("", obj.InfoColor, false, NaN, false, false, "");
        end

        function handleInputRequest(obj, status)
            % Don't claim — just show the prompt. A claim-capable view
            % attached to the same stack (Popup, CommandWindow) will
            % do the actual input collection.
            obj.present(status.Message, obj.InfoColor, false, NaN, false, false, "");
        end

    end

end
