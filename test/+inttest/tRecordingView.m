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

        function tIncludeIdentifiersGlobAllowList(testCase)
            % With IncludeIdentifiers set, only matching statuses are
            % shown; unidentified statuses are dropped.
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S, ...
                IncludeIdentifiers=["myapp:net:*"]);
            testCase.addTeardown(@() delete(view))

            S.addStatus("Info", Identifier="myapp:net:slow", Message="kept");
            S.addStatus("Info", Identifier="myapp:db:slow", Message="dropped");
            S.addStatus("Info", Message="no id, dropped");

            recordedMsgs = [view.RecordedStatuses.Message];
            testCase.verifyEqual(recordedMsgs, "kept")
        end

        function tExcludeIdentifiersGlobBlockList(testCase)
            % With ExcludeIdentifiers, matching statuses are dropped;
            % everything else (including unidentified) is recorded.
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S, ...
                ExcludeIdentifiers=["*timeout*"]);
            testCase.addTeardown(@() delete(view))

            S.addStatus("Info", Identifier="myapp:net:timeout", Message="dropped");
            S.addStatus("Info", Identifier="myapp:db:slow", Message="kept");
            S.addStatus("Info", Message="kept too");

            recordedMsgs = [view.RecordedStatuses.Message];
            testCase.verifyEqual(recordedMsgs, ["kept", "kept too"])
        end

        function tIncludeAndExcludeCombine(testCase)
            % Include narrows; exclude further removes from that set.
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S, ...
                IncludeIdentifiers=["myapp:*"], ...
                ExcludeIdentifiers=["*:debug"]);
            testCase.addTeardown(@() delete(view))

            S.addStatus("Info", Identifier="myapp:net:slow", Message="kept");
            S.addStatus("Info", Identifier="myapp:net:debug", Message="dropped");
            S.addStatus("Info", Identifier="other:net:slow", Message="dropped");

            recordedMsgs = [view.RecordedStatuses.Message];
            testCase.verifyEqual(recordedMsgs, "kept")
        end

        function tRecordsRequestingInputByDefault(testCase)
            % HandleInputRequests defaults to true on the recorder, so
            % the RequestingInput status is fed through handleInputRequest
            % and recorded. We check Message rather than Type because
            % the Status object is held by reference — by the time the
            % assertion runs, requestInput's timeout has transitioned
            % the same Status object's Type to ValueSupplied.
            S = statusMgr.Stack();
            view = statusMgr.view.RecordingView(S);
            testCase.addTeardown(@() delete(view))

            S.requestInput("Need value", DefaultValue="x", Timeout=0.1);

            recordedMsgs = [view.RecordedStatuses.Message];
            testCase.verifyTrue(any(recordedMsgs == "Need value"))
        end

    end

end
