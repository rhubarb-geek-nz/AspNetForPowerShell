// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;

namespace RhubarbGeekNz.AspNetForPowerShell
{
    public static class InitialSessionStateExtensions
    {
        public static void AddAspNetForPowerShellCmdlets(this InitialSessionState initialSessionState)
        {
            foreach (Type t in new Type[] {
                typeof(NewWebApplication),
                typeof(NewRequestDelegate) 
            })
            {
                CmdletAttribute ca = t.GetCustomAttribute<CmdletAttribute>();

                initialSessionState.Commands.Add(new SessionStateCmdletEntry($"{ca.VerbName}-{ca.NounName}", t, ca.HelpUri));
            }
        }
    }
}
