classdef StatusManager < handle
    %STATUSMANAGER Singleton for managing a shared status stack and views.
    %
    % Provides an application-wide Stack observed by optional Popup,
    % CommandWindow, and FileLog views.
    %
    % Usage:
    %   mgr = statusMgr.util.StatusManager.instance();
    %   mgr = statusMgr.util.StatusManager.instance(Parent=fig);
    %   mgr = statusMgr.util.StatusManager.instance(Reset=true);
    %   mgr.Stack.addStatus(statusMgr.StatusType.Running, "Loading...");
    %
    % Note: construction arguments are only applied on the first call or
    % after Reset=true. Subsequent calls return the existing instance.

    properties (SetAccess = protected)
        Stack
        PopupView
        CommandView
        FileLogView
    end

    methods (Access = protected)

        function obj = StatusManager(nvp)
            arguments
                nvp.Parent                          = []
                nvp.EnablePopup         (1,1) logical = false
                nvp.EnableCommandWindow (1,1) logical = true
                nvp.EnableFileLog       (1,1) logical = false
                nvp.LogFolder           (1,1) string  = pwd
            end

            obj.Stack = statusMgr.Stack();

            if nvp.EnablePopup || ~isempty(nvp.Parent)
                obj.PopupView = statusMgr.view.Popup(nvp.Parent, obj.Stack);
            end

            if nvp.EnableCommandWindow
                obj.CommandView = statusMgr.view.CommandWindow(obj.Stack);
            end

            if nvp.EnableFileLog
                obj.FileLogView = statusMgr.view.FileLog(obj.Stack, LogFolder=nvp.LogFolder);
            end
        end

    end

    methods (Static)

        function obj = instance(nvp)
            %INSTANCE Return (or create) the singleton StatusManager.
            arguments
                nvp.Parent                          = []
                nvp.Reset               (1,1) logical = false
                nvp.EnablePopup         (1,1) logical = false
                nvp.EnableCommandWindow (1,1) logical = true
                nvp.EnableFileLog       (1,1) logical = false
                nvp.LogFolder           (1,1) string  = pwd
            end

            persistent stored

            if nvp.Reset || isempty(stored) || ~isvalid(stored)
                stored = statusMgr.util.StatusManager( ...
                    Parent=nvp.Parent, ...
                    EnablePopup=nvp.EnablePopup, ...
                    EnableCommandWindow=nvp.EnableCommandWindow, ...
                    EnableFileLog=nvp.EnableFileLog, ...
                    LogFolder=nvp.LogFolder);
            end

            obj = stored;
        end

    end

end
