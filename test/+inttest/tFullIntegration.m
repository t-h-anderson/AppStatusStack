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
           testCase.Stack = appStatusStack.stack.StatusStack(); 
        end
        
        function createView(testCase)
            %% TODO: make fixture
            f = uifigure();
            testCase.addTeardown(@delete, f);

            testCase.StackView = appStatusStack.view.StateViewPopup(f, testCase.Stack);
        end
    end
    
    methods (Test)
        
        function testError(testCase)
            %DOTEST
            
            [~, err] = testCase.Stack.addState(appStatusStack.State.Error, "Message", "My Error Message");
           
            currentStatus = testCase.Stack.CurrentStatus;
                        
            while currentStatus.State ~= appStatusStack.State.Idle
                pause(0.5);
                fprintf('.');
                
                currentStatus = testCase.Stack.CurrentStatus;
            end
            
        end
           
    end
end

