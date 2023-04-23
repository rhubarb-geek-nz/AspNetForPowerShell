param(
    [parameter(Mandatory=$true)]
    $HttpContext,
    [parameter(ValueFromPipeline=$true,Mandatory=$false)]
    $pipelineInput
)
$Request = $HttpContext.Request
$Response = $HttpContext.Response
$Response.StatusCode = 200

if ( $pipelineInput )
{
    $Response.ContentType = 'application/json'
    $pipelineInput | ConvertTo-JSON
}
else
{
    $Response.ContentType = 'text/plain'
    $ContentRoot
    ' '
    $Request.Method
    ' '
    $Request.Path.Value
    ' '
    $Request.QueryString.Value
    "`n"
    $Request.Query | ConvertTo-JSON
    "`n"
    $Request.Headers | ConvertTo-JSON
    "`n"
}
