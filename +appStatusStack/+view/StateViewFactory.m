classdef StateViewFactory
    %STATEVIEWFACTORY 
  
    methods (Static)
        function obj = stateView(statusStack, nvp)
            arguments
                statusStack = appStatusStack.state.StatusStack
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
                warning("Intland:StateView:TestMode", "Test mode active. If this is intentional, turn off warning Intland:StateView:TestMode");
            end

            if testMode
                obj = appStatusStack.StateViewCommandWindow(statusStack, "Silent", nvp.Silent);
            else
                obj = appStatusStack.StateView(nvp.Parent, statusStack, "BlockingDialogues", nvp.BlockingDialougues);
            end

        end
    end
end

