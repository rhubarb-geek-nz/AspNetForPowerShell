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
param($Configuration,$TargetFramework,$Platform,$IntDir,$OutDir,$TargetDir)

$ModuleName = 'AspNetForPowerShell'
$CompanyName = 'rhubarb-geek-nz'

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$compatiblePSEdition = 'Core'
$DSC = [System.IO.Path]::DirectorySeparatorChar

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

$xmlDoc = [System.Xml.XmlDocument](Get-Content "$ModuleName.nuspec")

$ModuleId = $xmlDoc.SelectSingleNode("/package/metadata/id").FirstChild.Value
$ProjectUri = $xmlDoc.SelectSingleNode("/package/metadata/projectUrl").FirstChild.Value
$Description = $xmlDoc.SelectSingleNode("/package/metadata/description").FirstChild.Value
$Author = $xmlDoc.SelectSingleNode("/package/metadata/authors").FirstChild.Value
$Copyright = $xmlDoc.SelectSingleNode("/package/metadata/copyright").FirstChild.Value

$SDKChannels = @{
	'netcoreapp3.1' = '3.1';
	'net5.0' = '5.0';
	'net6.0' = '6.0';
	'net7.0' = '7.0'
}

$xmlDoc = [System.Xml.XmlDocument](Get-Content "$ModuleName.csproj")

$PackageReferences = $xmlDoc.SelectNodes("/Project/ItemGroup/PackageReference[@Include = 'Microsoft.PowerShell.SDK']")

$PowerShellSdkVersion = $null
$RuntimeVersion = $null

foreach ($Node in $PackageReferences)
{
	$Parent = $Node.ParentNode

	if ($Parent.Condition.Contains("'$TargetFramework'"))
	{
		$PowerShellSdkVersion = $Node.Version

		$config = Import-PowerShellDataFile 'package.psd1'

		$RuntimeVersion = $config[$TargetFramework][$PowerShellSdkVersion]
	}
}

if ( -not $RuntimeVersion )
{
	throw new "Unable to determine AspNetCore runtime version"
}

$ModulePath = ( $OutDir + $ModuleId )

if ( Test-Path $ModulePath )
{
	Remove-Item $ModulePath -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $ModulePath

Get-ChildItem -LiteralPath $OutDir -Filter '*.dll' | ForEach-Object {
	$Name = $_.Name

	$_ | Copy-Item -Destination $ModulePath
}

$Channel = $SDKChannels[$TargetFramework]

Copy-Item -LiteralPath ( '..'+$DSC+'README.md' ) -Destination $ModulePath

$CmdletsToExport = "'New-AspNetForPowerShellRequestDelegate'"

if ([int32]$RuntimeVersion.Split('.')[0] -ge 6)
{
	$CmdletsToExport += ",'New-AspNetForPowerShellWebApplication'"
}

@"
@{
	RootModule = 'RhubarbGeekNz.$ModuleName.dll'
	ModuleVersion = '$PowerShellSdkVersion'
	GUID = '59727163-f9c0-447d-9176-fc455fe932ef'
	Author = '$Author'
	CompanyName = '$CompanyName'
	Copyright = '$Copyright'
	PowerShellVersion = '$PowerShellSdkVersion'
	CompatiblePSEditions = @('$compatiblePSEdition')
	Description = '$Description'
	FunctionsToExport = @()
	CmdletsToExport = @($CmdletsToExport)
	VariablesToExport = '*'
	AliasesToExport = @()
	PrivateData = @{
		PSData = @{
			ProjectUri = '$ProjectUri'
		}
	}
}
"@ | ForEach-Object {
				$_.Replace('VERSION_PLACEHOLDER',$PowerShellSdkVersion)
} | Set-Content -Path "$ModulePath/$ModuleId.psd1"

Push-Location $OutDir

try
{
		$ZipName = "$moduleId.$PowerShellSdkVersion.zip"

		if ( Test-Path $ZipName)
		{
			Remove-Item $ZipName
		}

		Compress-Archive -LiteralPath $moduleId -DestinationPath $ZipName
}
finally
{
	Pop-Location
}

$nuget = $false

try
{
	$hasNuget = Get-Command 'nuget'
}
catch
{
}

if ( $hasNuget )
{
	Get-Content "$ModuleName.nuspec" | ForEach-Object {
		$_.Replace('VERSION_PLACEHOLDER',$PowerShellSdkVersion)
	} | Set-Content -Path ( "$OutDir"+"$ModuleName.nuspec")

	try
	{
		Push-Location $OutDir
		nuget pack "$ModuleName.nuspec"
		Remove-Item -LiteralPath "$ModuleName.nuspec"
	}
	finally
	{
		Pop-Location
	}
}

if ($IsLinux)
{
	./package-linux.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir

	If ( $LastExitCode -ne 0 )
	{
		throw "./package-linux.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir error $LastExitCode"
	}
}

if ($IsMacOs)
{
	./package-osx.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir

	If ( $LastExitCode -ne 0 )
	{
		throw "./package-osx.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir error $LastExitCode"
	}
}

if ($IsWindows)
{
	pwsh ./package-win.ps1 $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir

	If ( $LastExitCode -ne 0 )
	{
		throw "pwsh ./package-win.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir error $LastExitCode"
	}
}
