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
            S.addCondition(appStatus.Condition.Success, ...
                Message="Test", IsBlocking=true);

            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Success)
            testCase.verifyEqual(S.CurrentStatus.Message, "Test")
            testCase.verifyEqual(S.CurrentStatus.MessageShort, "Test")
            testCase.verifyTrue(S.CurrentStatus.IsBlocking)
        end

        function tAddConditionWithCleanup(testCase)
            % Request the second output (cleanup object) when adding a
            % condition.
            S = appStatus.stack.StatusStack();
            [~, cleanupObj] = S.addCondition(appStatus.Condition.Warning); %#ok<ASGLU>

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.Statuses(end), S.CurrentStatus)

            clear cleanupObj

            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tAddMultipleStatuses(testCase)
            S = appStatus.stack.StatusStack();
            S.addCondition(appStatus.Condition.Error, Message="S1");
            S.addCondition(appStatus.Condition.Success, Message="S2");
            S.addCondition(appStatus.Condition.Success, Message="S3");

            testCase.verifySize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
        end

        function tAddMultipleBlockingStatuses(testCase)
            S = appStatus.stack.StatusStack();
            S.addCondition(appStatus.Condition.Success, Message="S1", IsBlocking=true);
            S.addCondition(appStatus.Condition.Success, Message="S2");
            S.addCondition(appStatus.Condition.Success, Message="S3", IsBlocking=true);

            testCase.verifySize(S.Statuses, [1 4])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
        end

        function tRemoveStatus(testCase)
            % Remove a specific status in the stack.
            S = appStatus.stack.StatusStack();
            statusToRemove = S.addCondition(appStatus.Condition.Success, Message="S1");
            S.addCondition(appStatus.Condition.Success, Message="S2");
            S.addCondition(appStatus.Condition.Success, Message="S3");

            S.removeStatus(statusToRemove);

            testCase.verifySize(S.Statuses, [1 3])
            testCase.verifyEqual(S.CurrentStatus.Message, "S3")
            testCase.verifyEqual(S.Statuses(2).Message, "S2")
        end

        function tRemoveLastStatus(testCase)
            S = appStatus.stack.StatusStack();
            S.addCondition(appStatus.Condition.Success, Message="S1");
            S.addCondition(appStatus.Condition.Success, Message="S2");

            S.removeLastStatus();

            testCase.verifySize(S.Statuses, [1 2])
            testCase.verifyEqual(S.CurrentStatus.Message, "S1")
        end

        function tCompleteStatus(testCase)
            % Manually complete a status.
            S = appStatus.stack.StatusStack();
            status = S.addCondition(appStatus.Condition.Running);

            testCase.verifyFalse(status.IsComplete)

            pause(1);
            status.complete();

            testCase.verifyTrue(status.IsComplete)
            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tRemoveAllStatuses(testCase)
            S = appStatus.stack.StatusStack();
            S.addCondition(appStatus.Condition.Success, Message="S1");
            S.addCondition(appStatus.Condition.Success, Message="S2");

            testCase.verifySize(S.Statuses, [1 3])

            S.removeAllStatuses();

            testCase.verifySize(S.Statuses, [1 1])
            testCase.verifyEqual(S.CurrentStatus.Condition, appStatus.Condition.Idle)
        end

        function tPrintTable(testCase)
            % Display summary table of statuses.
            S = appStatus.stack.StatusStack();
            S.addCondition(appStatus.Condition.RunningCancellable, Message="S1");
            S.addCondition(appStatus.Condition.Warning, Message="S2");

            t = S.table();

            testCase.assertSize(t, [3 9])
            testCase.verifyEqual(t.Condition, ["Idle"; "RunningCancellable"; "Warning"])
        end

    end


end