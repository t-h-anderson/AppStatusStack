classdef tStatusStack < matlab.unittest.TestCase

    methods (Test)

        function tDefaultStack(testCase)
            % Check the default properties of a Stack.
            S = appStatus.StatusStack();

            testCase.assertSize(S.Statuses, [1 1]);
            testCase.assertEmpty(S.StatusListeners);
            testCase.assertEmpty(S.StatusStackMonitorableListeners);
            testCase.verifyEqual(S.Statuses, S.CurrentStatus);
        end

        function tIdleStatusByDefault(testCase)
            % Status on a new stack is Idle by default.
            S = appStatus.StatusStack();

            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Idle)
        end

        function tAddStatus(testCase)
            % Add default status with no other input.
            S = appStatus.StatusStack();
            S.addStatus();
            
            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Running)
            testCase.verifyEqual(S.CurrentStatus.Message, "")
            testCase.verifyEqual(S.CurrentStatus.MessageShort, "")
        end

        function tAddStatusWithProperties(testCase)
            % Add a status with non-default inputs.
            S = appStatus.StatusStack();
            S.addStatus("Warning", Message="t1", Value=10, IsTemporary=true, ...
                Identifier="id1", Data={1,2}, MessageShort="m1", ...
                IsBlocking=true, IsVisible=false);

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Warning)
            testCase.verifyEqual(S.CurrentStatus.Message, "t1")
            testCase.verifyEqual(S.CurrentStatus.MessageShort, "m1")
            testCase.verifyTrue(S.CurrentStatus.IsTemporary)
            testCase.verifyTrue(S.CurrentStatus.IsBlocking)
            testCase.verifyFalse(S.CurrentStatus.IsVisible)
            testCase.verifyEqual(S.CurrentStatus.Value, 10)
            testCase.verifyEqual(S.CurrentStatus.Identifier, "id1")
            testCase.verifyEqual(S.CurrentStatus.Data, {1,2})
        end

        function tAddBlockingStatus(testCase)
            % Add a blocking status with a message.
            S = appStatus.StatusStack();
            S.addStatus("Success", Message="Test", IsBlocking=true);

            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Success)
            testCase.verifyEqual(S.CurrentStatus.Message, "Test")
            testCase.verifyEqual(S.CurrentStatus.MessageShort, "Test")
            testCase.verifyTrue(S.CurrentStatus.IsBlocking)
        end

        function tAddStatusWithCleanup(testCase)
            % Request the second output (cleanup object) when adding a
            % status.
            S = appStatus.StatusStack();
            [~, cleanupObj] = S.addStatus("Warning"); %#ok<ASGLU>

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.Statuses(end), S.CurrentStatus)

            clear cleanupObj

            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Idle)
        end

        function tAddMultipleStatuses(testCase)
            S = appStatus.StatusStack();
            S.addStatus("Error", Message="S1");
            S.addStatus("Success", Message="S2");
            S.addStatus("Success", Message="S3");

            testCase.verifySize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
        end

        function tAddMultipleBlockingStatuses(testCase)
            S = appStatus.StatusStack();
            S.addStatus("Success", Message="S1", IsBlocking=true);
            S.addStatus("Success", Message="S2");
            S.addStatus("Success", Message="S3", IsBlocking=true);

            testCase.verifySize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
        end

        function tRemoveStatus(testCase)
            % Remove a specific status in the stack.
            S = appStatus.StatusStack();
            statusToRemove = S.addStatus("Success", Message="S1");
            S.addStatus("Success", Message="S2");
            S.addStatus("Success", Message="S3");

            S.removeStatus(statusToRemove);

            testCase.verifySize(S.Statuses, [1 3])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
            testCase.verifyEqual(S.Statuses(2).Message, "S2")
        end

        function tRemoveLastStatus(testCase)
            S = appStatus.StatusStack();
            S.addStatus("Success", Message="S1");
            status = S.addStatus("Success", Message="S2");

            S.removeLastStatus();

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Message, "S1")
            testCase.verifyTrue(status.IsComplete)
        end

        function tCompleteStatus(testCase)
            % Manually complete a status.
            S = appStatus.StatusStack();
            status = S.addStatus("Running");

            testCase.verifyFalse(status.IsComplete)

            pause(1);
            status.complete();

            testCase.verifyTrue(status.IsComplete)
            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Idle)
        end

        function tRemoveAllStatuses(testCase)
            S = appStatus.StatusStack();
            S.addStatus("Success", Message="S1");
            S.addStatus("Success", Message="S2");

            testCase.verifySize(S.Statuses, [1 3])

            S.removeAllStatuses();

            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Idle)
        end

        function tPrintTable(testCase)
            % Display summary table of statuses.
            S = appStatus.StatusStack();
            S.addStatus("RunningCancellable", Message="S1");
            S.addStatus("Warning", Message="S2");

            t = S.table();

            testCase.assertSize(t, [3 9])
            testCase.verifyEqual(t.Type, ["Idle"; "RunningCancellable"; "Warning"])
        end

        function tAddError(testCase)
            S = appStatus.StatusStack();
            S.addError(MException("a:b:c", "test"));

            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Error)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
            testCase.assertClass(S.CurrentStatus.Data, "MException")
            testCase.verifyEqual(S.CurrentStatus.Data.identifier, 'a:b:c')
            testCase.verifyTrue(S.CurrentStatus.IsBlocking)
            testCase.verifyEqual(S.CurrentStatus.Identifier, "a:b:c")
        end

        function tRunCommand(testCase)
            S = appStatus.StatusStack();
            result = S.run(@() 1+1);

            testCase.verifyEqual(result, 2)
            testCase.assertSize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Idle)
        end

        function tRunCommandWithWarning(testCase)
            S = appStatus.StatusStack();
            S.run(@() warning("test"));

            testCase.assertEqual(S.CurrentStatus.Type, appStatus.StatusType.Warning)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
        end

        function tRunCommandWithError(testCase)
            S = appStatus.StatusStack();
            S.run(@() error("test"));

            testCase.assertEqual(S.CurrentStatus.Type, appStatus.StatusType.Error)
            testCase.verifyEqual(S.CurrentStatus.Data.message, 'test')
            testCase.verifyTrue(S.CurrentStatus.IsBlocking)
        end

        function tRunMultipleCommands(testCase)
            S = appStatus.StatusStack();
            S.run(@() 1+1);
            S.run(@() error("test 1"));
            S.run(@() error("test 2"));
            S.run(@() 1+1);
            S.run(@() warning("test"));

            testCase.assertSize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Warning)
            testCase.verifyEqual(S.Statuses(2).MessageShort, "test 1")
        end

        function tRunCommandWithMultipleOutputs(testCase)
            S = appStatus.StatusStack();
            [a, b, c] = S.run(@() fileparts("a/b.c"));
             
            testCase.verifyEqual(a, "a")
            testCase.verifyEqual(b, "b")
            testCase.verifyEqual(c, ".c")
        end

        function tUpdateStatus(testCase)
            % Update value and message of the current status.
            S = appStatus.StatusStack();
            status = S.addStatus("Running", Message="m1", Value=1);

            testCase.verifyEqual(S.CurrentStatus.Message, "m1")
            testCase.verifyEqual(S.CurrentStatus.Value, 1)

            S.updateStatus(status, Value=2);
            S.updateStatus(status, Message="m2");

            testCase.verifyEqual(S.CurrentStatus.Message, "m2")
            testCase.verifyEqual(S.CurrentStatus.Value, 2)
        end

        function tUpdateOldStatus(testCase)
            % Update message and value of a status that no longer exists.
            S = appStatus.StatusStack();
            status = S.addStatus("Running", Message="m1", Value=1);
            status.complete();

            S.addStatus("Warning");

            S.updateStatus(status, Value=2);
            S.updateStatus(status, Message="m2");

            testCase.assertSize(S.Statuses, [1, 2])
            testCase.assertEqual(S.CurrentStatus.Type, appStatus.StatusType.Warning)
        end

        function tUpdateWithNoInputs(testCase)
            % Calling the update method without specifying a value or
            % message does nothing.
            S = appStatus.StatusStack();
            status = S.addStatus("Running", Message="m1", Value=1);
            
            S.updateStatus(status);

            testCase.verifyEqual(S.CurrentStatus.Message, "m1")
            testCase.verifyEqual(S.CurrentStatus.Value, 1)
        end

        function tAddStatusToMultipleStacks(testCase)
            % Add the same status to an array of stacks.
            S1 = appStatus.StatusStack();
            S2 = appStatus.StatusStack();
            StackArray = [S1, S2];

            status = StackArray.addStatus("Warning", Message="m1", Value=1);

            testCase.assertSize(status, [1 1])
            testCase.verifyEqual(S1.CurrentStatus.ID, status.ID)
            testCase.verifyEqual(S2.CurrentStatus.ID, status.ID)
            testCase.verifyEqual(S2.CurrentStatus.Message, "m1")
            testCase.verifyEqual(S2.CurrentStatus.Type, appStatus.StatusType.Warning)
            testCase.verifyEqual(S1.CurrentStatus.Value, 1)
        end

        function tUpdateMultipleStacks(testCase)
            % Call the update method on an array of stacks.
            S1 = appStatus.StatusStack();
            S2 = appStatus.StatusStack();
            StackArray = [S1, S2];

            status = StackArray.addStatus("Running", Message="m1", Value=1);
            StackArray.updateStatus(status, Message="m2", Value=2);

            testCase.verifyEqual(S1.CurrentStatus.Message, "m2")
            testCase.verifyEqual(S1.CurrentStatus.Value, 2)
            testCase.verifyEqual(S2.CurrentStatus.Message, "m2")
            testCase.verifyEqual(S2.CurrentStatus.Value, 2)
        end

        function tEmptyStack(testCase)
            % Call the main methods on an empty stack.
            S = appStatus.StatusStack.empty(1,0);

            status = S.addStatus("Running");
            testCase.verifyEmpty(status);

            S.updateStatus(appStatus.Status("Running"), Message="m", Value=1);
            S.removeStatus(appStatus.Status("Running"));

            testCase.verifyEmpty(S);
        end

        function tMonitorable(testCase)
            % If a monitorable class calls setStatus within its code it
            % gets picked up by the status stack.
            S = appStatus.StatusStack();
            obj = appStatus.demo.Monitorable;
            S.monitor(obj);

            obj.showError("test");

            testCase.verifyEqual(S.CurrentStatus.Type, appStatus.StatusType.Error)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
        end

    end


end