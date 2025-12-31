classdef tCommandWindow < matlab.uitest.TestCase

    properties
        Stack appStatus.stack.StatusStack
        CommandWindowView appStatus.view.CommandWindow
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.Stack = appStatus.stack.StatusStack();
            testCase.CommandWindowView = appStatus.view.CommandWindow(testCase.Stack);
            testCase.addTeardown(@() delete(testCase.CommandWindowView))
        end
    end

    methods (Test)

        function tDefaultValues(testCase)
            testCase.verifyTrue(testCase.CommandWindowView.ShowWarnings)
            testCase.verifyTrue(testCase.CommandWindowView.ShowErrors)
            testCase.verifyTrue(testCase.CommandWindowView.ShowSuccess)
            testCase.verifyTrue(testCase.CommandWindowView.ShowRunning)
            testCase.verifyFalse(testCase.CommandWindowView.ShowIdle)
        end

        function tDisplaySuccess(testCase)
            testCase.Stack.addCondition("Success", Message="s1");
            testCase.verifyEqual(testCase.CommandWindowView.PreviousMessage, "s1");
        end

        function tDisplayRunning(testCase)
            status = testCase.Stack.addCondition("Running", Message="r1");
            pause(0.5)

            testCase.verifyEqual(testCase.CommandWindowView.RunningTimer.Running, 'on')
            testCase.verifyEqual(testCase.CommandWindowView.PreviousMessage, "r1");

            testCase.Stack.CurrentStatus.complete()
            pause(0.5)

            testCase.verifyTrue(status.IsComplete)
            testCase.verifyFalse(isvalid(testCase.CommandWindowView.RunningTimer))
        end
        
        function tDisplayWarning(testCase)
            fcn = @() testCase.Stack.addCondition("Warning", Message="w1");
            testCase.verifyWarning(fcn, "")
        end

        function tDisplayError(testCase)
            testCase.assumeFail("To review behaviour")
            testCase.Stack.addError(MException("a:b:c", "test"));
        end

        function tDisplayMultipleErrors(testCase)
            testCase.assumeFail("To review behaviour - bug")
        end

        function tDisplayIdle(testCase)
            % Idle status is not displayed by default.
            testCase.Stack.addCondition("Idle", Message="idle 1");
            testCase.verifyTrue(ismissing(testCase.CommandWindowView.PreviousMessage))

            newview = appStatus.view.CommandWindow(testCase.Stack, ShowIdle=true);
            testCase.Stack.addCondition("Idle", Message="idle 2");
            testCase.verifyEqual(newview.PreviousMessage, "idle 2");
        end

        function tUpdateMessageAndValue(testCase)
            status = testCase.Stack.addCondition("Running", Message="r1", Value=1);

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "r1")
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Value, 1)

            testCase.Stack.updateStatusMessage("r2", status);
            testCase.Stack.updateStatusValue(2, status);

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "r2")
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Value, 2)
        end

    end
end

