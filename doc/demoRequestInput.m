%[text] # Demo: requestInput
%[text] This script demonstrates the three ways `requestInput` can behave depending
%[text] on which views are attached to the stack.

%% Setup
stack = statusMgr.Stack();

%% 1. No view — returns default after timeout
%[text] With no view attached the request times out and the default value is
%[text] returned.  The timeout here is kept short for demo purposes.
value = stack.requestInput("Enter your name", DefaultValue="World");
fprintf("No-view result: Hello, %s!\n", value);

%% 2. CommandWindow view — blocks on terminal input
%[text] Attach a CommandWindow view.  `requestInput` will print the prompt and
%[text] wait for you to type a value in the Command Window.
cmdView = statusMgr.view.CommandWindow(stack);

name = stack.requestInput("Enter your name", DefaultValue="World");
fprintf("CommandWindow result: Hello, %s!\n", name);

delete(cmdView)

%% 3. Popup view — shows a modal input dialog
%[text] Attach a Popup view.  `requestInput` will open a small dialog and wait
%[text] for you to type a value and click OK (or close the window to accept the
%[text] default).
f = uifigure("Name", "requestInput demo", "Position", [100 100 400 200]);
popupView = statusMgr.view.Popup(f, stack);

name = stack.requestInput("Enter your name", DefaultValue="World");
fprintf("Popup result: Hello, %s!\n", name);

delete(f)
delete(popupView)

%% 4. HandleInputRequests = false — view ignores the request
%[text] Setting `HandleInputRequests = false` on a view means it will not claim
%[text] the request.  The stack falls back to the default after the timeout.
cmdView2 = statusMgr.view.CommandWindow(stack);
cmdView2.HandleInputRequests = false;

name = stack.requestInput("Enter your name", DefaultValue="World");
fprintf("Ignored result: Hello, %s!\n", name);

delete(cmdView2)

