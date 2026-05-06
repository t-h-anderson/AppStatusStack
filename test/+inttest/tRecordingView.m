classdef tRecordingView < matlab.unittest.TestCase

    methods (Test)

        function tStartsEmpty(testCase)
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S);
            testCase.addTeardown(@() delete(view))

            testCase.verifyEmpty(view.RecordedStatuses)
        end

        function tRecordsStatusesInOrder(testCase)
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S);
            testCase.addTeardown(@() delete(view))

            S.addStatus("Info", Message="hello");
            S.addStatus("Warning", Message="oops");
            S.addStatus("Success", Message="done");

            testCase.assertSize(view.RecordedStatuses, [1 3])
            testCase.verifyEqual(view.RecordedStatuses(1).Message, "hello")
            testCase.verifyEqual(view.RecordedStatuses(2).Message, "oops")
            testCase.verifyEqual(view.RecordedStatuses(3).Message, "done")
        end

        function tHonoursShowFlags(testCase)
            % ShowWarnings=false suppresses Warning recording without
            % affecting other types.
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S, ShowWarnings=false);
            testCase.addTeardown(@() delete(view))

            S.addStatus("Info", Message="i");
            S.addStatus("Warning", Message="w");
            S.addStatus("Error", Message="e");

            recordedTypes = [view.RecordedStatuses.Type];
            testCase.verifyEqual(recordedTypes, ...
                [statusMgr.StatusType.Info, statusMgr.StatusType.Error])
        end

        function tShowIdleOptIn(testCase)
            % Idle is off by default; turning it on records the Idle
            % statuses that the stack falls back to.
            S = statusMgr.Stack();
            viewDefault = statusMgr.view.RecordingView(S);
            testCase.addTeardown(@() delete(viewDefault))
            viewWithIdle = statusMgr.view.RecordingView(S, ShowIdle=true);
            testCase.addTeardown(@() delete(viewWithIdle))

            S.addStatus("Info", Message="hi");
            S.removeAllStatuses(); % returns stack to Idle

            testCase.verifySize(viewDefault.RecordedStatuses, [1 1])
            % viewWithIdle saw the Idle pushed at construction-time
            % too via the same listener path.
            testCase.verifyGreaterThan(numel(viewWithIdle.RecordedStatuses), 1)
        end

        function tClearEmptiesHistory(testCase)
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S);
            testCase.addTeardown(@() delete(view))

            S.addStatus("Info", Message="hi");
            testCase.assertSize(view.RecordedStatuses, [1 1])

            view.clear();

            testCase.verifyEmpty(view.RecordedStatuses)
        end

        function tRecordsRequestingInputByDefault(testCase)
            % HandleInputRequests defaults to false on the recorder, so
            % requestInput times out (no view claims it). The recorder
            % still observes the RequestingInput status.
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S);
            testCase.addTeardown(@() delete(view))

            S.requestInput("Need value", DefaultValue="x", Timeout=0.1);

            recordedTypes = [view.RecordedStatuses.Type];
            testCase.verifyTrue(any(recordedTypes == statusMgr.StatusType.RequestingInput))
        end

    end

end
