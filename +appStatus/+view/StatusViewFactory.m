classdef StatusViewFactory
    %StatusVIEWFACTORY 
  
    methods (Static)
        function obj = StatusView(statusStack, nvp)
            arguments
                statusStack = appStatus.stack.StatusStack
                nvp.Parent = []
                nvp.Silent = false
                nvp.BlockingDialougues = true
                nvp.TestMode (1,:) logical {mustBeScalarOrEmpty} = true(1,0)
            end

            % Choose test mode by default
            persistent testMode
            if isempty(testMode)
                testMode = false; % Should this be true for safety so default is test mode?
            end

            if ~isempty(nvp.TestMode)
                testMode = nvp.TestMode;
            end

            if testMode
                warning("Intland:StatusView:TestMode", "Test mode active. If this is intentional, turn off warning Intland:StatusView:TestMode");
            end

            if testMode
                obj = appStatus.CommandWindow(statusStack, "Silent", nvp.Silent);
            else
                obj = appStatus.StatusView(nvp.Parent, statusStack, "BlockingDialogues", nvp.BlockingDialougues);
            end

        end
    end
end

