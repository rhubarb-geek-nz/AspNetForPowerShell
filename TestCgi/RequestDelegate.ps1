# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

param(
    [parameter(Mandatory=$true)]
    $context,
    [parameter(ValueFromPipeline=$true,Mandatory=$false)]
    $pipelineInput
)

trap
{
	throw $PSItem
}

$request = $context.Request
$response = $context.Response

$filePath = ( $WebRootPath + $request.Path.Value )

if ( Test-Path -LiteralPath $filePath -PathType Leaf )
{
	if ($filePath.EndsWith('.ps1'))
	{
		. $filePath
	}
	else
	{
		$response.StatusCode = 500
	}
}
else
{
	$response.StatusCode = 404
}
