classdef tPopupView < matlab.uitest.TestCase

    properties
        Stack appStatus.stack.StatusStack
        PopupView appStatus.view.Popup
        Figure matlab.ui.Figure
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.Stack = appStatus.stack.StatusStack();
            
            testCase.Figure = figure();
            testCase.addTeardown(@delete, testCase.Figure);
            testCase.PopupView = appStatus.view.Popup(testCase.Figure, testCase.Stack);
            % matlab.uitest.unlock(testCase.Figure);
        end
    end

    methods (Test)

        function tDismissNonBlockingError(testCase)
            % Dismiss the non-blocking error dialog and check the stack is
            % updated accordingly.
            testCase.Stack.addCondition(appStatus.Condition.Error, ...
                Message="Example error");
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Error)

            % Dismiss the dialog that popped up.
            testCase.dismissDialog("uiconfirm", testCase.Figure)

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tDismissBlockingError(testCase)
            % Dismiss the blocking error dialog and check the stack is
            % updated accordingly.
            testCase.assumeFail("not working - review")
            fcn = @() testCase.Stack.addCondition(appStatus.Condition.Error, ...
                Message="Example error", IsBlocking=true);

            testCase.dismissDialog("uiconfirm", testCase.Figure, fcn)

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tCleanupNonBlockingError(testCase)
            % Deleting the status's cleanup object should clear it from the
            % stack and dismiss the dialog.
            [~, cleanupObj] = testCase.Stack.addCondition(appStatus.Condition.Error, ...
                Message="Example error"); %#ok<ASGLU>
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Error)

            clear cleanupObj
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Idle)
            testCase.verifyError(@() testCase.dismissDialog("uiconfirm", testCase.Figure), ...
                "MATLAB:uiautomation:Driver:NoConfirmationDialogsFound")
        end

        function tDismissMultipleConditions(testCase)
            % Add multiple conditions in order and dismiss the dialogs one
            % by one.
            testCase.Stack.addCondition(appStatus.Condition.Warning, ...
                Message="S1");
            testCase.Stack.addCondition(appStatus.Condition.Error, ...
                Message="S2");
            testCase.Stack.addCondition(appStatus.Condition.Warning, ...
                Message="S3");

            testCase.verifySize(testCase.Stack.Statuses, [1 4])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "S3")

            testCase.dismissDialog("uiconfirm", testCase.Figure)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "S2")

            testCase.dismissDialog("uiconfirm", testCase.Figure)
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "S1")

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tRemoveAllStatuses(testCase)
            % Calling removeAllStatuses should dismiss all dialogs.
            testCase.Stack.addCondition(appStatus.Condition.Warning, ...
                Message="S1");
            testCase.Stack.addCondition(appStatus.Condition.Error, ...
                Message="S2");

            testCase.Stack.removeAllStatuses();

            testCase.assertSize(testCase.Stack.Statuses, [1 1])
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Idle)

            testCase.verifyError(@() testCase.dismissDialog("uiconfirm", testCase.Figure), ...
                "MATLAB:uiautomation:Driver:NoConfirmationDialogsFound")
        end

        function tAddNonBlockingError(testCase)
            status = testCase.Stack.addError(MException("a:b:c", "test"), IsBlocking=false);
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Error)

            testCase.dismissDialog("uiconfirm", testCase.Figure)

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Condition, appStatus.Condition.Idle)
            testCase.verifyTrue(status.IsComplete)
        end

        function tIndeterminateProgressDialog(testCase)

        end

        function tDeterminateProgressDialog(testCase)

        end

    end
end

