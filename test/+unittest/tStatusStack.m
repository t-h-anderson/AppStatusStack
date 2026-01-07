classdef tStatusStack < matlab.unittest.TestCase

    methods (Test)

        function tDefaultStack(testCase)
            % Check the default properties of a Stack.
            S = appStatus.stack.StatusStack();

            testCase.assertSize(S.Statuses, [1 1]);
            testCase.assertEmpty(S.StatusListeners);
            testCase.assertEmpty(S.StatusStackMonitorableListeners);
            testCase.verifyEqual(S.Statuses, S.CurrentStatus);
        end

        function tIdleStatusByDefault(testCase)
            % Status on a new stack is Idle by default.
            S = appStatus.stack.StatusStack();

            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tAddCondition(testCase)
            % Add default condition with no other input.
            S = appStatus.stack.StatusStack();
            S.addCondition();
            
            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Running)
            testCase.verifyEqual(S.CurrentStatus.Message, "")
            testCase.verifyEqual(S.CurrentStatus.MessageShort, "")
        end

        function tAddBlockingCondition(testCase)
            % Add a blocking condition with a message.
            S = appStatus.stack.StatusStack();
            S.addCondition("Success", Message="Test", IsBlocking=true);

            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Success)
            testCase.verifyEqual(S.CurrentStatus.Message, "Test")
            testCase.verifyEqual(S.CurrentStatus.MessageShort, "Test")
            testCase.verifyTrue(S.CurrentStatus.IsBlocking)
        end

        function tAddConditionWithCleanup(testCase)
            % Request the second output (cleanup object) when adding a
            % condition.
            S = appStatus.stack.StatusStack();
            [~, cleanupObj] = S.addCondition("Warning"); %#ok<ASGLU>

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.Statuses(end), S.CurrentStatus)

            clear cleanupObj

            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tAddMultipleStatuses(testCase)
            S = appStatus.stack.StatusStack();
            S.addCondition("Error", Message="S1");
            S.addCondition("Success", Message="S2");
            S.addCondition("Success", Message="S3");

            testCase.verifySize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
        end

        function tAddMultipleBlockingStatuses(testCase)
            S = appStatus.stack.StatusStack();
            S.addCondition("Success", Message="S1", IsBlocking=true);
            S.addCondition("Success", Message="S2");
            S.addCondition("Success", Message="S3", IsBlocking=true);

            testCase.verifySize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
        end

        function tRemoveStatus(testCase)
            % Remove a specific status in the stack.
            S = appStatus.stack.StatusStack();
            statusToRemove = S.addCondition("Success", Message="S1");
            S.addCondition("Success", Message="S2");
            S.addCondition("Success", Message="S3");

            S.removeStatus(statusToRemove);

            testCase.verifySize(S.Statuses, [1 3])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
            testCase.verifyEqual(S.Statuses(2).Message, "S2")
        end

        function tRemoveLastStatus(testCase)
            S = appStatus.stack.StatusStack();
            S.addCondition("Success", Message="S1");
            status = S.addCondition("Success", Message="S2");

            S.removeLastStatus();

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Message, "S1")
            testCase.verifyTrue(status.IsComplete)
        end

        function tCompleteStatus(testCase)
            % Manually complete a status.
            S = appStatus.stack.StatusStack();
            status = S.addCondition("Running");

            testCase.verifyFalse(status.IsComplete)

            pause(1);
            status.complete();

            testCase.verifyTrue(status.IsComplete)
            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tRemoveAllStatuses(testCase)
            S = appStatus.stack.StatusStack();
            S.addCondition("Success", Message="S1");
            S.addCondition("Success", Message="S2");

            testCase.verifySize(S.Statuses, [1 3])

            S.removeAllStatuses();

            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tPrintTable(testCase)
            % Display summary table of statuses.
            S = appStatus.stack.StatusStack();
            S.addCondition("RunningCancellable", Message="S1");
            S.addCondition("Warning", Message="S2");

            t = S.table();

            testCase.assertSize(t, [3 9])
            testCase.verifyEqual(t.Condition, ["Idle"; "RunningCancellable"; "Warning"])
        end

        function tAddError(testCase)
            S = appStatus.stack.StatusStack();
            S.addError(MException("a:b:c", "test"));

            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Error)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
            testCase.assertClass(S.CurrentStatus.Data, "MException")
            testCase.verifyEqual(S.CurrentStatus.Data.identifier, 'a:b:c')
            testCase.verifyTrue(S.CurrentStatus.IsBlocking)
        end

        function tRunCommand(testCase)
            S = appStatus.stack.StatusStack();
            result = S.run(@() 1+1);

            testCase.verifyEqual(result, 2)
            testCase.assertSize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tRunCommandWithWarning(testCase)
            S = appStatus.stack.StatusStack();
            S.run(@() warning("test"));

            testCase.assertEqual(S.CurrentStatus.Condition, appStatus.Condition.Warning)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
        end

        function tRunCommandWithError(testCase)
            S = appStatus.stack.StatusStack();
            S.run(@() error("test"));

            testCase.assertEqual(S.CurrentStatus.Condition, appStatus.Condition.Error)
            testCase.verifyEqual(S.CurrentStatus.Data.message, 'test')
            testCase.verifyTrue(S.CurrentStatus.IsBlocking)
        end

        function tRunMultipleCommands(testCase)
            S = appStatus.stack.StatusStack();
            S.run(@() 1+1);
            S.run(@() error("test 1"));
            S.run(@() error("test 2"));
            S.run(@() 1+1);
            S.run(@() warning("test"));

            testCase.assertSize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Warning)
            testCase.verifyEqual(S.Statuses(2).MessageShort, "test 1")
        end

        function tRunCommandWithMultipleOutputs(testCase)
            S = appStatus.stack.StatusStack();
            [a, b, c] = S.run(@() fileparts("a/b.c"));
             
            testCase.verifyEqual(a, "a")
            testCase.verifyEqual(b, "b")
            testCase.verifyEqual(c, ".c")
        end

        function tUpdateStatus(testCase)
            % Update value and message of the current status.
            S = appStatus.stack.StatusStack();
            status = S.addCondition("Running", Message="m1", Value=1);

            testCase.verifyEqual(S.CurrentStatus.Message, "m1")
            testCase.verifyEqual(S.CurrentStatus.Value, 1)

            S.updateStatusValue(2, status);
            S.updateStatusMessage("m2", status);

            testCase.verifyEqual(S.CurrentStatus.Message, "m2")
            testCase.verifyEqual(S.CurrentStatus.Value, 2)
        end

        function tUpdateOldStatus(testCase)
            % Update message and value of a status that no longer exists.
            S = appStatus.stack.StatusStack();
            status = S.addCondition("Running", Message="m1", Value=1);
            status.complete();

            S.addCondition("Warning");

            S.updateStatusValue(2, status);
            S.updateStatusMessage("m2", status);

            testCase.assertSize(S.Statuses, [1, 2])
            testCase.assertEqual(S.CurrentStatus.Condition, appStatus.Condition.Warning)
        end

        function tEmptyStack(testCase)
            % Call the main methods on an empty stack.
            S = appStatus.stack.StatusStack.empty(1,0);

            status = S.addCondition("Running");
            testCase.verifyEmpty(status);

            S.updateStatusMessage("m", appStatus.Status("Running"));
            S.updateStatusValue(1, appStatus.Status("Running"));
            S.removeStatus(appStatus.Status("Running"));

            testCase.verifyEmpty(S);
        end

        function tMonitorable(testCase)
            % If a monitorable class calls setStatus within its code it
            % gets picked up by the status stack.
            S = appStatus.stack.StatusStack();
            obj = appStatus.demo.Monitorable;
            S.monitor(obj);

            obj.showError("test");

            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Error)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
        end

    end


end