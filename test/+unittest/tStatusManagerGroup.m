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

    end

end
