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
            testCase.verifyEqual(string(testCase.Bar.DetailsButton.Visible), "off")
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

        function tErrorShowsDetailsAndOkButtonsAndPopulatesPopout(testCase)
            % Error/Warning/Success show the Details button (which
            % toggles the Popout) and the OK button (which dismisses
            % the alert). The Popout content is populated with the
            % full Message.
            testCase.Stack.addStatus("Error", ...
                Message="full error details here", ...
                MessageShort="oops");

            testCase.verifyEqual(string(testCase.Bar.MessageLabel.Text), "oops")
            testCase.verifyEqual(string(testCase.Bar.DetailsButton.Visible), "on")
            testCase.verifyEqual(string(testCase.Bar.OkButton.Visible), "on")
            testCase.verifyEqual(string(testCase.Bar.PopoutLabel.Text), ...
                "full error details here")
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

        function tDetailsButtonHiddenForNonAlertTypes(testCase)
            % Info / Running don't have Details to show, so the
            % button is hidden — the popout has no UI affordance to
            % open it.
            testCase.Stack.addStatus("Info", Message="just info");
            testCase.verifyEqual(string(testCase.Bar.DetailsButton.Visible), "off")

            testCase.Stack.addStatus("Running", Message="working");
            testCase.verifyEqual(string(testCase.Bar.DetailsButton.Visible), "off")
        end

        function tPopoutHasExplicitSize(testCase)
            % The popout has an explicit Position so its size is
            % predictable regardless of content. Default is 400x200;
            % constructor accepts a PopoutSize override.
            testCase.verifyEqual(testCase.Bar.Popout.Position(3:4), [400 200])

            customBar = statusMgr.view.StatusBar(uifigure(), testCase.Stack, ...
                PopoutSize=[600 300]);
            testCase.addTeardown(@() delete(customBar.Parent));
            testCase.addTeardown(@() delete(customBar));
            testCase.verifyEqual(customBar.Popout.Position(3:4), [600 300])
        end

        function tDismissingAlertClosesOpenPopout(testCase)
            % If the user opened the popout and then clicks OK to
            % dismiss the alert, the popout shouldn't linger after
            % the alert it was describing is gone.
            testCase.Stack.addStatus("Error", Message="boom");
            testCase.Bar.Popout.open();
            testCase.assertTrue(testCase.Bar.Popout.IsOpen)

            testCase.press(testCase.Bar.OkButton);

            testCase.verifyFalse(testCase.Bar.Popout.IsOpen)
        end

        function tDetailsButtonTogglesPopout(testCase)
            % First click of the Details button opens the popout;
            % second click closes it.
            testCase.Stack.addStatus("Error", ...
                Message="long detail text", MessageShort="short");

            testCase.assertFalse(testCase.Bar.Popout.IsOpen)
            testCase.press(testCase.Bar.DetailsButton);
            testCase.verifyTrue(testCase.Bar.Popout.IsOpen)

            testCase.press(testCase.Bar.DetailsButton);
            testCase.verifyFalse(testCase.Bar.Popout.IsOpen)
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
