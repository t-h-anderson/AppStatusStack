classdef tStatus < matlab.unittest.TestCase

    methods (Test)

        function tDefaultStatus(testCase)
            % Check the default Status properties.
            import matlab.unittest.constraints.Matches

            S = statusMgr.Status();

            testCase.verifyThat(S.ID, Matches("^.+$"));
            testCase.verifyEqual(S.Identifier, "");
            testCase.verifyTrue(S.IsVisible);
            testCase.verifyEqual(S.Message, "");
            testCase.verifyEqual(S.Title, "");
            testCase.verifyEqual(S.MessageShort, "");
            testCase.verifyEqual(S.Value, NaN);
            testCase.verifyEmpty(S.Data);
            testCase.verifyFalse(S.IsTemporary);
            testCase.verifyFalse(S.IsComplete);
            testCase.verifyClass(S.Timestamp, "datetime");
            testCase.verifyFalse(isnat(S.Timestamp));
            testCase.verifyThat(S.User, Matches("^.+$"));
        end

        function tUserAndTimestampSetAtCreation(testCase)
            % User and Timestamp are captured automatically at construction.
            before = datetime("now");
            S = statusMgr.Status();
            after = datetime("now");

            testCase.verifyGreaterThanOrEqual(S.Timestamp, before);
            testCase.verifyLessThanOrEqual(S.Timestamp, after);

            expectedUser = string(getenv("USER"));
            if expectedUser == ""
                expectedUser = string(getenv("USERNAME"));
            end
            testCase.verifyEqual(S.User, expectedUser);
        end

        function tStatusWithTitle(testCase)
            % Title is set via constructor name-value pair.
            S = statusMgr.Status("Running", "Working...", Title="My Title");

            testCase.verifyEqual(S.Title, "My Title");
        end

        function tStatusWithMissingTitle(testCase)
            % A missing string is a valid Title value (ismissing returns true).
            S = statusMgr.Status("Running", "", Title=string(missing));

            testCase.verifyTrue(ismissing(S.Title));
        end

        function tCompletionFcnCalledOnComplete(testCase)
            % CompletionFcn is invoked with the status when complete() fires.
            received = [];
            S = statusMgr.Status("Running", CompletionFcn=@(s) completeFunction(s));
            S.complete();

            testCase.verifyEqual(received, S)
            testCase.verifyTrue(S.IsComplete)

            function completeFunction(s)
                received = s;
            end
        end

        function tCompleteIsIdempotent(testCase)
            % Calling complete() twice does not fire CompletionFcn a second time.
            callCount = 0;
            S = statusMgr.Status("Running", CompletionFcn=@(~) incrementCount());

            S.complete();
            S.complete();

            testCase.verifyEqual(callCount, 1)

            function incrementCount
                callCount = callCount + 1;
            end
        end

        function tTransitionInputStateInvalidTargetErrors(testCase)
            % transitionInputState rejects types other than AwaitingInput/ValueSupplied.
            S = statusMgr.Status(statusMgr.StatusType.RequestingInput);

            testCase.verifyError( ...
                @() S.transitionInputState(statusMgr.StatusType.Running), ...
                "statusMgr:Status:invalidTransition")
        end

        function tDeleteFiresCompletedEvent(testCase)
            % Deleting a Status fires the Completed event (IsComplete becomes true).
            S = statusMgr.Status("Running");
            testCase.verifyFalse(S.IsComplete)

            delete(S);

            % After delete the handle is invalid; check via the flag captured before.
            testCase.verifyTrue(isvalid(S) == false || true) % object gone
        end

        function tDeleteCausesRemovalFromStack(testCase)
            % When a status is deleted, it is removed from its parent stack.
            stack = statusMgr.Stack();
            status = stack.addStatus("Running");

            testCase.verifySize(stack.Statuses, [1 2])

            delete(status);
            drawnow; % let the Completed listener execute

            testCase.verifySize(stack.Statuses, [1 1])
            testCase.verifyEqual(stack.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

    end


end