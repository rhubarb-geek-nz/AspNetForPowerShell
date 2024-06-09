// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Management.Automation;
using System.Management.Automation.Runspaces;
using RhubarbGeekNz.AspNetForPowerShell;

InitialSessionState initialSessionState = InitialSessionState.CreateDefault();

initialSessionState.AddAspNetForPowerShellCmdlets();

PowerShell powerShell = PowerShell.Create(initialSessionState);

string DemoAppPs1 = args[0];

powerShell.AddCommand(DemoAppPs1);

for (int i = 1; i < args.Length; i++)
{
    powerShell.AddArgument(args[i]);
}

powerShell.Invoke();
