# Status Manager

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=t-h-anderson/AppStatusStack&project=AppStatusStack.prj&file=doc/GettingStarted.m)

Status Manager is a lightweight MATLAB&reg; toolbox for tracking and displaying application state in MVC-style apps. Push typed status objects (Running, Error, Warning, Success, …) onto a shared stack; one or more views observe the stack and automatically update progress dialogs, command-window output, or log files in response.

## Setup

### MathWorks Products (https://www.mathworks.com)

Requires MATLAB release R2025a or newer.

- [MATLAB](https://www.mathworks.com/products/matlab.html)

## Installation

Install Status Manager directly from the MATLAB Add-On Explorer, or install the `.mltbx` file manually:

1. Download `StatusManager 1.5.0.mltbx` from the [releases](releases/) folder.
2. Double-click the file in MATLAB to open the Add-On installer and follow the prompts.

**Programmatic installation** — to pin a specific version as a dependency of another project, copy `src/installStatusManager.m` into that project's startup script:

```matlab
installStatusManager(RequiredVersion="1.5.0", ToolboxPath="dependencies")
```

## Getting Started

Open the interactive getting-started guide:

```matlab
open doc/GettingStarted.m
```

Or follow the quick-start steps below.

**1. Create a status stack**

```matlab
stack = statusMgr.Stack();
```

**2. Attach a view**

```matlab
% GUI progress dialogs and alerts (recommended for App Designer apps)
f = uifigure();
statusMgr.view.Popup(f, stack);

% Plain-text output to the command window
statusMgr.view.CommandWindow(stack);

% Append every status to a log file
statusMgr.view.FileLog(stack, LogFolder=pwd);
```

**3. Push and remove statuses**

```matlab
% Second output is an onCleanup object — status is removed when it goes out of scope
[status, cleanup] = stack.addStatus("Running", Message="Loading data…");
loadMyData();
clear cleanup  % removes the Running status; view updates automatically

% Or remove explicitly
stack.removeStatus(status);
```

**4. Capture errors and warnings automatically**

```matlab
result = stack.run(@myFunction);   % Running → clears on success, Error on failure
```

### Available status types

| Type | Popup view behaviour |
|---|---|
| `Running` | Indeterminate progress dialog |
| `RunningCancellable` | Progress dialog with Cancel button |
| `Error` | Alert dialog with red icon |
| `Warning` | Alert dialog with yellow icon |
| `Success` | Alert dialog with green icon |
| `Info` | Alert dialog with info icon |
| `Idle` | Clears any active dialog (default state) |

### Key features

- **Stack semantics** — statuses stack; removing the top status reveals the one beneath, so nested operations compose naturally.
- **Multiple views** — attach as many views as needed to the same stack; each updates independently.
- **Array stacks** — broadcast a status to several stacks at once: `[stack1, stack2].addStatus("Running")`.
- **Suppression** — hide specific identifiers without removing them: `stack.suppressIdentifier("my:warning:id")`.
- **Monitorable classes** — any class that extends `statusMgr.monitorable.Monitorable` can emit statuses that are automatically forwarded to a watching stack.
- **User input** — request a string from the user through whichever view is active, with a timeout and default fallback.

## Examples

See [`doc/GettingStarted.m`](doc/GettingStarted.m) for a full walkthrough including progress bars, cancellable operations, error capture, and monitorable classes.

## License

The license is available in the [license.txt](license.txt) file in this GitHub repository.

## Community Support

[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2025 The MathWorks, Inc.
