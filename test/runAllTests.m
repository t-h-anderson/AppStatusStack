function results = runAllTests(nvp)
% Entry point to run all tests.
arguments
    nvp.CollectCoverage (1,1) logical = false
end
import matlab.unittest.plugins.XMLPlugin

% Define relevant folders and file paths.
artifactsDir = fullfile(testroot, "artifacts");
coverageDir = fullfile(artifactsDir, "coverage");
junitFile = fullfile(artifactsDir, "JunitXMLResults.xml");

% Create test suite from all tests found in a given folder.
suite = matlab.unittest.TestSuite.fromFolder(testroot, IncludingSubfolders=true);

% Create test runner and add JUnit plugin for CI integration.
runner = matlab.unittest.TestRunner.withTextOutput(Verbosity=2);
runner.addPlugin(XMLPlugin.producingJUnitFormat(junitFile));

% Add coverage plugin, if required.
if nvp.CollectCoverage
    % TODO
end

% Run tests.
results = runner.run(suite);

% Display results.
table(results)

end
