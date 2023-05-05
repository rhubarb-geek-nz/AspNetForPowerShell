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
