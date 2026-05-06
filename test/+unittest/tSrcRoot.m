classdef tSrcRoot < matlab.unittest.TestCase
    % Smoke test for the srcRoot helper.

    methods (Test)

        function tReturnsSrcDirectory(testCase)
            % srcRoot strips three levels off its own path, landing on
            % the src folder (the parent of +statusMgr).
            root = statusMgr.util.srcRoot();

            testCase.assertClass(root, "char")
            testCase.verifyEqual( ...
                exist(fullfile(root, "+statusMgr"), "dir"), 7)
        end

    end

end
