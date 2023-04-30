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
param($Configuration='Release',$TargetFramework=$null)

$args = $null

trap
{
	throw $PSItem
}

$PSC = [System.IO.Path]::PathSeparator
$DSC = [System.IO.Path]::DirectorySeparatorChar
$OriginalPath = $Env:PSModulePath

$configDir = ( $PSScriptRoot + $DSC + 'bin' + $DSC + $Configuration )

if ( -not $TargetFramework )
{
	$Major =  [System.Environment]::Version.Major
	$Minor =  [System.Environment]::Version.Minor

	foreach ($s in "netcoreapp$Major.$Minor","net$Major.$Minor")
	{
		if ( Test-Path -LiteralPath "$configDir/$s" -PathType Container)
		{
			$TargetFramework = $s
		} 
	}

	if ( -not $TargetFramework )
	{
		throw "no matching framework for dotnet $Major.$Minor"
	}
}

$moduleDir = ( $configDir + $DSC + $TargetFramework )

$InPath = $false

foreach ($d in ($Env:PSModulePath).Split($PSC))
{
	if ($_ -eq $moduleDir)
	{
		$InPath = $true
	}
}

if ( -not $InPath )
{
	$Env:PSModulePath=($moduleDir + $PSC + $Env:PSModulePath)
}

try
{
	$app = New-AspNetForPowerShellWebApplication -ArgumentList $args
}
finally
{
	if ( -not $InPath )
	{
		$Env:PSModulePath=$OriginalPath
	}
}

$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

$env = $app.Services.GetService([Microsoft.AspNetCore.Hosting.IWebHostEnvironment])
$log = $app.Services.GetService([Microsoft.Extensions.Logging.ILogger[RhubarbGeekNz.AspNetForPowerShell.NewRequestDelegate]])

foreach ($var in
	('ContentRootPath',$env.ContentRootPath,'Content Root Path'),
	('WebRootPath',$env.WebRootPath,'Web Root Path'),
	('Logger',$log,'Logger')
)
{
	$iss.Variables.Add((New-Object -TypeName 'System.Management.Automation.Runspaces.SessionStateVariableEntry' -ArgumentList $var))
}

$script = [string]$Content = [System.IO.File]::ReadAllText( ( $PSScriptRoot+$DSC+'..'+$DSC+'TestApp'+$DSC+'RequestDelegate.ps1') )

$delegate = New-AspNetForPowerShellRequestDelegate -Script $script -InitialSessionState $iss

[Microsoft.AspNetCore.Builder.RunExtensions]::Run($app,$delegate)

$app.Run()
