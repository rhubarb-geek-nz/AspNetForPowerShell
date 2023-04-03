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
