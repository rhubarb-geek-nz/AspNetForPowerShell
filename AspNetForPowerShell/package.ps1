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
param($Configuration,$TargetFramework)

$ModuleName = 'AspNetForPowerShell'
$CompanyName = 'rhubarb-geek-nz'

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$compatiblePSEdition = 'Core'
$DSC = [System.IO.Path]::DirectorySeparatorChar
$ObjDir = ( 'obj'+$DSC+$Configuration+$DSC+$TargetFramework )
$BinDir = ( 'bin'+$DSC+$Configuration+$DSC+$TargetFramework )

trap
{
	throw $PSItem
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
$Version = $null

foreach ($Node in $PackageReferences)
{
	$Parent = $Node.ParentNode

	if ($Parent.Condition.Contains("'$TargetFramework'"))
	{
		$PowerShellSdkVersion = $Node.Version

		$config = Import-PowerShellDataFile 'package.psd1'

		$Version = $config[$TargetFramework][$PowerShellSdkVersion]
	}
}

if ( -not $Version )
{
	throw new "Unable to determine AspNetCore runtime version"
}

$ModulePath = ( $BinDir + $DSC + $ModuleId )

if ( Test-Path $ModulePath )
{
	Remove-Item $ModulePath -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $ModulePath

Get-ChildItem -LiteralPath $binDir -Filter '*.dll' | ForEach-Object {
	$Name = $_.Name

	$_ | Copy-Item -Destination $ModulePath
}

$Channel = $SDKChannels[$TargetFramework]

if ($IsMacOs)
{
	$sdkDir = '/usr/local/share/dotnet'
}
else
{
	$sdkDir = ($ObjDir+$DSC+"sdk-$Version")

	if ( -not ( Test-Path $sdkDir ))
	{
		try
		{
			$null = New-Item -ItemType Directory -Path $sdkDir

			if ($IsWindows)
			{
				Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile "$ObjDir/dotnet-install.ps1"
				pwsh "$ObjDir/dotnet-install.ps1" -InstallDir $sdkDir -Runtime 'aspnetcore' -Channel $Channel -Version $Version
			}
			else
			{
				Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.sh' -OutFile "$ObjDir/dotnet-install.sh"
				bash $ObjDir/dotnet-install.sh --install-dir $sdkDir --runtime aspnetcore --channel $Channel --version $Version
			}

			If ( $LastExitCode -ne 0 )
			{
				throw "dotnet-install error $LastExitCode"
			}
		}
		catch
		{
			Remove-Item -LiteralPath $sdkDir -Force -Recursive
			foreach ($p in "$ObjDir/dotnet-install.ps1","$ObjDir/dotnet-install.sh")
			{
				if ( Test-Path $p )
				{
					Remove-Item -LiteralPath $p
				}
			}
			throw
		}
	}
}

$runtimeDir = ($sdkDir+$DSC+'shared'+$DSC+'Microsoft.AspNetCore.App'+$DSC+$Version)

if ( -not ( Test-Path $runtimeDir ) )
{
	throw "Runtime $Version not found for $Channel for $TargetFramework"
}

Get-ChildItem -LiteralPath $runtimeDir -Filter '*.dll' | Copy-Item -Destination $ModulePath

Copy-Item -LiteralPath ( '..'+$DSC+'README.md' ) -Destination $ModulePath

$CmdletsToExport = "'New-AspNetForPowerShellRequestDelegate'"

if ([int32]$Version.Split('.')[0] -ge 6)
{
	$CmdletsToExport += ",'New-AspNetForPowerShellWebApplication'"
}

@"
@{
	RootModule = 'RhubarbGeekNz.$ModuleName.dll'
	ModuleVersion = '$Version'
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

$nuget = $false

try
{
	$nuget = Get-Command 'nuget'
}
catch
{
}

$loc = Get-Location

try
{
	if ( $nuget )
	{
		Get-Content "$ModuleName.nuspec" | ForEach-Object {
			$_.Replace('VERSION_PLACEHOLDER',$PowerShellSdkVersion)
		} | Set-Content -Path ( "$BinDir"+$DSC+"$ModuleName.nuspec")
		Set-Location $BinDir
		nuget pack "$ModuleName.nuspec"
		Remove-Item -LiteralPath "$ModuleName.nuspec"
	}
	else
	{
		Set-Location $BinDir

		if ( Test-Path "$moduleId-$PowerShellSdkVersion.zip")
		{
			Remove-Item "$moduleId-$PowerShellSdkVersion.zip"
		}

		Compress-Archive -LiteralPath $moduleId -DestinationPath "$moduleId-$PowerShellSdkVersion.zip"
	}
}
finally
{
	Set-Location $loc
}

if ($IsLinux)
{
	foreach ($Arch in 'all','native')
	{
		./package.sh $Configuration $TargetFramework $Version $PowerShellSdkVersion $ModuleId $Channel $Arch

		If ( $LastExitCode -ne 0 )
		{
			throw "./package.sh $Configuration $TargetFramework $Version $PowerShellSdkVersion $ModuleId $Channel $Arch error $LastExitCode"
		}
	}
}
