classdef tStack < matlab.unittest.TestCase

    methods (Test)

        function tDefaultStack(testCase)
            % Check the default properties of a Stack.
            S = statusMgr.Stack();

            testCase.assertSize(S.Statuses, [1 1]);
            testCase.assertEmpty(S.StatusListeners);
            testCase.assertEmpty(S.StackMonitorableListeners);
            testCase.verifyEqual(S.Statuses, S.CurrentStatus);
        end

        function tIdleStatusByDefault(testCase)
            % Status on a new stack is Idle by default.
            S = statusMgr.Stack();

            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tAddStatus(testCase)
            % Add default status with no other input.
            S = statusMgr.Stack();
            S.addStatus();
            
            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Info)
            testCase.verifyEqual(S.CurrentStatus.Message, "")
            testCase.verifyEqual(S.CurrentStatus.MessageShort, "")
        end

        function tAddStatusWithProperties(testCase)
            % Add a status with non-default inputs.
            S = statusMgr.Stack();
            S.addStatus("Info", Message="t1", Value=10, IsTemporary=true, ...
                Identifier="id1", Data={1,2}, MessageShort="m1", ...
                IsVisible=false);

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Info)
            testCase.verifyEqual(S.CurrentStatus.Message, "t1")
            testCase.verifyEqual(S.CurrentStatus.MessageShort, "m1")
            testCase.verifyTrue(S.CurrentStatus.IsTemporary)
            testCase.verifyFalse(S.CurrentStatus.IsVisible)
            testCase.verifyEqual(S.CurrentStatus.Value, 10)
            testCase.verifyEqual(S.CurrentStatus.Identifier, "id1")
            testCase.verifyEqual(S.CurrentStatus.Data, {1,2})
        end

        function tAddStatusWithTitle(testCase)
            % Title is threaded through addStatus to the Status object.
            S = statusMgr.Stack();
            S.addStatus("Running", Title="Phase 1");

            testCase.verifyEqual(S.CurrentStatus.Title, "Phase 1")
        end

        function tAddStatusDefaultTitle(testCase)
            % Default Title is an empty string.
            S = statusMgr.Stack();
            S.addStatus("Running");

            testCase.verifyEqual(S.CurrentStatus.Title, "")
        end

        function tAddStatusWithCleanup(testCase)
            % Request the second output (cleanup object) when adding a
            % status.
            S = statusMgr.Stack();
            [~, cleanupObj] = S.addStatus("Warning"); %#ok<ASGLU>

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.Statuses(end), S.CurrentStatus)

            clear cleanupObj

            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tAddMultipleStatuses(testCase)
            S = statusMgr.Stack();
            S.addStatus("Error", Message="S1");
            S.addStatus("Success", Message="S2");
            S.addStatus("Success", Message="S3");

            testCase.verifySize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
        end

        function tRemoveStatus(testCase)
            % Remove a specific status in the stack.
            S = statusMgr.Stack();
            statusToRemove = S.addStatus("Success", Message="S1");
            S.addStatus("Success", Message="S2");
            S.addStatus("Success", Message="S3");

            S.removeStatus(statusToRemove);

            testCase.verifySize(S.Statuses, [1 3])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
            testCase.verifyEqual(S.Statuses(2).Message, "S2")
        end

        function tRemoveLastStatus(testCase)
            S = statusMgr.Stack();
            S.addStatus("Success", Message="S1");
            status = S.addStatus("Success", Message="S2");

            S.removeLastStatus();

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Message, "S1")
            testCase.verifyTrue(status.IsComplete)
        end

        function tCompleteStatus(testCase)
            % Manually complete a status.
            S = statusMgr.Stack();
            status = S.addStatus("Running");

            testCase.verifyFalse(status.IsComplete)

            pause(1);
            status.complete();

            testCase.verifyTrue(status.IsComplete)
            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tRemoveAllStatuses(testCase)
            S = statusMgr.Stack();
            S.addStatus("Success", Message="S1");
            S.addStatus("Success", Message="S2");

            testCase.verifySize(S.Statuses, [1 3])

            S.removeAllStatuses();

            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tPrintTable(testCase)
            % Display summary table of statuses.
            S = statusMgr.Stack();
            S.addStatus("RunningCancellable", Message="S1");
            S.addStatus("Warning", Message="S2");

            t = S.table();

            testCase.assertSize(t, [3 8])
            testCase.verifyEqual(t.Type, ["Idle"; "RunningCancellable"; "Warning"])
        end

        function tAddError(testCase)
            S = statusMgr.Stack();
            S.addError(MException("a:b:c", "test"));

            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Error)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
            testCase.assertClass(S.CurrentStatus.Data, "MException")
            testCase.verifyEqual(S.CurrentStatus.Data.identifier, 'a:b:c')
            testCase.verifyEqual(S.CurrentStatus.Identifier, "a:b:c")
        end

        function tRunCommand(testCase)
            S = statusMgr.Stack();
            result = S.run(@() 1+1);

            testCase.verifyEqual(result, 2)
            testCase.assertSize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tRunCommandWithWarning(testCase)
            S = statusMgr.Stack();
            S.run(@() warning("test"));

            testCase.assertEqual(S.CurrentStatus.Type, statusMgr.StatusType.Warning)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
        end

        function tRunCommandWithError(testCase)
            S = statusMgr.Stack();
            S.run(@() error("test"));

            testCase.assertEqual(S.CurrentStatus.Type, statusMgr.StatusType.Error)
            testCase.verifyEqual(S.CurrentStatus.Data.message, 'test')
        end

        function tRunMultipleCommands(testCase)
            S = statusMgr.Stack();
            S.run(@() 1+1);
            S.run(@() error("test 1"));
            S.run(@() error("test 2"));
            S.run(@() 1+1);
            S.run(@() warning("test"));

            testCase.assertSize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Warning)
            testCase.verifyEqual(S.Statuses(2).MessageShort, "test 1")
        end

        function tRunCommandWithMultipleOutputs(testCase)
            S = statusMgr.Stack();
            [a, b, c] = S.run(@() fileparts("a/b.c"));
             
            testCase.verifyEqual(a, "a")
            testCase.verifyEqual(b, "b")
            testCase.verifyEqual(c, ".c")
        end

        function tUpdateStatus(testCase)
            % Update value and message of the current status.
            S = statusMgr.Stack();
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
            S = statusMgr.Stack();
            status = S.addStatus("Running", Message="m1", Value=1);
            status.complete();

            S.addStatus("Warning");

            S.updateStatus(status, Value=2);
            S.updateStatus(status, Message="m2");

            testCase.assertSize(S.Statuses, [1, 2])
            testCase.assertEqual(S.CurrentStatus.Type, statusMgr.StatusType.Warning)
        end

        function tUpdateWithNoInputs(testCase)
            % Calling the update method without specifying a value or
            % message does nothing.
            S = statusMgr.Stack();
            status = S.addStatus("Running", Message="m1", Value=1);
            
            S.updateStatus(status);

            testCase.verifyEqual(S.CurrentStatus.Message, "m1")
            testCase.verifyEqual(S.CurrentStatus.Value, 1)
        end

        function tAddStatusToMultipleStacks(testCase)
            % Add the same status to an array of stacks.
            S1 = statusMgr.Stack();
            S2 = statusMgr.Stack();
            StackArray = [S1, S2];

            status = StackArray.addStatus("Warning", Message="m1", Value=1);

            testCase.assertSize(status, [1 1])
            testCase.verifyEqual(S1.CurrentStatus.ID, status.ID)
            testCase.verifyEqual(S2.CurrentStatus.ID, status.ID)
            testCase.verifyEqual(S2.CurrentStatus.Message, "m1")
            testCase.verifyEqual(S2.CurrentStatus.Type, statusMgr.StatusType.Warning)
            testCase.verifyEqual(S1.CurrentStatus.Value, 1)
        end

        function tUpdateMultipleStacks(testCase)
            % Call the update method on an array of stacks.
            S1 = statusMgr.Stack();
            S2 = statusMgr.Stack();
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
            S = statusMgr.Stack.empty(1,0);

            status = S.addStatus("Running");
            testCase.verifyEmpty(status);

            S.updateStatus(statusMgr.Status("Running"), Message="m", Value=1);
            S.removeStatus(statusMgr.Status("Running"));

            testCase.verifyEmpty(S);
        end

        function tMonitorable(testCase)
            % If a monitorable class calls setStatus within its code it
            % gets picked up by the status stack.
            S = statusMgr.Stack();
            obj = statusMgr.demo.Monitorable;
            S.monitor(obj);

            obj.showError("test");

            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Error)
            testCase.verifyEqual(S.CurrentStatus.Message, "test")
        end

    end


end