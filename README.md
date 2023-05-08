# AspNetForPowerShell
## Host `PowerShell` pages in `ASP.NET`

Implements a `RequestDelegate` for executing `PowerShell` scripts

The scripts are executed in a new `PowerShell` per request. The pipelines are connected to the request and response bodies.

## Example of a script for `GET` Hello World

```
param(
    [parameter(Mandatory=$true)]
    $HttpContext
)
$Response=$HttpContext.Response
$Response.StatusCode=200
$Response.ContentType='text/plain'
[System.Text.Encoding]::ASCII
'Hello World'
```

Writing the `ASCII` encoding to the output allows control of the encoding.

## Example of a script for `POST` implementing an echo

```
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
```

The `-NoEnumerate` is to write a byte array rather than individual bytes onto the pipeline.

## Delegate Implementation

The delegate uses the asynchronous programming model in order to allow overlapping of both input and output.

### InitialSessionState

An `InitialSessionState` can be used to provide state that will be shared by each request invocation.

### Input Pipeline

The request body is fed into to the input pipeline. The input can either be an `IFormCollection`, a byte array or a string depending on the `Content-Type`.

### Output Pipeline

The output pipeline is written to the response body. The output is written as the objects are added to the pipeline. Only primitives that can be converted to characters or bytes are supported. An `Encoding` type will set the current character encoding.

### Response Status

The response status and any headers should be applied to the `HttpContext` before the output is written.

## Interesting features

The code includes some hopefully interesting techniques

- `PowerShell` delegate uses asynchronous programming to simultaneously read and write the input and output pipelines while executing the `PowerShell` script without using threads; see [PowerShellDelegate/PowerShellDelegate.cs](PowerShellDelegate/PowerShellDelegate.cs)
- Test harness uses `WebApplicationFactory` with top-level programs; see [UnitTests/WebApplicationFactoryBuilder.cs](UnitTests/WebApplicationFactoryBuilder.cs)
- Generates native packages to install matching `AspNetCore` runtime; see [AspNetForPowerShell/package.ps1](AspNetForPowerShell/package.ps1)
- `PowerShell` can be used at different levels;
  - Main `Program`; see [TestPs1/Program.ps1](TestPs1/Program.ps1)
  - `Startup` configuration; see [TestEol/Startup.ps1](TestEol/Startup.ps1)
  - `RequestDelegate` handler; see [TestCgi/RequestDelegate.ps1](TestCgi/RequestDelegate.ps1)
- Combining with `Controllers`; see [TestApi/Program.cs](TestApi/Program.cs)
- Combining with static content; see [TestCgi/Program.cs](TestCgi/Program.cs)
- Access resources from `PowerShell`; see [TestEol/Startup.ps1](TestEol/Startup.ps1)
- Get services by type, eg `ILogger`; [TestPs1/Program.ps1](TestPs1/Program.ps1)
- Extension to add `Cmdlets` to `InitialSessionState`; see [Extensions/InitialSessionStateExtensions.cs](Extensions/InitialSessionStateExtensions.cs)
- Using unit tests to validate `PowerShell` implementation; see [UnitTests/TestPs1Tests.cs](UnitTests/TestPs1Tests.cs)
