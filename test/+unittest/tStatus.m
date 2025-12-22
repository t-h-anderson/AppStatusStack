classdef tStatus < matlab.unittest.TestCase

    methods (Test)

        function tDefaultStatus(testCase)
            % Check the default Status properties.
            import matlab.unittest.constraints.Matches
            
            S = appStatus.Status();

            testCase.verifyThat(S.ID, Matches("^.+$"));
            testCase.verifyTrue(S.IsVisible);
            testCase.verifyEqual(S.Message, "");
            testCase.verifyEqual(S.MessageShort, "");
            testCase.verifyEqual(S.Value, NaN);
            testCase.verifyEmpty(S.Data);
            testCase.verifyFalse(S.IsTemporary);
            testCase.verifyFalse(S.IsBlocking);
            testCase.verifyFalse(S.IsComplete);
        end

    end


end