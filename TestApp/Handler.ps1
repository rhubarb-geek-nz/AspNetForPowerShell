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
    switch ( $Request.Path.Value )
    {
        '/PSVersionTable' {
            $Response.ContentType = 'application/json'
            $PSVersionTable | ConvertTo-JSON
        }
        '/Query' {
            $Response.ContentType = 'application/json'
            $Request.Query | ConvertTo-JSON
        }
        '/Headers' {
            $Response.ContentType = 'application/json'
            $Request.Headers | ConvertTo-JSON
        }
        '/ContentRoot' {
            $Response.ContentType = 'text/plain'
            $ContentRoot
        }
        default {
            $Response.ContentType = 'text/plain'
            $Request.Method
            ' '
            $Request.Path.Value
            ' '
            $Request.QueryString.Value
        }
    }
}
