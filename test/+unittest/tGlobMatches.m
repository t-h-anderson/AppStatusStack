classdef tGlobMatches < matlab.unittest.TestCase
    % Tests for the statusMgr.util.globMatches helper.

    methods (Test)

        function tLiteralExactMatch(testCase)
            testCase.verifyTrue(statusMgr.util.globMatches("a:b", "a:b"))
            testCase.verifyFalse(statusMgr.util.globMatches("a:b", "a:c"))
        end

        function tPrefixWildcard(testCase)
            testCase.verifyTrue(statusMgr.util.globMatches("myapp:net:timeout", "myapp:net:*"))
            testCase.verifyFalse(statusMgr.util.globMatches("myapp:db:slow", "myapp:net:*"))
        end

        function tSuffixWildcard(testCase)
            testCase.verifyTrue(statusMgr.util.globMatches("error:net:timeout", "*:timeout"))
            testCase.verifyFalse(statusMgr.util.globMatches("error:net", "*:timeout"))
        end

        function tInfixWildcard(testCase)
            testCase.verifyTrue(statusMgr.util.globMatches("a:timeout:b", "*timeout*"))
            testCase.verifyTrue(statusMgr.util.globMatches("timeout", "*timeout*"))
            testCase.verifyFalse(statusMgr.util.globMatches("ok", "*timeout*"))
        end

        function tMultipleWildcards(testCase)
            testCase.verifyTrue(statusMgr.util.globMatches("a:b:c", "a:*:c"))
            testCase.verifyTrue(statusMgr.util.globMatches("a::c", "a:*:c"))
            testCase.verifyFalse(statusMgr.util.globMatches("a:b:d", "a:*:c"))
        end

        function tStarMatchesEverything(testCase)
            testCase.verifyTrue(statusMgr.util.globMatches("anything", "*"))
            testCase.verifyTrue(statusMgr.util.globMatches("", "*"))
        end

    end

end
