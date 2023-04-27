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
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using RhubarbGeekNz.AspNetForPowerShell;

namespace TestEol
{
    public class Startup
    {
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            var initialSessionState = InitialSessionState.CreateDefault();

            initialSessionState.Variables.Add(new SessionStateVariableEntry("ContentRoot", env.ContentRootPath, "Content Root Path"));

            var installer = InitialSessionState.CreateDefault();

            installer.Commands.Add(new SessionStateCmdletEntry("New-PowerShellDelegate", typeof(NewPowerShellDelegate), null));
            installer.Commands.Add(new SessionStateCmdletEntry("Set-PowerShellDelegate", typeof(SetPowerShellDelegate), null));

            using (Runspace runspace = RunspaceFactory.CreateRunspace(installer))
            {
                runspace.Open();

                try
                {
                    object requestDelegate;

                    using (PowerShell powerShell = PowerShell.Create(runspace))
                    {
                        powerShell.AddCommand("New-PowerShellDelegate").AddArgument(Resources.Handler).AddArgument(initialSessionState);

                        var result = powerShell.Invoke();

                        requestDelegate = result[0].BaseObject;
                    }

                    using (PowerShell powerShell = PowerShell.Create(runspace))
                    {
                        powerShell.AddCommand("Set-PowerShellDelegate").AddArgument(app).AddArgument(requestDelegate);

                        powerShell.Invoke();
                    }
                }
                finally
                {
                    runspace.Close();
                }
            }
        }
    }
}
