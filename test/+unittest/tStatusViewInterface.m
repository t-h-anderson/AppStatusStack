classdef tStatusViewInterface < matlab.unittest.TestCase
    % Tests for branches of statusMgr.internal.view.StatusViewInterface
    % that are not exercised by the per-view integration tests.

    methods (Test)

        function tAwaitingInputStatusIsNoOp(testCase)
            % Pushing a Status with Type=AwaitingInput hits the no-op case
            % in standardDisplay's switch — the view does not display
            % anything and no error is raised.
            S = statusMgr.Stack();
            view = statusMgr.view.CommandWindow(S);
            testCase.addTeardown(@() delete(view))

            s = statusMgr.Status(statusMgr.StatusType.AwaitingInput);

            testCase.verifyWarningFree(@() S.add(s))
        end

        function tValueSuppliedStatusIsNoOp(testCase)
            % Same as above for ValueSupplied — the intermediate transition
            % type that should not produce display output.
            S = statusMgr.Stack();
            view = statusMgr.view.CommandWindow(S);
            testCase.addTeardown(@() delete(view))

            s = statusMgr.Status(statusMgr.StatusType.ValueSupplied);

            testCase.verifyWarningFree(@() S.add(s))
        end

        function tRebindingViewDetachesFromPreviousStack(testCase)
            % Regression for issue #50: setStack must delete the existing
            % StackListener before rebinding, otherwise a view re-bound to
            % a second stack keeps firing for the first one too.
            stackA = statusMgr.Stack();
            stackB = statusMgr.Stack();

            view = statusMgr.view.RecordingView(stackA);
            testCase.addTeardown(@() delete(view))

            % Rebind from A to B, then publish on each stack.
            view.setStack(stackB);
            stackA.addStatus("Info", Message="from A");
            stackB.addStatus("Info", Message="from B");

            % Only the second stack's update should have been recorded.
            testCase.verifyEqual(view.RecordedStatuses.Message, "from B")
        end

        function tHeterogeneousArrayDefaultElementErrors(testCase)
            % matlab.mixin.Heterogeneous calls getDefaultScalarElement when
            % it needs to fill empty slots in a mixed-subclass array.
            % StatusViewInterface refuses to manufacture default views, so
            % the operation errors.
            import matlab.unittest.fixtures.WorkingFolderFixture
            fx = testCase.applyFixture(WorkingFolderFixture);

            cw = statusMgr.view.CommandWindow();
            fl = statusMgr.view.FileLog(LogFolder=fx.Folder);
            testCase.addTeardown(@() delete([cw fl]))

            testCase.verifyError(@() expandWithGap(cw, fl), ...
                "statusMgr:view:noDefault")

            function expandWithGap(a, b)
                arr = [a b];
                arr(5) = b; % indices 3..4 need default → calls getDefaultScalarElement
            end
        end

    end

end
