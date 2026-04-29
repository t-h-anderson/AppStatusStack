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
            testCase.verifyClass(S.Timestamp, "datetime");
            testCase.verifyFalse(isnat(S.Timestamp));
            testCase.verifyThat(S.User, Matches("^.+$"));
        end

        function tUserAndTimestampSetAtCreation(testCase)
            % User and Timestamp are captured automatically at construction.
            before = datetime("now");
            S = statusMgr.Status();
            after = datetime("now");

            testCase.verifyGreaterThanOrEqual(S.Timestamp, before);
            testCase.verifyLessThanOrEqual(S.Timestamp, after);

            expectedUser = string(getenv("USER"));
            if expectedUser == ""
                expectedUser = string(getenv("USERNAME"));
            end
            testCase.verifyEqual(S.User, expectedUser);
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