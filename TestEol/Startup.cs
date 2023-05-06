// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Logging;
using RhubarbGeekNz.AspNetForPowerShell;

namespace TestEol
{
    public class Startup
    {
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogger<PowerShellDelegate> log)
        {
            var installer = InitialSessionState.CreateDefault();

            installer.AddAspNetForPowerShellCmdlets();

            using (PowerShell powerShell = PowerShell.Create(installer))
            {
                powerShell.AddScript(Resources.Startup);

                powerShell.AddParameters(new object[] { app, env, log, typeof(Resources) });

                powerShell.Invoke();
            }
        }
    }
}
