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

        function tMakeReturnsStatusManagerGroup(testCase)
            smg = statusMgr.util.StatusManager.make();
            testCase.assertClass(smg, 'statusMgr.util.StatusManagerGroup')
            testCase.assertClass(smg.Stack, 'statusMgr.Stack')
        end

        function tMakeNoArgEquivalentToDefault(testCase)
            % make() and make("Default") return the same group.
            smg1 = statusMgr.util.StatusManager.make();
            smg2 = statusMgr.util.StatusManager.make("Default");
            testCase.verifyEqual(smg1, smg2)
        end

        function tMakeIsIdempotent(testCase)
            % Calling make() twice returns the same object unchanged.
            smg1 = statusMgr.util.StatusManager.make();
            smg2 = statusMgr.util.StatusManager.make();
            testCase.verifyEqual(smg1, smg2)
        end

        function tMakeNamedGroup(testCase)
            smg = statusMgr.util.StatusManager.make("MyGroup");
            testCase.assertClass(smg, 'statusMgr.util.StatusManagerGroup')
        end

        function tMakeDistinctNamedGroupsHaveSeparateStacks(testCase)
            smg1 = statusMgr.util.StatusManager.make("Group1");
            smg2 = statusMgr.util.StatusManager.make("Group2");
            testCase.verifyNotEqual(smg1, smg2)
            testCase.verifyNotEqual(smg1.Stack, smg2.Stack)
        end

        function tMakeWithCommandWindow(testCase)
            smg = statusMgr.util.StatusManager.make(EnableCommandWindow=true);
            testCase.addTeardown(@() delete(smg.Views))

            testCase.assertSize(smg.Views, [1 1])
            testCase.assertClass(smg.Views(1), 'statusMgr.view.CommandWindow')
        end

        function tMakeWithFileLog(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            fx = testCase.applyFixture(WorkingFolderFixture);

            smg = statusMgr.util.StatusManager.make(LogFolder=fx.Folder);

            testCase.assertSize(smg.Views, [1 1])
            testCase.assertClass(smg.Views(1), 'statusMgr.view.FileLog')
        end

        function tMakeWithMissingLogFolderCreatesNoFileLog(testCase)
            % Default LogFolder=string(nan) suppresses FileLog creation.
            smg = statusMgr.util.StatusManager.make();
            testCase.assertSize(smg.Views, [1 0])
        end

        function tMakeOnExistingGroupReturnsItUnchanged(testCase)
            % Second make() call with different args returns the original
            % group without modifying it.
            smg1 = statusMgr.util.StatusManager.make("MyGroup");
            smg2 = statusMgr.util.StatusManager.make("MyGroup", EnableCommandWindow=true);

            testCase.verifyEqual(smg1, smg2)
            testCase.assertSize(smg1.Views, [1 0])
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
            smg = statusMgr.util.StatusManager.make("MyGroup");
            result = statusMgr.util.StatusManager.get("MyGroup", Type="StatusManagerGroup");
            testCase.verifyEqual(result, smg)
        end

        function tGetTypeViews(testCase)
            smg = statusMgr.util.StatusManager.make("MyGroup");
            result = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.verifyEqual(result, smg.Views)
        end

        function tGetStackMatchesMakeStack(testCase)
            smg = statusMgr.util.StatusManager.make("MyGroup");
            stack = statusMgr.util.StatusManager.get("MyGroup");
            testCase.verifyEqual(stack, smg.Stack)
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

        function tClearThenMakeCreatesNewGroup(testCase)
            % After clearing, make() produces a fresh group with a new Stack.
            smg1 = statusMgr.util.StatusManager.make("MyGroup");
            statusMgr.util.StatusManager.clear("MyGroup");
            smg2 = statusMgr.util.StatusManager.make("MyGroup");

            testCase.verifyNotEqual(smg1, smg2)
            testCase.verifyNotEqual(smg1.Stack, smg2.Stack)
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
            smg = statusMgr.util.StatusManager.make("MyGroup");
            view = statusMgr.view.CommandWindow(statusMgr.Stack());
            testCase.addTeardown(@() delete(view))

            statusMgr.util.StatusManager.addView("MyGroup", view);

            views = statusMgr.util.StatusManager.get("MyGroup", Type="Views");
            testCase.assertSize(views, [1 1])
            testCase.verifyEqual(view.Stack, smg.Stack)
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
            stack1 = statusMgr.util.StatusManager.get();
            stack2 = statusMgr.util.StatusManager.get();
            testCase.verifyEqual(stack1, stack2)
        end

        function tViewsShareGroupStack(testCase)
            % Views created via make() are connected to the group's Stack.
            smg = statusMgr.util.StatusManager.make(EnableCommandWindow=true);
            testCase.addTeardown(@() delete(smg.Views))

            testCase.verifyEqual(smg.Views(1).Stack, smg.Stack)
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
