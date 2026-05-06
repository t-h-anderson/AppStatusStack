classdef tCancellationToken < matlab.unittest.TestCase

    methods (Test)

        function tDefaultIsNotCancelled(testCase)
            t = statusMgr.CancellationToken();
            testCase.verifyFalse(t.IsCancelled)
            testCase.verifyFalse(t.IsCancellationRequested())
        end

        function tCancelFlipsTheFlag(testCase)
            t = statusMgr.CancellationToken();
            t.cancel();
            testCase.verifyTrue(t.IsCancelled)
            testCase.verifyTrue(t.IsCancellationRequested())
        end

        function tCancelIsIdempotent(testCase)
            t = statusMgr.CancellationToken();
            t.cancel();
            t.cancel();
            testCase.verifyTrue(t.IsCancelled)
        end

        function tThrowIfCancellationRequestedIsNoOpWhenNotCancelled(testCase)
            t = statusMgr.CancellationToken();
            testCase.verifyWarningFree(@() t.throwIfCancellationRequested());
        end

        function tThrowIfCancellationRequestedRaisesAfterCancel(testCase)
            t = statusMgr.CancellationToken();
            t.cancel();
            testCase.verifyError(@() t.throwIfCancellationRequested(), ...
                "statusMgr:cancelled")
        end

        function tIsCancelledIsObservable(testCase)
            % SetObservable means callers can use waitfor on it. Verify
            % the property exists with that attribute.
            t = statusMgr.CancellationToken();
            mc = metaclass(t);
            prop = findobj(mc.PropertyList, "Name", "IsCancelled");
            testCase.assertNotEmpty(prop)
            testCase.verifyTrue(prop.SetObservable)
        end

    end

end
