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

$filePath = $request.Path.Value

if ( $filePath.Contains('..') )
{
	$response.StatusCode = 400
}
else
{
	$filePath = ( $WebRootPath + $filePath )

	if ( Test-Path -LiteralPath $filePath -PathType Leaf )
	{
		$response.StatusCode = 200

		if ($filePath.EndsWith('.ps1'))
		{
			. $filePath
		}
		else
		{
			Get-Content -LiteralPath $filePath -AsByteStream -Raw | Write-Output -NoEnumerate
		}
	}
	else
	{
		$response.StatusCode = 404
	}
}
