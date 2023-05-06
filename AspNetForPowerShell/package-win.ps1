#!/usr/bin/env pwsh
# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

param($Configuration,$TargetFramework,$RuntimeVersion,$PowerShellSdkVersion,$ModuleId,$Channel,$Platform,$IntDir,$OutDir)

$ModuleName = 'AspNetForPowerShell'
$CompanyName = 'rhubarb-geek-nz'

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

trap
{
	throw $PSItem
}

if ( -not ( Test-Path $IntDir ))
{
	throw "$IntDir not found"
}

if ( -not ( Test-Path $OutDir ))
{
	throw "$OutDir not found"
}

# TODO - create MSI
# Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile ( "$IntDir"+"dotnet-install.ps1" )
# pwsh "$IntDir/dotnet-install.ps1" -InstallDir $sdkDir -Runtime 'aspnetcore' -Channel $Channel -Version $Version -Architecture $Architecture
