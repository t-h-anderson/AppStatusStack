classdef tStatusManager < matlab.unittest.TestCase
    % Tests for the StatusManager singleton registry.
    %
    % Each test method gets a clean slate: the teardown added in
    % TestMethodSetup calls clear() with no arguments to reset the
    % singleton's dictionary before the next test runs.

    methods (TestMethodSetup)
        function resetSingleton(testCase)
            testCase.addTeardown(@() statusMgr.util.StatusManager.clear())
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

    end

end
