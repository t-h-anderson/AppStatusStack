classdef tFullIntegration < matlab.unittest.TestCase
    %tFullIntegration Test random string generation

    properties
        Stack
        StackView
    end
    
    methods (TestClassSetup)
        function setup(testCase)
           testCase.createStack(); 
           testCase.createView();
        end
    end
    
    methods
        function createStack(testCase)
           testCase.Stack = appStatus.stack.StatusStack(); 
        end
        
        function createView(testCase)
            %% TODO: make fixture
            f = uifigure();
            testCase.addTeardown(@delete, f);

            testCase.StackView = appStatus.view.Popup(f, testCase.Stack);
        end
    end
    
    methods (Test)
        
        function testError(testCase)
            %DOTEST
            [~, err] = testCase.Stack.addCondition(appStatus.Condition.Error, "Message", "My Error Message");
            currentStatus = testCase.Stack.CurrentStatus;
                        
            while ~currentStatus.IsComplete
                pause(0.5);
                fprintf('.');
            end
        end
    end
end

