/**************************************************************************
 *
 *  Copyright 2023, Roger Brown
 *
 *  This file is part of rhubarb-geek-nz/AspNetForPowerShell.
 *
 *  This program is free software: you can redistribute it and/or modify it
 *  under the terms of the GNU Lesser General Public License as published by the
 *  Free Software Foundation, either version 3 of the License, or (at your
 *  option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 */

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
