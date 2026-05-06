classdef tStatusBar < matlab.uitest.TestCase

    properties
        Stack statusMgr.Stack
        Figure matlab.ui.Figure
        Bar statusMgr.view.StatusBar
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.Stack = statusMgr.Stack();
            testCase.Figure = uifigure("Position", [100 100 600 200]);
            testCase.addTeardown(@() delete(testCase.Figure));
            testCase.Bar = statusMgr.view.StatusBar(testCase.Figure, testCase.Stack);
            testCase.addTeardown(@() delete(testCase.Bar));
        end
    end

    methods (Test)

        function tConstructorBuildsLayout(testCase)
            testCase.assertClass(testCase.Bar.Layout, "matlab.ui.container.GridLayout")
            testCase.verifyTrue(isvalid(testCase.Bar.Layout))
            testCase.verifyTrue(testCase.Bar.isVisible())
        end

        function tInfoStatusUpdatesMessage(testCase)
            testCase.Stack.addStatus("Info", Message="hello");
            testCase.verifyEqual(string(testCase.Bar.MessageLabel.Text), "hello")
            testCase.verifyEqual(string(testCase.Bar.ProgressIndicator.Visible), "off")
            testCase.verifyEqual(string(testCase.Bar.CancelButton.Visible), "off")
            testCase.verifyEqual(string(testCase.Bar.OkButton.Visible), "off")
        end

        function tErrorStatusUsesErrorColor(testCase)
            testCase.Stack.addStatus("Error", Message="boom");
            testCase.verifyEqual(string(testCase.Bar.MessageLabel.Text), "boom")
            testCase.verifyEqual(testCase.Bar.MessageLabel.FontColor, ...
                testCase.Bar.ErrorColor)
        end

        function tWarningAndSuccessHaveDistinctColors(testCase)
            testCase.Stack.addStatus("Warning", Message="careful");
            warningColor = testCase.Bar.MessageLabel.FontColor;

            testCase.Stack.addStatus("Success", Message="done");
            successColor = testCase.Bar.MessageLabel.FontColor;

            testCase.verifyEqual(warningColor, testCase.Bar.WarningColor)
            testCase.verifyEqual(successColor, testCase.Bar.SuccessColor)
            testCase.verifyNotEqual(warningColor, successColor)
        end

        function tRunningShowsIndeterminateProgress(testCase)
            testCase.Stack.addStatus("Running", Message="loading");
            testCase.verifyEqual(string(testCase.Bar.ProgressIndicator.Visible), "on")
            testCase.verifyEqual(string(testCase.Bar.ProgressIndicator.Indeterminate), "on")
        end

        function tRunningWithValueShowsDeterminateProgress(testCase)
            testCase.Stack.addStatus("Running", Message="loading", Value=0.4);
            testCase.verifyEqual(string(testCase.Bar.ProgressIndicator.Visible), "on")
            testCase.verifyEqual(string(testCase.Bar.ProgressIndicator.Indeterminate), "off")
            testCase.verifyEqual(testCase.Bar.ProgressIndicator.Value, 0.4)
        end

        function tRunningCancellableShowsCancelButton(testCase)
            testCase.Stack.addStatus("RunningCancellable", Message="long task");
            testCase.verifyEqual(string(testCase.Bar.CancelButton.Visible), "on")
        end

        function tCancelButtonCompletesCurrentStatus(testCase)
            status = testCase.Stack.addStatus("RunningCancellable", Message="long task");
            testCase.assertFalse(status.IsComplete)
            testCase.assertEqual(string(testCase.Bar.CancelButton.Visible), "on")

            testCase.press(testCase.Bar.CancelButton);

            testCase.verifyTrue(status.IsComplete)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tErrorShowsOkButtonAndPopulatesPopout(testCase)
            % Error/Warning/Success show the OK button and populate
            % the click-triggered Popout with the full Message.
            testCase.Stack.addStatus("Error", ...
                Message="full error details here", ...
                MessageShort="oops");

            testCase.verifyEqual(string(testCase.Bar.MessageLabel.Text), "oops")
            testCase.verifyEqual(string(testCase.Bar.OkButton.Visible), "on")
            testCase.verifyEqual(string(testCase.Bar.PopoutLabel.Text), ...
                "full error details here")
            testCase.verifyEqual(string(testCase.Bar.Popout.Trigger), "click")
        end

        function tWarningShowsOkButton(testCase)
            testCase.Stack.addStatus("Warning", Message="be careful");
            testCase.verifyEqual(string(testCase.Bar.OkButton.Visible), "on")
        end

        function tSuccessShowsOkButton(testCase)
            testCase.Stack.addStatus("Success", Message="all done");
            testCase.verifyEqual(string(testCase.Bar.OkButton.Visible), "on")
        end

        function tOkButtonClearsTheStatus(testCase)
            % Clicking OK completes the status, removing it from the
            % stack and reverting to the previous state (Idle here).
            status = testCase.Stack.addStatus("Error", Message="boom");
            testCase.assertFalse(status.IsComplete)
            testCase.assertEqual(string(testCase.Bar.OkButton.Visible), "on")

            testCase.press(testCase.Bar.OkButton);

            testCase.verifyTrue(status.IsComplete)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tPopoutTriggerIsManualForNonAlertTypes(testCase)
            % Info / Running / Idle disarm the click trigger so
            % clicking the message label has no effect.
            testCase.Stack.addStatus("Info", Message="just info");
            testCase.verifyEqual(string(testCase.Bar.Popout.Trigger), "manual")

            testCase.Stack.addStatus("Running", Message="working");
            testCase.verifyEqual(string(testCase.Bar.Popout.Trigger), "manual")
        end

        function tIdleClearsTheBar(testCase)
            testCase.Stack.addStatus("Info", Message="something");
            testCase.assertEqual(string(testCase.Bar.MessageLabel.Text), "something")

            testCase.Stack.removeAllStatuses();

            testCase.verifyEqual(string(testCase.Bar.MessageLabel.Text), "")
        end

        function tDoesNotClaimRequestingInput(testCase)
            % The bar shows the prompt but does not transition to
            % AwaitingInput, so requestInput times out and falls back
            % to the default. Use a short Timeout so the test is fast.
            value = testCase.Stack.requestInput("Enter your name", ...
                DefaultValue="anonymous", Timeout=0.1);

            testCase.verifyEqual(value, "anonymous")
        end

        function tDeleteRemovesLayout(testCase)
            bar = statusMgr.view.StatusBar(testCase.Figure, testCase.Stack);
            layout = bar.Layout;

            delete(bar);

            testCase.verifyFalse(isvalid(layout))
        end

    end

end
