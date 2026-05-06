classdef PopupAccess < statusMgr.view.Popup
    % Subclass exposing protected helpers so tests can exercise default
    % argument values in popupAlert and displayRunning that are never
    % triggered by the dispatch path in standardDisplay.

    methods
        function callDisplayRunningNoCancellable(obj, status)
            obj.displayRunning(status); % cancellable default applies
        end

        function callPopupAlertDefaults(obj, status)
            obj.popupAlert(status); % title/icon defaults apply
        end
    end
end
