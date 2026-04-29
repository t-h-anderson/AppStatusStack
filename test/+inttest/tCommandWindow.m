classdef tCommandWindow < matlab.uitest.TestCase

    properties
        Stack statusMgr.Stack
        CommandWindowView statusMgr.view.CommandWindow
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.Stack = statusMgr.Stack();
            testCase.CommandWindowView = statusMgr.view.CommandWindow(testCase.Stack);
            testCase.addTeardown(@() delete(testCase.CommandWindowView))
        end
    end

    methods (Test)

        function tDefaultValues(testCase)
            testCase.verifyTrue(testCase.CommandWindowView.ShowInfo)
            testCase.verifyTrue(testCase.CommandWindowView.ShowWarnings)
            testCase.verifyTrue(testCase.CommandWindowView.ShowErrors)
            testCase.verifyTrue(testCase.CommandWindowView.ShowSuccess)
            testCase.verifyTrue(testCase.CommandWindowView.ShowRunning)
            testCase.verifyFalse(testCase.CommandWindowView.ShowIdle)
        end

        function tDisplaySuccess(testCase)
            testCase.Stack.addStatus("Success", Message="s1");
            testCase.verifyEqual(testCase.CommandWindowView.PreviousMessage, "s1");
        end

        function tDisplayInfo(testCase)
            testCase.Stack.addStatus("Info", Message="i1");
            testCase.verifyTrue(testCase.CommandWindowView.ShowInfo)
            testCase.verifyEqual(testCase.CommandWindowView.PreviousMessage, "i1");

            testCase.CommandWindowView.ShowInfo = false;
            testCase.Stack.addStatus("Info", Message="i2");
            testCase.verifyFalse(testCase.CommandWindowView.ShowInfo)
            testCase.verifyEqual(testCase.CommandWindowView.IncomingStatus.Message, "i2");
            testCase.verifyTrue(ismissing(testCase.CommandWindowView.PreviousMessage))
        end

        function tDisplayRunning(testCase)
            status = testCase.Stack.addStatus("Running", Message="r1");
            pause(0.5)

            testCase.verifyEqual(testCase.CommandWindowView.RunningTimer.Running, 'on')
            testCase.verifyEqual(testCase.CommandWindowView.PreviousMessage, "r1");

            testCase.Stack.CurrentStatus.complete()
            pause(0.5)

            testCase.verifyTrue(status.IsComplete)
            testCase.verifyFalse(isvalid(testCase.CommandWindowView.RunningTimer))
        end
        
        function tDisplayWarning(testCase)
            fcn = @() testCase.Stack.addStatus("Warning", Message="w1", Identifier="a:b");
            testCase.verifyWarning(fcn, "a:b")
        end

        function tDisplayError(testCase)

            me = MException("a:b:c", "test error a:b:c");

            diaryFile = testCase.diaryFixture();

            testCase.Stack.addError(me);

            lines = strjoin(readlines(diaryFile), newline);
            testCase.verifyTrue(contains(lines, "test error a:b:c"));

            testCase.verifyEqual(testCase.CommandWindowView.PreviousMessage, string(me.getReport()));

        end

        function tDisplayIdle(testCase)
            % Idle status is not displayed by default.
            testCase.Stack.addStatus("Idle", Message="idle 1");
            testCase.verifyTrue(ismissing(testCase.CommandWindowView.PreviousMessage))

            newview = statusMgr.view.CommandWindow(testCase.Stack, ShowIdle=true);
            testCase.Stack.addStatus("Idle", Message="idle 2");
            testCase.verifyEqual(newview.PreviousMessage, "idle 2");
        end

        function tNonVisibleStatus(testCase)
            % A status with IsVisible=false is not printed to the terminal.
            testCase.Stack.addStatus("Warning", Message="hidden", IsVisible=false);
            testCase.verifyTrue(ismissing(testCase.CommandWindowView.PreviousMessage))
        end

        function tSuppressedIdentifier(testCase)
            % Statuses whose identifier is suppressed on the stack are not
            % printed to the terminal.
            testCase.Stack.suppressIdentifier("my:id");
            testCase.Stack.addStatus("Warning", Identifier="my:id", Message="suppressed");
            testCase.verifyTrue(ismissing(testCase.CommandWindowView.PreviousMessage))
        end

        function tUpdateMessageAndValue(testCase)
            status = testCase.Stack.addStatus("Running", Message="r1", Value=1);

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "r1")
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Value, 1)

            testCase.Stack.updateStatus(status, Message="r2", Value=2);

            testCase.verifyEqual(testCase.Stack.CurrentStatus.Message, "r2")
            testCase.verifyEqual(testCase.Stack.CurrentStatus.Value, 2)
        end

    end

    methods (Access = protected)

        function diaryFile = diaryFixture(testCase)
            % Use diary to capture the output to the command window
            testCase.addTeardown(@() diary(get(0,'Diary')));

            wff = matlab.unittest.fixtures.WorkingFolderFixture;
            testCase.applyFixture(wff);
            diaryFile = fullfile(wff.Folder, "diary.txt");
            testCase.addTeardown(@() delete(diaryFile));

            testCase.addTeardown(@() diary("off")); % Ensure the diary is closed before trying to delete the file
            diary(diaryFile);
        end

    end

end

