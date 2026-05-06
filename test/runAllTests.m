function results = runAllTests(nvp)
% Entry point to run all tests.
%
%   runAllTests
%   runAllTests(CollectCoverage=true)
%   runAllTests(CollectCoverage=true, CoverageFormat="cobertura")
%
% CoverageFormat:
%   "html"      - navigable multi-file HTML report (default)
%   "cobertura" - single Cobertura XML file (shareable / CI-friendly)
arguments
    nvp.CollectCoverage (1,1) logical = false
    nvp.CoverageFormat (1,1) string ...
        {mustBeMember(nvp.CoverageFormat, ["html", "cobertura"])} = "html"
end
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoverageReport
import matlab.unittest.plugins.codecoverage.CoberturaFormat

% Define relevant folders and file paths.
artifactsDir = fullfile(testroot, "artifacts");
junitFile = fullfile(artifactsDir, "JunitXMLResults.xml");

% Create test suite from all tests found in a given folder.
suite = matlab.unittest.TestSuite.fromFolder(testroot, IncludingSubfolders=true);

% Create test runner and add JUnit plugin for CI integration.
runner = matlab.unittest.TestRunner.withTextOutput(Verbosity=2);
runner.addPlugin(XMLPlugin.producingJUnitFormat(junitFile));

% Add coverage plugin, if required.
if nvp.CollectCoverage
    switch nvp.CoverageFormat
        case "html"
            producer = CoverageReport(fullfile(artifactsDir, "coverage"));
        case "cobertura"
            producer = CoberturaFormat(fullfile(artifactsDir, "coverage.xml"));
    end
    runner.addPlugin(CodeCoveragePlugin.forNamespace("statusMgr", ...
        MetricLevel="statement", ...
        IncludingInnerNamespaces=true, ...
        Producing=producer));
end

% Run tests.
results = runner.run(suite);

% Display results.
table(results)

end
