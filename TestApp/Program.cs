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
