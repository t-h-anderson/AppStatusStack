classdef tPopupView < matlab.uitest.TestCase

    properties
        Stack statusMgr.Stack
        PopupView statusMgr.view.Popup
        Figure matlab.ui.Figure
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.Stack = statusMgr.Stack();
            
            testCase.Figure = figure(Position=[1 1 796 479]);
            testCase.addTeardown(@delete, testCase.Figure);
            testCase.PopupView = statusMgr.view.Popup(testCase.Figure, testCase.Stack);
            testCase.addTeardown(@() delete(testCase.PopupView));
        end
    end

    methods (Test)

        function tDefaultValues(testCase)
            testCase.verifyTrue(testCase.PopupView.ShowWarnings)
            testCase.verifyTrue(testCase.PopupView.ShowErrors)
            testCase.verifyTrue(testCase.PopupView.ShowSuccess)
            testCase.verifyTrue(testCase.PopupView.ShowRunning)
            testCase.verifyFalse(testCase.PopupView.ShowIdle)
        end

        function tDismissNonBlockingError(testCase)
            % Dismiss the non-blocking error dialog and check the stack is
            % updated accordingly.
            testCase.Stack.addStatus("Error", Message="Example error");
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Error)

            % Dismiss the dialog that popped up.
            testCase.dismissDialog("uiconfirm", testCase.Figure)

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tDismissBlockingError(testCase)
            % Dismiss the blocking error dialog and check the stack is
            % updated accordingly.
            testCase.assumeFail("not working - review")
            fcn = @() testCase.Stack.addStatus("Error", Message="Example error", IsBlocking=true);

            testCase.dismissDialog("uiconfirm", testCase.Figure, fcn)

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tCleanupNonBlockingError(testCase)
            % Deleting the status's cleanup object should clear it from the
            % stack and dismiss the dialog.
            [~, cleanupObj] = testCase.Stack.addStatus("Error", Message="Example error"); %#ok<ASGLU>
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Error)

            clear cleanupObj
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
            testCase.verifyError(@() testCase.dismissDialog("uiconfirm", testCase.Figure), ...
                "MATLAB:uiautomation:Driver:NoConfirmationDialogsFound")
        end

        function tDismissMultipleStatuses(testCase)
            % Add multiple statuses in order and dismiss the dialogs one
            % by one.
            testCase.Stack.addStatus("Warning", Message="S1");
            testCase.Stack.addStatus("Error", Message="S2");
            testCase.Stack.addStatus("Warning", Message="S3");

            testCase.verifySize(testCase.Stack.Statuses, [1 4])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "S3")

            testCase.dismissDialog("uiconfirm", testCase.Figure)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "S2")

            testCase.dismissDialog("uiconfirm", testCase.Figure)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "S1")

            testCase.dismissDialog("uiconfirm", testCase.Figure)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tRemoveAllStatuses(testCase)
            % Calling removeAllStatuses should dismiss all dialogs.
            testCase.Stack.addStatus("Warning", Message="S1");
            testCase.Stack.addStatus("Error", Message="S2");

            testCase.Stack.removeAllStatuses();

            testCase.assertSize(testCase.Stack.Statuses, [1 1])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)

            testCase.verifyError(@() testCase.dismissDialog("uiconfirm", testCase.Figure), ...
                "MATLAB:uiautomation:Driver:NoConfirmationDialogsFound")
        end

        function tAddNonBlockingError(testCase)
            status = testCase.Stack.addError(MException("a:b:c", "test"), IsBlocking=false);
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Error)

            testCase.dismissDialog("uiconfirm", testCase.Figure)

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
            testCase.verifyTrue(status.IsComplete)
        end

        function tShowInfo(testCase)
            % Show an info message.
            testCase.Stack.addStatus("Info", Message="info1", Identifier="i1");

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Info)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "info1")
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Identifier, "i1")

            testCase.chooseDialog("uiconfirm", testCase.Figure, "OK")
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tUpdateStatusMessage(testCase)
            % Create an indeterminate progress dialog and update its
            % message.
            status = testCase.Stack.addStatus("Running", Message="message");
            
            pause(0.2)
            testCase.Stack.updateStatus(testCase.Stack.CurrentStatus, Message="new message");
            pause(0.5)

            testCase.verifyEqual(status.Message, "new message")
        end

        function tIndeterminateProgressDialog(testCase)
            status = testCase.Stack.addStatus("Running", Message="test");
            pause(0.5)

            testCase.verifyFalse(status.IsBlocking)
            testCase.verifyFalse(status.IsComplete)

            status.complete();

            testCase.verifyTrue(status.IsComplete)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tDeterminateProgressDialog(testCase)
            status = testCase.Stack.addStatus("Running", Message="test", Value=0.1);

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Value, 0.1)

            pause(0.2)
            testCase.Stack.updateStatus(testCase.Stack.CurrentStatus, Value=0.5);
            pause(0.5)

            testCase.verifyEqual(status.Value, 0.5)
        end

        function tCancelIndeterminateProgressDialog(testCase)
            status = testCase.Stack.addStatus("RunningCancellable", Message="test");

            pause(0.2)
            testCase.press(testCase.Figure, [520,205]) % click the Cancel button
            pause(0.2)

            testCase.verifyTrue(status.IsComplete)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tUpdateOldStatus(testCase)
            % Update the message of a status that is not at the top of the
            % stack. 
            status = testCase.Stack.addStatus("Success", Message="message 1");
            testCase.Stack.addStatus("Error", Message="message 2");

            testCase.Stack.updateStatus(status, Message="new message");

            testCase.verifyEqual(testCase.Stack.Statuses(2).Message, "new message")
            testCase.verifyEqual(testCase.Stack.Statuses(end).Message, "message 2")
        end 

        function tDismissOneGroupedDialog(testCase)
            % Automatically click "ok" when multiple dialogs have been
            % grouped. The dialog from the next status in the stack should
            % still appear.
            testCase.Stack.addStatus("Success", Message="message 1");
            testCase.Stack.addStatus("Error", Message="message 2");

            testCase.chooseDialog("uiconfirm", testCase.Figure, "OK")

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "message 1")

            testCase.chooseDialog("uiconfirm", testCase.Figure, "OK")

            testCase.assertSize(testCase.Stack.Statuses, [1 1])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tCloseAllDialogs(testCase)
            % Click on "Close All" when multiple dialogs are grouped. They
            % should all be dismissed.
            testCase.Stack.addStatus("Success", Message="message 1");
            testCase.Stack.addStatus("Error", Message="message 2");

            testCase.chooseDialog("uiconfirm", testCase.Figure, "Close All")

            testCase.assertSize(testCase.Stack.Statuses, [1 1])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tRunCommandWithError(testCase)
            % Running a command that errors should result in a blocking
            % dialog.
            testCase.assumeFail("not working - review")
            fcn = @() testCase.Stack.run(@() error("test"));

            testCase.dismissDialog("uiconfirm", testCase.Figure, fcn)
        end

        function tTemporaryStatus(testCase)
            % Marking a status as temporary will result in it being
            % automatically removed once a new status is pushed.
            testCase.Stack.addStatus("Warning", Message="message 1", IsTemporary=true);
            testCase.Stack.addStatus("Warning", Message="message 2", IsTemporary=true);
            testCase.Stack.addStatus("Warning", Message="message 3", IsTemporary=true);

            testCase.assertSize(testCase.Stack.Statuses, [1 2])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Warning)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "message 3")
            testCase.verifyTrue(testCase.Stack.CurrentStatus.IsTemporary)
            testCase.verifyEqual(testCase.Stack.Statuses(1).Type, statusMgr.StatusType.Idle)
        end

        function tMultipleStacks(testCase)
            % Create a second stack and a second popup view. Both stacks
            % can push statuses to the same figure.
            testCase.Stack.addStatus("Warning", Message="warning");
            newStack = statusMgr.Stack();
            statusMgr.view.Popup(testCase.Figure, newStack);

            stackArray = [testCase.Stack, newStack];
            stackArray.addStatus("Error", Message="error");

            testCase.assertSize(testCase.Stack.Statuses, [1 3])
            testCase.assertSize(newStack.Statuses, [1 2])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Error)
            testCase.verifyEqual(newStack.CurrentStatus.Type, statusMgr.StatusType.Error)
        end

        function tUpdateStatusInMultipleStacks(testCase)
            % Check the methods to update the value and message of a
            % status on an array of stacks on different figures.
            % Note this assumes that we're updating the same status in the
            % two stacks.
            testCase.Stack.addStatus("Warning", Message="warning");
            newStack = statusMgr.Stack();
            newFigure = figure();
            testCase.addTeardown(@delete, newFigure);
            statusMgr.view.Popup(newFigure, newStack);

            stackArray = [testCase.Stack, newStack];
            stackArray.addStatus("Running", Message="message 1", Value=0.1);

            pause(0.1)
            stackArray.updateStatus(testCase.Stack.CurrentStatus, Value=0.5, Message="new message");
            pause(0.1)

            testCase.assertSize(testCase.Stack.Statuses, [1 3])
            testCase.assertSize(newStack.Statuses, [1 2])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Type, statusMgr.StatusType.Running)
            testCase.verifyEqual(newStack.CurrentStatus.Type, statusMgr.StatusType.Running)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "new message")
            testCase.verifyEqual(newStack.CurrentStatus.Message, "new message")
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Value, 0.5)
            testCase.verifyEqual(newStack.CurrentStatus.Value, 0.5)
        end

        function tNonVisibileStatus(testCase)
            % Setting the status as non-visible makes it not appear as a
            % popup, even if IsBlocking is enabled.
            testCase.Stack.addStatus("Warning", IsVisible=false, IsBlocking=true);
            
            testCase.verifyError(@() testCase.dismissDialog("uiconfirm", testCase.Figure), ...
                "MATLAB:uiautomation:Driver:NoConfirmationDialogsFound")
        end

        function tDisableShowSuccess(testCase)
            % Creating a popup view with ShowSuccess disabled will prevent
            % success statuses dialogs from appearing.
            newstack = statusMgr.Stack();
            popupView = statusMgr.view.Popup(testCase.Figure, newstack, ShowSuccess=false);

            newstack.addStatus("Success");

            testCase.verifyFalse(popupView.ShowSuccess)
            testCase.verifyEqual(newstack.CurrentStatus.Type, statusMgr.StatusType.Success)
            testCase.verifyError(@() testCase.dismissDialog("uiconfirm", testCase.Figure), ...
                "MATLAB:uiautomation:Driver:NoConfirmationDialogsFound")
        end

        function tDeletedFigure(testCase)
            % A popup view that references a deleted figure does nothing.
            testCase.Figure.delete();
            testCase.Stack.addStatus("Warning");

            testCase.verifyFalse(testCase.PopupView.isVisible());
            testCase.verifyFalse(testCase.PopupView.HasPopup);
        end


    end
end

