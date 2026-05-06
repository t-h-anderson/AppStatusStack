classdef tBackgroundFuture < matlab.unittest.TestCase
    % Integration tests for Stack.monitorFuture / Stack.runInBackground.
    % Uses backgroundPool, which is available without the Parallel
    % Computing Toolbox.

    methods (Test)

        function tMonitorFuturePushesRunningCancellableStatus(testCase)
            S = statusMgr.Stack();
            f = parfeval(backgroundPool, @() pause(0.5), 0);
            testCase.addTeardown(@() cancel(f));

            status = S.monitorFuture(f, Message="hello", PollPeriod=0.05);

            testCase.verifyEqual(S.CurrentStatus.Type, ...
                statusMgr.StatusType.RunningCancellable)
            testCase.verifyEqual(S.CurrentStatus.Message, "hello")
            testCase.verifyEqual(status.Data, f)
        end

        function tMonitorFutureCompletesStatusOnSuccess(testCase)
            S = statusMgr.Stack();
            f = parfeval(backgroundPool, @() 1 + 1, 1);
            testCase.addTeardown(@() cancel(f));

            status = S.monitorFuture(f, PollPeriod=0.05);

            wait(f);
            testCase.waitUntil(@() S.CurrentStatus.Type == statusMgr.StatusType.Idle, 3);

            testCase.verifyTrue(status.IsComplete)
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tMonitorFuturePushesErrorOnFailure(testCase)
            S = statusMgr.Stack();
            f = parfeval(backgroundPool, @() error("test:err", "boom"), 0);
            testCase.addTeardown(@() cancel(f));

            S.monitorFuture(f, PollPeriod=0.05);

            testCase.waitUntil(@() S.CurrentStatus.Type == statusMgr.StatusType.Error, 3);

            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Error)
            testCase.verifyEqual(S.CurrentStatus.Identifier, "test:err")
        end

        function tCancellingStatusCancelsFuture(testCase)
            % Completing the status (e.g. via a StatusBar Cancel
            % button) propagates to the future via cancel().
            S = statusMgr.Stack();
            f = parfeval(backgroundPool, @() pause(60), 0);
            testCase.addTeardown(@() cancel(f));

            status = S.monitorFuture(f, PollPeriod=0.05);
            testCase.assertEqual(string(f.State), "queued") % or "running"

            status.complete();

            testCase.waitUntil(@() ismember(string(f.State), ["finished", "unavailable"]), 3);
            testCase.verifyTrue(ismember(string(f.State), ["finished", "unavailable"]))
        end

        function tProgressQueueNumericUpdatesValue(testCase)
            S = statusMgr.Stack();
            queue = parallel.pool.DataQueue;
            f = parfeval(backgroundPool, @sendNumeric, 0, queue);
            testCase.addTeardown(@() cancel(f));

            status = S.monitorFuture(f, ProgressQueue=queue, PollPeriod=0.05);

            wait(f);
            testCase.waitUntil(@() status.IsComplete, 3);

            testCase.verifyEqual(status.Value, 1.0)

            function sendNumeric(q)
                for i = 1:5
                    send(q, i / 5);
                    pause(0.02);
                end
            end
        end

        function tProgressQueueStructUpdatesBoth(testCase)
            S = statusMgr.Stack();
            queue = parallel.pool.DataQueue;
            f = parfeval(backgroundPool, @sendStruct, 0, queue);
            testCase.addTeardown(@() cancel(f));

            status = S.monitorFuture(f, ProgressQueue=queue, PollPeriod=0.05);

            wait(f);
            testCase.waitUntil(@() status.IsComplete, 3);

            testCase.verifyEqual(status.Message, "step 3 of 3")
            testCase.verifyEqual(status.Value, 1.0)

            function sendStruct(q)
                for i = 1:3
                    send(q, struct("Value", i/3, "Message", "step " + i + " of 3"));
                    pause(0.02);
                end
            end
        end

        function tRunInBackgroundLaunchesAndMonitors(testCase)
            % runInBackground = parfeval + monitorFuture.
            S = statusMgr.Stack();

            [future, status] = S.runInBackground(@() 6 * 7, ...
                Message="answer", PollPeriod=0.05);
            testCase.addTeardown(@() cancel(future));

            testCase.assertEqual(S.CurrentStatus.Message, "answer")

            wait(future);
            testCase.waitUntil(@() status.IsComplete, 3);

            testCase.verifyEqual(fetchOutputs(future), 42)
            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Idle)
        end

        function tRunInBackgroundForwardsArgsAndProgressQueue(testCase)
            S = statusMgr.Stack();
            queue = parallel.pool.DataQueue;
            [future, status] = S.runInBackground(@addAndReport, ...
                Args={queue, 3, 4}, NumOutputs=1, PollPeriod=0.05, ...
                ProgressQueue=queue);
            testCase.addTeardown(@() cancel(future));

            wait(future);
            testCase.waitUntil(@() status.IsComplete, 3);

            testCase.verifyEqual(fetchOutputs(future), 7)
            testCase.verifyEqual(status.Message, "done")

            function out = addAndReport(q, a, b)
                send(q, "done");
                out = a + b;
            end
        end

        function tNonCancellableUsesRunningType(testCase)
            S = statusMgr.Stack();
            f = parfeval(backgroundPool, @() 1, 1);
            testCase.addTeardown(@() cancel(f));

            S.monitorFuture(f, Cancellable=false, PollPeriod=0.05);

            testCase.verifyEqual(S.CurrentStatus.Type, statusMgr.StatusType.Running)
        end

    end

    methods (Access = protected)

        function waitUntil(testCase, conditionFcn, timeoutSec)
            % Helper: poll a condition until it's true or timeout
            % expires. Lets test bodies stay declarative.
            deadline = tic;
            while ~conditionFcn() && toc(deadline) < timeoutSec
                pause(0.05);
                drawnow;
            end
            testCase.verifyTrue(conditionFcn(), ...
                "Condition not met within " + timeoutSec + "s")
        end

    end

end
