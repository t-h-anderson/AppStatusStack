classdef WarningCapture < handle
    %WARNINGCAPTURE Detect any MATLAB warning issued in a scope.
    %
    % The constructor saves the current warning state, silences warnings
    % so they do not pollute the command window during the captured
    % region, and seeds `lastwarn` with a UUID sentinel so any later
    % `lastwarn` change can be unambiguously attributed to a warning
    % issued during the scope.
    %
    % Usage:
    %   captor = statusMgr.util.WarningCapture();
    %   ... code that might issue warnings ...
    %   [msg, id] = captor.warning();
    %   if msg ~= ""
    %       % a warning was issued during the captured region
    %   end
    %   % warning() state is restored automatically when captor is deleted

    properties (SetAccess = private)
        Sentinel (1,1) string
    end

    properties (Access = private)
        SavedState
    end

    methods
        function obj = WarningCapture()
            obj.SavedState = warning();
            warning("off");
            obj.Sentinel = statusMgr.util.uuid();
            warning(obj.Sentinel, obj.Sentinel);
        end

        function [msg, id] = warning(obj)
            % Return the warning message and identifier of the last
            % warning issued since this capture started, or empty
            % strings if none was issued. "MATLAB:callback:error" is
            % filtered out — these come from errors raised inside
            % unrelated callbacks during the captured region.
            [w, c] = lastwarn;
            if strcmp(c, obj.Sentinel) || strcmp(c, "MATLAB:callback:error")
                msg = "";
                id = "";
            else
                msg = string(w);
                id = string(c);
            end
        end

        function delete(obj)
            warning(obj.SavedState);
        end
    end
end
