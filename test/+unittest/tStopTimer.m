classdef tStopTimer < matlab.unittest.TestCase

    methods (Test)

        function tEmptyTimerIsNoOp(testCase)
            % An empty timer handle is silently ignored.
            testCase.verifyWarningFree(...
                @() statusMgr.util.stopTimer(timer.empty(1,0)));
        end

        function tInvalidTimerIsNoOp(testCase)
            % An already-deleted timer handle is silently ignored.
            t = timer;
            delete(t);
            testCase.assertFalse(isvalid(t))

            testCase.verifyWarningFree(@() statusMgr.util.stopTimer(t));
        end

        function tStopsAndDeletesRunningTimer(testCase)
            % A running timer is stopped and deleted.
            t = timer("ExecutionMode", "fixedRate", "Period", 1, ...
                "TimerFcn", @(~,~) []);
            testCase.addTeardown(@() statusMgr.util.stopTimer(t));
            start(t);
            testCase.assertEqual(t.Running, 'on')

            statusMgr.util.stopTimer(t);

            testCase.verifyFalse(isvalid(t))
        end

        function tDeletesStoppedTimer(testCase)
            % A stopped-but-valid timer is just deleted.
            t = timer;
            testCase.addTeardown(@() statusMgr.util.stopTimer(t));
            testCase.assertEqual(t.Running, 'off')

            statusMgr.util.stopTimer(t);

            testCase.verifyFalse(isvalid(t))
        end

    end

end
