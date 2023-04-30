#!/usr/bin/env pwsh
#
#  Copyright 2023, Roger Brown
#
#  This file is part of rhubarb-geek-nz/AspNetForPowerShell
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
param($args)

trap
{
	throw $PSItem
}

$Delegate = New-PowerShellDelegate -Script @'
param($Context)
$Response=$Context.Response
$Response.StatusCode=200
$Response.ContentType='text/plain'
'Hello World'
'@

$App = New-WebApplication -ArgumentList $args
$RouteBuilder = [Microsoft.AspNetCore.Routing.RouteBuilder]::new($App)
[Void][Microsoft.AspNetCore.Routing.RequestDelegateRouteBuilderExtensions]::MapGet($RouteBuilder, "/", $Delegate)
$RouteTable = $RouteBuilder.Build()
$App = [Microsoft.AspNetCore.Builder.RoutingBuilderExtensions]::UseRouter($App, $RouteTable)
$App.Run()