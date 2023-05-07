// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Management.Automation.Runspaces;
using Microsoft.PowerShell;
using RhubarbGeekNz.AspNetForPowerShell;
using TestCgi;

var app = WebApplication.Create(args);
var env = app.Services.GetRequiredService<IWebHostEnvironment>();
var logger = app.Services.GetRequiredService<ILogger<PowerShellDelegate>>();
var iss = InitialSessionState.CreateDefault();

iss.Variables.Add(new[]{
    new SessionStateVariableEntry("ContentRootPath", env.ContentRootPath, "Content Root Path"),
    new SessionStateVariableEntry("WebRootPath", env.WebRootPath, "Web Root Path"),
    new SessionStateVariableEntry("Logger", logger, "Logger")
});

if (System.Environment.OSVersion.Platform==PlatformID.Win32NT)
{
    iss.ExecutionPolicy = ExecutionPolicy.RemoteSigned;
}

var requestDelegate = new PowerShellDelegate(Resources.RequestDelegate, iss).InvokeAsync;
var cgiBin = new PathString("/cgi-bin");

app.UseStaticFiles();

app.Use((context, next) =>
    context.Request.Path.StartsWithSegments((cgiBin)) ?
        requestDelegate(context) :
        next(context));

await app.RunAsync();
