classdef cancellableProgressDlg < matlab.ui.dialog.ProgressDialog

    events
        CancelRequestTriggered
    end

    methods

        function obj = cancellableProgressDlg(varargin)
            arguments (Repeating)
                varargin
            end

            obj = obj@matlab.ui.dialog.ProgressDialog(varargin{:}, "Cancelable", true);

            % Get the progress dialog controller object which interacts
            % with the javascript view
            s = warning();
            warning("off")
            cc = struct(obj).Controller;
            warning(s);

            % Listen to the controller being destroyed and remove the
            % internal listener if it is
            addlistener(obj, "ObjectBeingDestroyed", @(~, ~) matlab.ui.internal.dialog.ProgressDialogController.unsubscribeToCancelCallback(cc.CallbackChannelID));

            % Listen to the cancel callback
            matlab.ui.internal.dialog.ProgressDialogController.subscribeToCancelCallback(cc.CallbackChannelID);
            message.subscribe(cc.CallbackChannelID, @(~) obj.respondToCancelRequest);

        end

    end

    methods (Access = protected)
        function respondToCancelRequest(obj)
            notify(obj, "CancelRequestTriggered")
            delete(obj)
        end
    end

end