// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using RhubarbGeekNz.AspNetForPowerShell;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using TestApi;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

var app = builder.Build();

app.MapControllers();

var iss = InitialSessionState.CreateDefault();

iss.Variables.Add(new[]{
    new SessionStateVariableEntry("ContentRootPath", app.Environment.ContentRootPath, "Content Root Path"),
    new SessionStateVariableEntry("WebRootPath", app.Environment.WebRootPath, "Web Root Path"),
    new SessionStateVariableEntry("Logger", app.Logger, "Logger")
});

app.MapGet("/HelloWorld", new PowerShellDelegate(ScriptBlock.Create(Resources.HelloWorld),iss).InvokeAsync);

app.Run();
