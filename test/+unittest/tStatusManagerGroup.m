classdef tStatusManagerGroup < matlab.unittest.TestCase

    methods (Test)

        % --- construction ---------------------------------------------------

        function tDefaultConstruction(testCase)
            % New group has a Stack and an empty Views array.
            smg = statusMgr.util.StatusManagerGroup();

            testCase.assertClass(smg.Stack, 'statusMgr.Stack')
            testCase.assertSize(smg.Views, [1 0])
        end

        % --- addView --------------------------------------------------------

        function tAddView(testCase)
            % Adding a view registers it in the Views array.
            smg = statusMgr.util.StatusManagerGroup();
            view = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(view))

            smg.addView(view);

            testCase.assertSize(smg.Views, [1 1])
            testCase.verifyEqual(smg.Views(1), view)
        end

        function tAddViewConnectsToGroupStack(testCase)
            % addView reconnects a view that was built on a different Stack.
            smg = statusMgr.util.StatusManagerGroup();
            otherStack = statusMgr.Stack();
            view = statusMgr.view.CommandWindow(otherStack);
            testCase.addTeardown(@() delete(view))

            smg.addView(view);

            testCase.verifyEqual(view.Stack, smg.Stack)
        end

        function tAddMultipleViewsHeterogeneousArray(testCase)
            % Different view types can coexist in the same typed Views array.
            import matlab.unittest.fixtures.WorkingFolderFixture
            smg = statusMgr.util.StatusManagerGroup();

            v1 = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(v1))

            fx = testCase.applyFixture(WorkingFolderFixture);
            v2 = statusMgr.view.FileLog(smg.Stack, LogFolder=fx.Folder);

            smg.addView(v1);
            smg.addView(v2);

            testCase.assertSize(smg.Views, [1 2])
            testCase.verifyClass(smg.Views(1), 'statusMgr.view.CommandWindow')
            testCase.verifyClass(smg.Views(2), 'statusMgr.view.FileLog')
        end

        % --- removeView -----------------------------------------------------

        function tRemoveView(testCase)
            % Removing a view by index shrinks the array.
            smg = statusMgr.util.StatusManagerGroup();
            view = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(view))
            smg.addView(view);

            smg.removeView(1);

            testCase.assertSize(smg.Views, [1 0])
        end

        function tRemoveViewMiddleIndex(testCase)
            % Removing index 2 of 3 leaves views at positions 1 and 3.
            import matlab.unittest.fixtures.WorkingFolderFixture
            smg = statusMgr.util.StatusManagerGroup();

            v1 = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(v1))
            fx = testCase.applyFixture(WorkingFolderFixture);
            v2 = statusMgr.view.FileLog(smg.Stack, LogFolder=fx.Folder);
            v3 = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(v3))

            smg.addView(v1);
            smg.addView(v2);
            smg.addView(v3);

            smg.removeView(2);

            testCase.assertSize(smg.Views, [1 2])
            testCase.verifyEqual(smg.Views(1), v1)
            testCase.verifyEqual(smg.Views(2), v3)
        end

        function tRemoveViewOutOfRangeErrors(testCase)
            smg = statusMgr.util.StatusManagerGroup();
            testCase.verifyError(@() smg.removeView(1), ...
                'statusMgr:StatusManagerGroup:indexOutOfRange')
        end

        % --- findViews / hasView -------------------------------------------

        function tFindViewsByClass(testCase)
            % findViews(Class=...) returns only the matching-type views.
            [smg, v1, v2] = testCase.groupWithCmdAndFileLog();

            found = smg.findViews(Class="statusMgr.view.FileLog");

            testCase.assertSize(found, [1 1])
            testCase.verifyEqual(found(1), v2)
            testCase.verifyEqual(smg.findViews(Class="statusMgr.view.CommandWindow"), v1)
        end

        function tFindViewsByInstance(testCase)
            % findViews(Instance=...) returns just that registered view.
            [smg, v1, ~] = testCase.groupWithCmdAndFileLog();

            found = smg.findViews(Instance=v1);

            testCase.assertSize(found, [1 1])
            testCase.verifyEqual(found(1), v1)
        end

        function tFindViewsNoCriteriaReturnsAll(testCase)
            [smg, ~, ~] = testCase.groupWithCmdAndFileLog();
            testCase.assertSize(smg.findViews(), [1 2])
        end

        function tFindViewsClassWithNoMatchIsEmpty(testCase)
            [smg, ~, ~] = testCase.groupWithCmdAndFileLog();
            testCase.verifyEmpty(smg.findViews(Class="statusMgr.view.Popup"))
        end

        function tHasView(testCase)
            [smg, v1, ~] = testCase.groupWithCmdAndFileLog();

            testCase.verifyTrue(smg.hasView(Class="statusMgr.view.FileLog"))
            testCase.verifyTrue(smg.hasView(Instance=v1))
            testCase.verifyFalse(smg.hasView(Class="statusMgr.view.Popup"))
        end

        % --- removeViews ----------------------------------------------------

        function tRemoveViewsByClass(testCase)
            % Removing by class detaches matches and returns them; the view
            % objects survive because Delete defaults to false.
            [smg, v1, v2] = testCase.groupWithCmdAndFileLog();

            removed = smg.removeViews(Class="statusMgr.view.FileLog");

            testCase.verifyEqual(removed, v2)
            testCase.verifyTrue(isvalid(v2))          % not deleted
            testCase.assertSize(smg.Views, [1 1])
            testCase.verifyEqual(smg.Views(1), v1)
        end

        function tRemoveViewsByInstance(testCase)
            [smg, v1, v2] = testCase.groupWithCmdAndFileLog();

            smg.removeViews(Instance=v1);

            testCase.assertSize(smg.Views, [1 1])
            testCase.verifyEqual(smg.Views(1), v2)
        end

        function tRemoveViewsDeleteDeletesObject(testCase)
            [smg, ~, v2] = testCase.groupWithCmdAndFileLog();

            smg.removeViews(Instance=v2, Delete=true);

            testCase.assertSize(smg.Views, [1 1])
            testCase.verifyFalse(isvalid(v2))         % deleted
        end

        function tRemoveViewsNoCriteriaErrors(testCase)
            % Guard against accidentally clearing every view.
            [smg, ~, ~] = testCase.groupWithCmdAndFileLog();
            testCase.verifyError(@() smg.removeViews(), ...
                'statusMgr:StatusManagerGroup:noMatchCriteria')
        end

        % --- addViewScoped --------------------------------------------------

        function tAddViewScopedRemovesOnCleanup(testCase)
            % Clearing the returned onCleanup removes only that view, and
            % leaves the (still valid) view object intact when Delete=false.
            smg = statusMgr.util.StatusManagerGroup();
            view = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(view))

            cleanup = smg.addViewScoped(view);
            testCase.assertSize(smg.Views, [1 1])

            clear cleanup    %#ok<NASGU> % triggers onCleanup

            testCase.assertSize(smg.Views, [1 0])
            testCase.verifyTrue(isvalid(view))
        end

        function tAddViewScopedRemovesOnlyRegisteredInstance(testCase)
            % A scoped view's cleanup must not disturb other views.
            smg = statusMgr.util.StatusManagerGroup();
            keep = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(keep))
            smg.addView(keep);

            scoped = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(scoped))
            cleanup = smg.addViewScoped(scoped); %#ok<NASGU>
            testCase.assertSize(smg.Views, [1 2])

            clear cleanup

            testCase.assertSize(smg.Views, [1 1])
            testCase.verifyEqual(smg.Views(1), keep)
        end

        function tAddViewScopedDeleteDeletesView(testCase)
            smg = statusMgr.util.StatusManagerGroup();
            view = statusMgr.view.CommandWindow(smg.Stack);

            cleanup = smg.addViewScoped(view, Delete=true); %#ok<NASGU>
            clear cleanup

            testCase.assertSize(smg.Views, [1 0])
            testCase.verifyFalse(isvalid(view))
        end

    end

    methods (Access = private)

        function [smg, v1, v2] = groupWithCmdAndFileLog(testCase)
            % A group holding a CommandWindow (v1) then a FileLog (v2).
            import matlab.unittest.fixtures.WorkingFolderFixture
            smg = statusMgr.util.StatusManagerGroup();

            v1 = statusMgr.view.CommandWindow(smg.Stack);
            testCase.addTeardown(@() delete(v1))

            fx = testCase.applyFixture(WorkingFolderFixture);
            v2 = statusMgr.view.FileLog(smg.Stack, LogFolder=fx.Folder);
            testCase.addTeardown(@() delete(v2))

            smg.addView(v1);
            smg.addView(v2);
        end

    end

end
