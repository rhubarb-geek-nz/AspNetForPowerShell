// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using RhubarbGeekNz.AspNetForPowerShell;
using TestPS1;

var iss = InitialSessionState.CreateDefault();

foreach (Type t in new Type[] {
    typeof(NewRequestDelegate),
    typeof(NewWebApplication) })
{
    CmdletAttribute ca = t.GetCustomAttribute<CmdletAttribute>();

    iss.Commands.Add(new SessionStateCmdletEntry($"{ca.VerbName}-{ca.NounName}", t, ca.HelpUri));
}

iss.Variables.Add(new SessionStateVariableEntry("Resources",typeof(Resources),"Resources"));

using (PowerShell powerShell = PowerShell.Create(iss))
{
    powerShell.AddScript(Resources.Program);

    powerShell.AddArgument(args);

    powerShell.Invoke();
}
