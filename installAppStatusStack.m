function installappStatus(nvp)
% Install method to make sure appStatus is installed and up-to-date
% Include in other projects' startup to automatically install this
% dependency
% Note: Add default toolbox path is "dependencies" folder

arguments
    nvp.RequiredVersion = ""
    nvp.ToolboxPath = "./dependencies";
end

requiredVersion= nvp.RequiredVersion;

% Get installed toolbox version
toolboxes = matlab.addons.toolbox.installedToolboxes;
toolboxNames = string({toolboxes.Name});
installedIdx = contains(toolboxNames, "appStatus");

if any(installedIdx) 
    installedVersion = toolboxes(installedIdx).Version;
else
    installedVersion = "";
end

% Return if toolbox is installed and it matches the required version
if any(installedIdx) && installedVersion == requiredVersion
    fprintf("appStatus (Ver. %s) matches requirement.\n", requiredVersion);
    return
end

% Get available versions
tbxPath = fullfile(nvp.ToolboxPath, "*.mltbx");
tbxs = dir(tbxPath);

if isempty(tbxs)
    error("No appStatus toolboxes available in %s", nvp.ToolboxPath);
end

% Get list of available versions
vers = arrayfun(@(x) string(matlab.addons.toolbox.toolboxVersion(fullfile(x.folder, x.name))), tbxs);

if requiredVersion == ""
    % If specific version isn't required get latest
    [maxVersion, idx] = maxVer(vers);    
    
    if maxVersion == installedVersion
        fprintf("appStatus up-to-date (Ver. %s).\n", maxVersion);
        return
    end
else
    idx = (vers == requiredVersion);
    
    if ~any(idx)
        error("appStatus (Ver. %s) not found in %s.", nvp.RequiredVersion, nvp.ToolboxPath)
    end 
end
    
tbxName = tbxs(idx).name;
latestTbxPath = fullfile(tbxs(idx).folder, tbxName);

matlab.addons.toolbox.installToolbox(latestTbxPath);
fprintf("appStatus (Ver. %s) installed.\n", vers(idx));

end


function [value, idx] = maxVer(vers)
arguments
    vers(1, :) string
end

% Split at points
splitUp = arrayfun(@(x) strsplit(x, "."), vers, "UniformOutput", false);

% Get number of version levels
levels = cellfun(@(x) numel(x), splitUp);
maxLevel = max(levels);

% Pad version levels with 0 if there is variation
for i = 1:numel(levels)
    levelsToAdd = maxLevel - levels(i);
    zeroPadding = repmat("0", 1, levelsToAdd);
    splitUp{i} = [splitUp{i}, zeroPadding];
end

% Get list of separated and padded version numbers
splitUp = vertcat(splitUp{:});

% Iteratively 'clear' rows that are not maximal
for i = 1:size(splitUp, 2)
    iMax = string(max(str2double(splitUp(:, i))));
    splitUp(splitUp(:, i) ~= iMax, :) = "";
end

% Get indices of noncleared rows
idx = any(strlength(splitUp) ~= 0, 2);

% Get max version
value = vers(idx);

end