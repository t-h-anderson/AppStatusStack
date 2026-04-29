classdef tFileLog < matlab.uitest.TestCase

    properties
        Stack statusMgr.Stack
        FileLogView statusMgr.view.FileLog
        Folder
    end

    methods (TestMethodSetup)
        function setup(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            fx = testCase.applyFixture(WorkingFolderFixture);
            testCase.Folder = fx.Folder;
            testCase.Stack = statusMgr.Stack();
            testCase.FileLogView = statusMgr.view.FileLog(testCase.Stack, ...
                LogFolder=testCase.Folder);
        end
    end

    methods (Test)

        function tDefaultValues(testCase)
            testCase.verifyTrue(testCase.FileLogView.IncludeTimestamp)
            testCase.verifyTrue(testCase.FileLogView.IncludeUser)
            testCase.verifyTrue(testCase.FileLogView.IncludeIdentifier)
            testCase.verifyTrue(testCase.FileLogView.IncludeValue)
            testCase.verifyTrue(testCase.FileLogView.ShowInfo)
            testCase.verifyTrue(testCase.FileLogView.ShowWarnings)
            testCase.verifyTrue(testCase.FileLogView.ShowErrors)
            testCase.verifyTrue(testCase.FileLogView.ShowSuccess)
            testCase.verifyTrue(testCase.FileLogView.ShowRunning)
            testCase.verifyFalse(testCase.FileLogView.ShowIdle)
            testCase.verifyEqual(testCase.FileLogView.LogFolder, string(testCase.Folder))
        end

        function tDisplayInfo(testCase)
            import matlab.unittest.constraints.IsFile
            testCase.Stack.addStatus("Info", Message="s1");
            
            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);
            
            testCase.verifyFalse(endsWith(lines(1), "[Info] [] s1"))
            testCase.verifyTrue(endsWith(lines(1), "[Info] s1"))
            testCase.verifyEqual(lines(2), "")
        end

        function tDisplayIdleDisabledByDefault(testCase)
            import matlab.unittest.constraints.IsFile
            testCase.Stack.addStatus("Idle");
            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.verifyThat(logfile, ~IsFile)
        end

        function tDoNotIncludeIdentifierOrTimestamp(testCase)
            import matlab.unittest.constraints.IsFile
            testCase.FileLogView.IncludeTimestamp = false;
            testCase.FileLogView.IncludeUser = false;
            testCase.FileLogView.IncludeIdentifier = false;
            testCase.FileLogView.IncludeValue = false;

            testCase.Stack.addStatus("Error", Message="s1", Identifier="a:b");
            testCase.Stack.addStatus("Running", Message="s2", Value=1);

            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);

            testCase.verifyEqual(lines(1), "[Error] s1")
            testCase.verifyEqual(lines(2), "[Running] s2")
            testCase.verifyEqual(lines(3), "")
        end

        function tIncludeUser(testCase)
            % User appears in the log line when IncludeUser is true (default).
            import matlab.unittest.constraints.IsFile
            testCase.FileLogView.IncludeTimestamp = false;

            testCase.Stack.addStatus("Info", Message="msg");

            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);

            expectedUser = string(getenv("USER"));
            if expectedUser == ""
                expectedUser = string(getenv("USERNAME"));
            end
            testCase.verifyTrue(startsWith(lines(1), "[" + expectedUser + "] "))
        end

        function tExcludeUser(testCase)
            % Setting IncludeUser=false omits the user field.
            import matlab.unittest.constraints.IsFile
            testCase.FileLogView.IncludeTimestamp = false;
            testCase.FileLogView.IncludeUser = false;

            testCase.Stack.addStatus("Info", Message="msg");

            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            lines = readlines(logfile);

            testCase.verifyEqual(lines(1), "[Info] msg")
        end

        function tAddError(testCase)
            import matlab.unittest.constraints.IsFile
            testCase.Stack.addError(MException("a:b:c", "e1"));

            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);

            testCase.verifyTrue(endsWith(lines(1), "[Error] [a:b:c] e1"))
            testCase.verifyEqual(lines(2), "")
        end

        function tAddMultipleStatuses(testCase)
            import matlab.unittest.constraints.IsFile
            testCase.Stack.addStatus("Success", Message="s1");
            testCase.Stack.addStatus("Warning", Message="s2", Identifier="a:b");
            testCase.Stack.addStatus("Running", Message="s3", Value=2);

            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);

            testCase.verifyTrue(endsWith(lines(1), "[Success] s1"))
            testCase.verifyTrue(endsWith(lines(2), "[Warning] [a:b] s2"))
            testCase.verifyTrue(endsWith(lines(3), "[Running] [Value=2] s3"))
            testCase.verifyEqual(lines(4), "")
        end

        function tUpdateValueAndMessage(testCase)
            % Add a "running" status and update its value and message after
            % creation.
            import matlab.unittest.constraints.IsFile
            status = testCase.Stack.addStatus("Running", Message="s1", Value=1);

            testCase.Stack.updateStatus(status, Message="s2")
            testCase.Stack.updateStatus(status, Value=2)
            testCase.Stack.updateStatus(status, Value=3, Message="s3");

            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);

            testCase.verifyTrue(endsWith(lines(1), "[Running] [Value=1] s1"))
            testCase.verifyTrue(endsWith(lines(2), "[Running] [Value=1] s2"))
            testCase.verifyTrue(endsWith(lines(3), "[Running] [Value=2] s2"))
            testCase.verifyTrue(endsWith(lines(4), "[Running] [Value=3] s3"))
            testCase.verifyEqual(lines(5), "")
        end

        function tUpdateOldStatusValueAndMessage(testCase)
            % Update a status when there are more recent statuses.
            import matlab.unittest.constraints.IsFile
            testCase.Stack.addStatus("Info", Message="i1");
            status = testCase.Stack.addStatus("Running", Message="r1", Value=1);
            testCase.Stack.addStatus("Warning", Message="w1");
            testCase.Stack.addStatus("Error", Message="e1");

            testCase.Stack.updateStatus(status, Message="r2")

            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);

            testCase.verifyTrue(endsWith(lines(1), "[Info] i1"))
            testCase.verifyTrue(endsWith(lines(2), "[Running] [Value=1] r1"))
            testCase.verifyTrue(endsWith(lines(3), "[Warning] w1"))
            testCase.verifyTrue(endsWith(lines(4), "[Error] e1"))
            testCase.verifyEqual(lines(5), "")
        end

        function tReuseExistingLogFile(testCase)
            import matlab.unittest.constraints.IsFile
            testCase.Stack.addStatus("Error", Message="e1", Data={1,2});
            testCase.Stack.addStatus("Success", Message="s1");

            % Create new stack and new file log and point it to the same
            % log file.
            newStack = statusMgr.Stack();
            newFileLogView = statusMgr.view.FileLog(newStack, ...
                LogFolder=testCase.Folder, LogFilename=testCase.FileLogView.LogFilename);

            newStack.addStatus("Info", Message="i1");

            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);

            testCase.verifyTrue(endsWith(lines(1), "[Error] e1"))
            testCase.verifyTrue(endsWith(lines(2), "[Success] s1"))
            testCase.verifyEqual(lines(3), "")
            testCase.verifyTrue(endsWith(lines(4), "[Info] i1"))
            testCase.verifyEqual(lines(5), "")
        end

        function tNonVisibleStatus(testCase)
            % A status with IsVisible=false is not written to the log file.
            import matlab.unittest.constraints.IsFile
            testCase.Stack.addStatus("Warning", Message="hidden", IsVisible=false);
            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.verifyThat(logfile, ~IsFile)
        end

        function tSuppressedIdentifier(testCase)
            % A status whose identifier is suppressed on the stack is not
            % written to the log file.
            import matlab.unittest.constraints.IsFile
            testCase.Stack.suppressIdentifier("my:id");
            testCase.Stack.addStatus("Warning", Identifier="my:id", Message="suppressed");
            logfile = fullfile(testCase.FileLogView.LogFolder, testCase.FileLogView.LogFilename);
            testCase.verifyThat(logfile, ~IsFile)
        end

        function tDisplayIdle(testCase)
            import matlab.unittest.constraints.IsFile
            newFileLogView = statusMgr.view.FileLog(testCase.Stack, ...
                LogFilename="test.txt", ShowIdle=true);
            
            testCase.Stack.addStatus("Idle", Message="i1");

            logfile = fullfile(newFileLogView.LogFolder, "test.txt");
            testCase.assertThat(logfile, IsFile)
            lines = readlines(logfile);

            testCase.verifyTrue(endsWith(lines(1), "[Idle] i1"))
            testCase.verifyEqual(lines(2), "")
        end

    end
end

