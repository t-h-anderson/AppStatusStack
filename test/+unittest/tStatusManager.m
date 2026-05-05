classdef tStatusManager < matlab.unittest.TestCase
    % Tests for the StatusManager singleton registry.
    %
    % Each test method gets a clean slate: the teardown added in
    % TestMethodSetup calls clear() with no arguments to reset the
    % singleton's dictionary before the next test runs.

    methods (TestMethodSetup)
        function saveState(testCase)
            % Capture the singleton and its Groups dictionary before the
            % test runs, then restore both afterwards. This leaves any
            % pre-existing singleton completely intact.
            token = statusMgr.util.StatusManager.snapshot();
            testCase.addTeardown(@() statusMgr.util.StatusManager.restore(token))
        end
    end

    methods (Test)

        % --- make -----------------------------------------------------------

        function tMakeReturnsStack(testCase)
            % make() returns the Stack for the group, not the group itself.
            stack = statusMgr.util.StatusManager.make();
            testCase.assertClass(stack, 'statusMgr.Stack')
        end

        function tMakeNoArgEquivalentToDefault(testCase)
            % make() and make("Default") return the same Stack.
            s1 = statusMgr.util.StatusManager.make();
            s2 = statusMgr.util.StatusManager.make("Default");
            testCase.verifyEqual(s1, s2)
        end

        function tMakeIsIdempotent(testCase)
            % Calling make() twice returns the same Stack unchanged.
            s1 = statusMgr.util.StatusManager.make();
            s2 = statusMgr.util.StatusManager.make();
            testCase.verifyEqual(s1, s2)
        end

        function tMakeNamedGroup(testCase)
            stack = statusMgr.util.StatusManager.make("MyGroup");
            testCase.assertClass(stack, 'statusMgr.Stack')
        end

        function tMakeDistinctNamedGroupsHaveSeparateStacks(testCase)
            s1 = statusMgr.util.StatusManager.make("Group1");
            s2 = statusMgr.util.StatusManager.make("Group2");
            testCase.verifyNotEqual(s1, s2)
        end

        function tMakeWithCommandWindow(testCase)
            statusMgr.util.StatusManager.make(EnableCommandWindow=true);
            smg = statusMgr.util.StatusManager.get(Type="StatusManagerGroup");
            testCase.addTeardown(@() delete(smg.Views))

            testCase.assertSize(smg.Views, [1 1])
            testCase.assertClass(smg.Views(1), 'statusMgr.view.CommandWindow')
        end

        function tMakeWithFileLog(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            fx = testCase.applyFixture(WorkingFolderFixture);

            statusMgr.util.StatusManager.make(LogFolder=fx.Folder);
            smg = statusMgr.util.StatusManager.get(Type="StatusManagerGroup");

            testCase.assertSize(smg.Views, [1 1])
            testCase.assertClass(smg.Views(1), 'statusMgr.view.FileLog')
        end

        function tMakeWithMissingLogFolderCreatesNoFileLog(testCase)
            % Default LogFolder=string(nan) suppresses FileLog creation.
            statusMgr.util.StatusManager.make();
            smg = statusMgr.util.StatusManager.get(Type="StatusManagerGroup");
            testCase.assertSize(smg.Views, [1 0])
        end

        function tMakeOnExistingGroupReturnsItUnchanged(testCase)
            % Second make() call with different args returns the original
            % Stack; the group's Views are not modified.
            s1 = statusMgr.util.StatusManager.make("MyGroup");
            s2 = statusMgr.util.StatusManager.make("MyGroup", EnableCommandWindow=true);

            testCase.verifyEqual(s1, s2)
            smg = statusMgr.util.StatusManager.get("MyGroup", Type="StatusManagerGroup");
            testCase.assertSize(smg.Views, [1 0])
        end

        % --- get ------------------------------------------------------------

        function tGetDefaultReturnsStack(testCase)
            statusMgr.util.StatusManager.make();
            result = statusMgr.util.StatusManager.get();
            testCase.assertClass(result, 'statusMgr.Stack')
        end

        function tGetAutoCreatesDefaultGroup(testCase)
            % get() with no args creates "Default" if it does not exist.
            result = statusMgr.util.StatusManager.get();
            testCase.assertClass(result, 'statusMgr.Stack')
        end

        function tGetTypeStack(testCase)
            statusMgr.util.StatusManager.make("MyGroup");
            result = statusMgr.util.StatusManager.get("MyGroup", Type="Stack");
            testCase.assertClass(result, 'statusMgr.Stack')
        end

        function tGetTypeStatusManagerGroup(testCase)
            statusMgr.util.StatusManager.make("MyGroup");
            result = statusMgr.util.StatusManager.get("MyGroup", Type="StatusManagerGroup");
            testCase.assertClass(result, 'statusMgr.util.StatusManagerGroup')
        end

        function tGetTypeViews(testCase)
            statusMgr.util.StatusManager.make("MyGroup");
            result = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.assertSize(result, [1 0])
        end

        function tGetStackMatchesMakeStack(testCase)
            makeStack = statusMgr.util.StatusManager.make("MyGroup");
            getStack  = statusMgr.util.StatusManager.get("MyGroup");
            testCase.verifyEqual(makeStack, getStack)
        end

        function tGetUnknownGroupErrors(testCase)
            testCase.verifyError( ...
                @() statusMgr.util.StatusManager.get("NonExistent"), ...
                'statusMgr:StatusManager:unknownGroup')
        end

        % --- clear ----------------------------------------------------------

        function tClearAllGroups(testCase)
            statusMgr.util.StatusManager.make("A");
            statusMgr.util.StatusManager.make("B");

            statusMgr.util.StatusManager.clear();

            testCase.verifyError( ...
                @() statusMgr.util.StatusManager.get("A"), ...
                'statusMgr:StatusManager:unknownGroup')
            testCase.verifyError( ...
                @() statusMgr.util.StatusManager.get("B"), ...
                'statusMgr:StatusManager:unknownGroup')
        end

        function tClearNamedGroupLeavesOthersIntact(testCase)
            statusMgr.util.StatusManager.make("A");
            statusMgr.util.StatusManager.make("B");

            statusMgr.util.StatusManager.clear("A");

            testCase.verifyError( ...
                @() statusMgr.util.StatusManager.get("A"), ...
                'statusMgr:StatusManager:unknownGroup')
            testCase.assertClass( ...
                statusMgr.util.StatusManager.get("B"), 'statusMgr.Stack')
        end

        function tClearUnknownGroupErrors(testCase)
            testCase.verifyError( ...
                @() statusMgr.util.StatusManager.clear("NonExistent"), ...
                'statusMgr:StatusManager:unknownGroup')
        end

        function tClearThenMakeCreatesNewStack(testCase)
            % After clearing a group, make() produces a fresh Stack.
            s1 = statusMgr.util.StatusManager.make("MyGroup");
            statusMgr.util.StatusManager.clear("MyGroup");
            s2 = statusMgr.util.StatusManager.make("MyGroup");
            testCase.verifyNotEqual(s1, s2)
        end

        % --- addCommandWindow / addFileLog / addView / removeView -----------

        function tAddCommandWindow(testCase)
            statusMgr.util.StatusManager.make("MyGroup");
            statusMgr.util.StatusManager.addCommandWindow("MyGroup");

            views = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.assertSize(views, [1 1])
            testCase.assertClass(views(1), 'statusMgr.view.CommandWindow')
        end

        function tAddCommandWindowDefaultGroup(testCase)
            % No name argument operates on the "Default" group,
            % creating it automatically if needed.
            statusMgr.util.StatusManager.addCommandWindow();

            views = statusMgr.util.StatusManager.get(Type="Views");
            testCase.assertSize(views, [1 1])
            testCase.assertClass(views(1), 'statusMgr.view.CommandWindow')
        end

        function tAddFileLog(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            fx = testCase.applyFixture(WorkingFolderFixture);

            statusMgr.util.StatusManager.make("MyGroup");
            statusMgr.util.StatusManager.addFileLog("MyGroup", LogFolder=fx.Folder);

            views = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.assertSize(views, [1 1])
            testCase.assertClass(views(1), 'statusMgr.view.FileLog')
        end

        function tAddExistingView(testCase)
            % addView reconnects an existing view to the group's Stack.
            stack = statusMgr.util.StatusManager.make("MyGroup");
            view = statusMgr.view.CommandWindow(statusMgr.Stack());
            testCase.addTeardown(@() delete(view))

            statusMgr.util.StatusManager.addView("MyGroup", view);

            views = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.assertSize(views, [1 1])
            testCase.verifyEqual(view.Stack, stack)
        end

        function tRemoveView(testCase)
            statusMgr.util.StatusManager.make("MyGroup");
            statusMgr.util.StatusManager.addCommandWindow("MyGroup");

            statusMgr.util.StatusManager.removeView("MyGroup", 1);

            views = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.assertSize(views, [1 0])
        end

        % --- singleton and Stack sharing ------------------------------------

        function tGetReturnsSameStackAcrossCalls(testCase)
            % The singleton returns the same Stack object on every call.
            s1 = statusMgr.util.StatusManager.get();
            s2 = statusMgr.util.StatusManager.get();
            testCase.verifyEqual(s1, s2)
        end

        function tViewsShareGroupStack(testCase)
            % Views created via make() are connected to the group's Stack.
            stack = statusMgr.util.StatusManager.make(EnableCommandWindow=true);
            smg = statusMgr.util.StatusManager.get(Type="StatusManagerGroup");
            testCase.addTeardown(@() delete(smg.Views))

            testCase.verifyEqual(smg.Views(1).Stack, stack)
        end

        function tStatusAddedToStackVisibleViaGet(testCase)
            % A status pushed onto the retrieved Stack is reflected in the
            % group's Stack — they are the same object.
            stack = statusMgr.util.StatusManager.get();
            stack.addStatus("Info", Message="hello");

            smg = statusMgr.util.StatusManager.get(Type="StatusManagerGroup");
            testCase.verifyEqual(smg.Stack.CurrentStatus.Message, "hello")
        end

        % --- snapshot / restore ---------------------------------------------

        function tSnapshotCapturesExistingInstance(testCase)
            % snapshot() taken with a live singleton records hasInstance=true
            % and the current Groups dictionary.
            statusMgr.util.StatusManager.make("X");

            token = statusMgr.util.StatusManager.snapshot();

            testCase.verifyTrue(token.hasInstance)
            testCase.assertClass(token.instance, 'statusMgr.util.StatusManager')
            testCase.verifyTrue(isKey(token.groups, "X"))
        end

        function tRestoreReinstatesPreviousGroupsDict(testCase)
            % Modifying groups after a snapshot, then restoring, returns the
            % singleton to the snapshotted state — exercises the "instance
            % still valid" branch of restore().
            statusMgr.util.StatusManager.make("Original");
            token = statusMgr.util.StatusManager.snapshot();

            statusMgr.util.StatusManager.make("AddedAfter");
            testCase.assertClass( ...
                statusMgr.util.StatusManager.get("AddedAfter"), 'statusMgr.Stack')

            statusMgr.util.StatusManager.restore(token);

            testCase.assertClass( ...
                statusMgr.util.StatusManager.get("Original"), 'statusMgr.Stack')
            testCase.verifyError( ...
                @() statusMgr.util.StatusManager.get("AddedAfter"), ...
                'statusMgr:StatusManager:unknownGroup')
        end

        function tRestoreFallsBackWhenInstanceInvalid(testCase)
            % If the snapshotted instance has been deleted, restore() clears
            % the persistent and a fresh singleton is created on next access.
            statusMgr.util.StatusManager.make();
            token = statusMgr.util.StatusManager.snapshot();

            % Forcefully delete the snapshotted singleton.
            delete(token.instance);
            testCase.assertFalse(isvalid(token.instance))

            statusMgr.util.StatusManager.restore(token);

            % A fresh instance is created on next access.
            stack = statusMgr.util.StatusManager.get();
            testCase.assertClass(stack, 'statusMgr.Stack')
        end

        % --- addPopup -------------------------------------------------------

        function tAddPopup(testCase)
            % addPopup() attaches a Popup view to a named group.
            fig = uifigure;
            testCase.addTeardown(@() delete(fig))

            statusMgr.util.StatusManager.make("MyGroup");
            statusMgr.util.StatusManager.addPopup("MyGroup", Parent=fig);

            views = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.assertSize(views, [1 1])
            testCase.assertClass(views(1), 'statusMgr.view.Popup')
        end

        function tAddPopupNoArgsUsesDefaultGroupAndParent(testCase)
            % addPopup() with no arguments operates on the Default group
            % and applies the empty Parent default.
            statusMgr.util.StatusManager.addPopup();

            views = statusMgr.util.StatusManager.get(Type="Views");
            testCase.assertSize(views, [1 1])
            testCase.assertClass(views(1), 'statusMgr.view.Popup')
            testCase.addTeardown(@() delete(views(1)))
        end

        function tMakeWithPopupParent(testCase)
            % make(PopupParent=fig) attaches a Popup to the group on
            % first creation. Covers the PopupParent branch in make().
            fig = uifigure;
            testCase.addTeardown(@() delete(fig))

            statusMgr.util.StatusManager.make("MyGroup", PopupParent=fig);

            views = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.assertSize(views, [1 1])
            testCase.assertClass(views(1), 'statusMgr.view.Popup')
        end

    end

end
