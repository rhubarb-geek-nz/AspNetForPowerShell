// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Management.Automation;
using System.Management.Automation.Runspaces;
using RhubarbGeekNz.AspNetForPowerShell;
using TestApp;

var app = WebApplication.Create(args);
var env = app.Services.GetRequiredService<IWebHostEnvironment>();
var logger = app.Services.GetRequiredService<ILogger<PowerShellDelegate>>();
var iss = InitialSessionState.CreateDefault();

iss.Variables.Add(new[]{
    new SessionStateVariableEntry("ContentRootPath", env.ContentRootPath, "Content Root Path"),
    new SessionStateVariableEntry("WebRootPath", env.WebRootPath, "Web Root Path"),
    new SessionStateVariableEntry("Logger", logger, "Logger")
});

var requestDelegate = new PowerShellDelegate(ScriptBlock.Create(Resources.RequestDelegate), iss).InvokeAsync;

app.Run((x) => requestDelegate(x));

await app.RunAsync();
