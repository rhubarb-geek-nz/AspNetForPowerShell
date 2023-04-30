param(
    [parameter(Mandatory=$true)]
    $context,
    [parameter(ValueFromPipeline=$true,Mandatory=$false)]
    $pipelineInput
)
$request = $context.Request
$response = $context.Response
$response.StatusCode = 200

if ( $pipelineInput )
{
    $response.ContentType = 'application/json'
    $pipelineInput | ConvertTo-JSON
}
else
{
    switch ( $request.Path.Value )
    {
        '/PSVersionTable' {
            $response.ContentType = 'application/json'
            $PSVersionTable | ConvertTo-JSON
        }
        '/Query' {
            $response.ContentType = 'application/json'
            $request.Query | ConvertTo-JSON
        }
        '/Headers' {
            $response.ContentType = 'application/json'
            $request.Headers | ConvertTo-JSON
        }
        '/ContentRootPath' {
            $response.ContentType = 'text/plain'
            $ContentRootPath
        }
        '/WebRootPath' {
            $response.ContentType = 'text/plain'
            $WebRootPath
        }
        '/Logger' {
            $response.ContentType = 'text/plain'
            [Microsoft.Extensions.Logging.LoggerExtensions]::LogInformation($Logger,'logger request',$null)
            'ok'
        }
        '/favicon.ico' {
            $response.StatusCode = 404
            $response.ContentType = 'text/plain'
            'not found'
        }
        '/Fault' {
            throw 'fault'
        }
        default {
            $response.ContentType = 'text/plain'
            $request.Method
            ' '
            $request.Path.Value
            ' '
            $request.QueryString.Value
        }
    }
}
