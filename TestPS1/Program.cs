// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using RhubarbGeekNz.AspNetForPowerShell;
using TestPS1;

var iss = InitialSessionState.CreateDefault();

iss.AddAspNetForPowerShellCmdlets();

iss.Variables.Add(new SessionStateVariableEntry("Resources",typeof(Resources),"Resources"));

using (PowerShell powerShell = PowerShell.Create(iss))
{
    powerShell.AddScript(Resources.Program);

    powerShell.AddArgument(args);

    powerShell.Invoke();
}
