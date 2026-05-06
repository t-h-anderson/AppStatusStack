classdef StatusBar < statusMgr.internal.view.StatusViewBase
    %STATUSBAR Inline non-modal status view rendered in a figure container.
    %
    % Renders the current status as a thin bar with:
    %   * A message label (colour-coded by status type)
    %   * A linear progress indicator (visible only for Running statuses)
    %   * A Cancel button (visible only for RunningCancellable statuses)
    %
    % Unlike Popup, no modal dialogs appear — every update happens
    % inline so user code can keep interacting with the rest of the UI.
    %
    % Usage:
    %
    %   fig = uifigure;
    %   stack = statusMgr.Stack();
    %   bar = statusMgr.view.StatusBar(fig, stack);
    %   stack.addStatus("Info", Message="Ready");
    %   stack.run(@() pause(2));     % shows running progress in the bar
    %
    % If the parent is a uifigure the bar pins itself to the bottom and
    % follows the figure's width on resize. Otherwise it fills its
    % parent (caller is responsible for positioning, e.g. by adding it
    % to a uigridlayout cell).
    %
    % Implementation note: the linear progress indicator is built on
    % matlab.ui.control.internal.ProgressIndicator, which is an
    % internal Mathworks API. It works in current MATLAB releases but
    % may move or change without notice.

    properties (SetAccess = protected)
        Parent
        Panel matlab.ui.container.Panel = matlab.ui.container.Panel.empty(1,0)
        Layout matlab.ui.container.GridLayout = matlab.ui.container.GridLayout.empty(1,0)
        MessageLabel matlab.ui.control.Label = matlab.ui.control.Label.empty(1,0)
        ProgressIndicator = []  % matlab.ui.control.internal.ProgressIndicator
        CancelButton matlab.ui.control.Button = matlab.ui.control.Button.empty(1,0)
        FigureSizeListener event.listener = event.listener.empty(1,0)
    end

    properties
        Height (1,1) double {mustBePositive} = 28
        InfoColor (1,3) double = [0 0 0]
        WarningColor (1,3) double = [0.85 0.5 0]
        ErrorColor (1,3) double = [0.78 0 0]
        SuccessColor (1,3) double = [0 0.55 0]
    end

    methods

        function obj = StatusBar(parent, stack, nvp)
            arguments
                parent = uifigure
                stack (1,1) statusMgr.internal.StackInterface = statusMgr.Stack
                nvp.Height (1,1) double {mustBePositive} = 28
                nvp.InfoColor (1,3) double = [0 0 0]
                nvp.WarningColor (1,3) double = [0.85 0.5 0]
                nvp.ErrorColor (1,3) double = [0.78 0 0]
                nvp.SuccessColor (1,3) double = [0 0.55 0]
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
            tf = ~isempty(obj.Panel) && isvalid(obj.Panel);
        end

        function delete(obj)
            delete(obj.FigureSizeListener);
            delete(obj.Panel);
        end

    end

    methods (Access = protected)

        function buildUI(obj)
            obj.Panel = uipanel(obj.Parent, ...
                "BorderType", "line", ...
                "Title", "");

            % Pin to the bottom of a parent figure; otherwise let the
            % caller's layout decide where the panel sits.
            if isa(obj.Parent, "matlab.ui.Figure")
                fig = obj.Parent;
                obj.Panel.Units = "pixels";
                obj.Panel.Position = [1, 1, fig.Position(3), obj.Height];
                obj.FigureSizeListener = listener(fig, "SizeChanged", ...
                    @(~,~) obj.onParentResized());
            end

            obj.Layout = uigridlayout(obj.Panel, [1, 3], ...
                "ColumnWidth", {"1x", 0, 0}, ...
                "Padding", [6, 2, 6, 2], ...
                "ColumnSpacing", 6, ...
                "RowHeight", {"fit"});

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
        end

        function onParentResized(obj)
            if isvalid(obj.Panel) && isa(obj.Parent, "matlab.ui.Figure")
                obj.Panel.Position = [1, 1, obj.Parent.Position(3), obj.Height];
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

        function present(obj, message, color, progressVisible, progressValue, cancelVisible)
            obj.MessageLabel.Text = message;
            obj.MessageLabel.FontColor = color;
            obj.setProgress(progressVisible, progressValue);
            obj.setCancelVisible(cancelVisible);
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

        function displayInfo(obj, status)
            obj.present(status.Message, obj.InfoColor, false, NaN, false);
        end

        function displayRunning(obj, status, cancellable)
            obj.present(status.Message, obj.InfoColor, true, status.Value, cancellable);
        end

        function displayError(obj, status)
            obj.present(status.MessageShort, obj.ErrorColor, false, NaN, false);
        end

        function displayWarning(obj, status)
            obj.present(status.MessageShort, obj.WarningColor, false, NaN, false);
        end

        function displaySuccess(obj, status)
            obj.present(status.MessageShort, obj.SuccessColor, false, NaN, false);
        end

        function displayIdle(obj, ~)
            obj.present("", obj.InfoColor, false, NaN, false);
        end

        function handleInputRequest(obj, status)
            % Don't claim — just show the prompt. A claim-capable view
            % attached to the same stack (Popup, CommandWindow) will
            % do the actual input collection.
            obj.present(status.Message, obj.InfoColor, false, NaN, false);
        end

    end

end
