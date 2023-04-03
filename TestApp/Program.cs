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

using System.Management.Automation.Runspaces;
using AspNetForPowerShell;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

string scriptGet = @"
param(
    [parameter(Mandatory=$true)]
    $HttpContext
)
$Response=$HttpContext.Response
$Response.StatusCode=200
$Response.ContentType='text/plain'
[System.Text.Encoding]::ASCII
'Hello World'
";

string scriptPost = @"
param(
    [parameter(Mandatory=$true)]
    $HttpContext,
    [parameter(ValueFromPipeline=$true,Mandatory=$true)]
    $pipelineInput
)
$Response=$HttpContext.Response
$Response.StatusCode=200
$Response.ContentType=$HttpContext.Request.ContentType
Write-Output $pipelineInput -NoEnumerate
";

InitialSessionState iss = InitialSessionState.CreateDefault();
app.MapGet("/", new PowerShellDelegate(iss,scriptGet).InvokeAsync);
app.MapPost("/", new PowerShellDelegate(iss,scriptPost).InvokeAsync);

app.Run();
