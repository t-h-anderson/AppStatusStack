classdef tStatus < matlab.unittest.TestCase

    methods (Test)

        function tDefaultStatus(testCase)
            % Check the default Status properties.
            import matlab.unittest.constraints.Matches

            S = statusMgr.Status();

            testCase.verifyThat(S.ID, Matches("^.+$"));
            testCase.verifyEqual(S.Identifier, "");
            testCase.verifyTrue(S.IsVisible);
            testCase.verifyEqual(S.Message, "");
            testCase.verifyEqual(S.Title, "");
            testCase.verifyEqual(S.MessageShort, "");
            testCase.verifyEqual(S.Value, NaN);
            testCase.verifyEmpty(S.Data);
            testCase.verifyFalse(S.IsTemporary);
            testCase.verifyFalse(S.IsComplete);
        end

        function tStatusWithTitle(testCase)
            % Title is set via constructor name-value pair.
            S = statusMgr.Status("Running", "Working...", Title="My Title");

            testCase.verifyEqual(S.Title, "My Title");
        end

        function tStatusWithMissingTitle(testCase)
            % A missing string is a valid Title value (ismissing returns true).
            S = statusMgr.Status("Running", "", Title=string(missing));

            testCase.verifyTrue(ismissing(S.Title));
        end

    end


end