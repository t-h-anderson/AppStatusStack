classdef StatusManager < handle
    %STATUSMANAGER Singleton registry of named StatusManagerGroups.
    %
    % Each group holds a Stack and zero or more views, keyed by name.
    % The "Default" group is created automatically on first access.
    %
    % Creating and clearing groups:
    %   smg = statusMgr.util.StatusManager.make()
    %   smg = statusMgr.util.StatusManager.make("MyGroup", PopupParent=fig, ...
    %             EnableCommandWindow=true, LogFolder="/logs")
    %   statusMgr.util.StatusManager.clear()           % remove all groups
    %   statusMgr.util.StatusManager.clear("MyGroup")  % remove one group
    %
    % Retrieving state (Type defaults to "Stack"):
    %   stack = statusMgr.util.StatusManager.get()
    %   stack = statusMgr.util.StatusManager.get("MyGroup")
    %   smg   = statusMgr.util.StatusManager.get(Type="StatusManagerGroup")
    %   views = statusMgr.util.StatusManager.get("MyGroup", Type="Views")
    %
    % Managing views:
    %   statusMgr.util.StatusManager.addPopup("MyGroup", Parent=fig)
    %   statusMgr.util.StatusManager.addCommandWindow("MyGroup")
    %   statusMgr.util.StatusManager.addFileLog("MyGroup", LogFolder="/logs")
    %   statusMgr.util.StatusManager.addView("MyGroup", existingView)
    %   statusMgr.util.StatusManager.removeView("MyGroup", idx)

    methods (Access = private)
        function obj = StatusManager()
            % Private constructor — this class cannot be instantiated.
        end
    end

    methods (Static)

        function smg = make(name, nvp)
            %MAKE Return or create a named StatusManagerGroup.
            %
            % If the group already exists it is returned unchanged.
            % Construction arguments are only applied on first creation.
            % LogFolder=string(nan) (default) suppresses FileLog creation.
            arguments
                name                        (1,1) string  = "Default"
                nvp.PopupParent                           = []
                nvp.EnableCommandWindow     (1,1) logical = false
                nvp.LogFolder               (1,1) string  = string(nan)
            end

            m = statusMgr.util.StatusManager.groups();

            if isKey(m, char(name))
                smg = m(char(name));
                return
            end

            smg = statusMgr.util.StatusManagerGroup();

            if ~isempty(nvp.PopupParent)
                smg.addView(statusMgr.view.Popup(nvp.PopupParent, smg.Stack));
            end
            if nvp.EnableCommandWindow
                smg.addView(statusMgr.view.CommandWindow(smg.Stack));
            end
            if ~ismissing(nvp.LogFolder)
                smg.addView(statusMgr.view.FileLog(smg.Stack, LogFolder=nvp.LogFolder));
            end

            m(char(name)) = smg;
        end

        function result = get(name, nvp)
            %GET Retrieve state from a named StatusManagerGroup.
            %
            % Returns the Stack by default. Use Type= to return the group
            % or its views. The "Default" group is created automatically if
            % it does not exist; all other names error if not found.
            arguments
                name     (1,1) string = "Default"
                nvp.Type (1,1) string ...
                    {mustBeMember(nvp.Type, ["Stack", "StatusManagerGroup", "Views"])} ...
                    = "Stack"
            end

            m = statusMgr.util.StatusManager.groups();

            if name == "Default" && ~isKey(m, "Default")
                statusMgr.util.StatusManager.make("Default");
            elseif ~isKey(m, char(name))
                error("statusMgr:StatusManager:unknownGroup", ...
                    "No group named '%s'. Call StatusManager.make() first.", name);
            end

            smg = m(char(name));

            switch nvp.Type
                case "Stack"
                    result = smg.Stack;
                case "StatusManagerGroup"
                    result = smg;
                case "Views"
                    result = smg.Views;
            end
        end

        function clear(name)
            %CLEAR Remove a group by name, or all groups if no name is given.
            arguments
                name (1,1) string = string(nan)
            end
            m = statusMgr.util.StatusManager.groups();
            if ismissing(name)
                remove(m, keys(m));
            elseif isKey(m, char(name))
                remove(m, char(name));
            else
                error("statusMgr:StatusManager:unknownGroup", ...
                    "No group named '%s'.", name);
            end
        end

        function addPopup(name, nvp)
            %ADDPOPUP Add a Popup view to a named group.
            arguments
                name       (1,1) string = "Default"
                nvp.Parent               = []
            end
            smg = statusMgr.util.StatusManager.get(name, Type="StatusManagerGroup");
            smg.addView(statusMgr.view.Popup(nvp.Parent, smg.Stack));
        end

        function addCommandWindow(name)
            %ADDCOMMANDWINDOW Add a CommandWindow view to a named group.
            arguments
                name (1,1) string = "Default"
            end
            smg = statusMgr.util.StatusManager.get(name, Type="StatusManagerGroup");
            smg.addView(statusMgr.view.CommandWindow(smg.Stack));
        end

        function addFileLog(name, nvp)
            %ADDFILELOG Add a FileLog view to a named group.
            arguments
                name          (1,1) string              = "Default"
                nvp.LogFolder (1,1) string {mustBeFolder} = pwd
            end
            smg = statusMgr.util.StatusManager.get(name, Type="StatusManagerGroup");
            smg.addView(statusMgr.view.FileLog(smg.Stack, LogFolder=nvp.LogFolder));
        end

        function addView(name, view)
            %ADDVIEW Add an existing view object to a named group.
            %
            % The view's Stack is updated to match the group's Stack.
            arguments
                name (1,1) string
                view (1,1) statusMgr.internal.view.StatusViewInterface
            end
            smg = statusMgr.util.StatusManager.get(name, Type="StatusManagerGroup");
            smg.addView(view);
        end

        function removeView(name, idx)
            %REMOVEVIEW Remove the view at position idx from a named group.
            arguments
                name (1,1) string
                idx  (1,1) double {mustBeInteger, mustBePositive}
            end
            smg = statusMgr.util.StatusManager.get(name, Type="StatusManagerGroup");
            smg.removeView(idx);
        end

    end

    methods (Static, Access = private)

        function m = groups()
            %GROUPS Return the persistent containers.Map of StatusManagerGroups.
            %
            % containers.Map is a handle type, so all static methods share
            % the same map instance without a dispatcher wrapper.
            persistent map
            if isempty(map)
                map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            end
            m = map;
        end

    end

end
