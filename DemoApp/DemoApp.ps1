#!/usr/bin/env pwsh
# Copyright (c) 2024 Roger Brown.
# Licensed under the MIT License.

trap
{
	throw $PSItem
}

$Delegate = New-AspNetForPowerShellRequestDelegate -ScriptBlock {
	param($Context)
	$Response = $Context.Response
	$Response.StatusCode = 200
	$Response.ContentType = 'text/plain'
	'Hello World'
}

$App = New-AspNetForPowerShellWebApplication
$RouteBuilder = [Microsoft.AspNetCore.Routing.RouteBuilder]::new($App)
[Void][Microsoft.AspNetCore.Routing.RequestDelegateRouteBuilderExtensions]::MapGet($RouteBuilder, "/", $Delegate)
$RouteTable = $RouteBuilder.Build()
$App = [Microsoft.AspNetCore.Builder.RoutingBuilderExtensions]::UseRouter($App, $RouteTable)
$App.Run()
