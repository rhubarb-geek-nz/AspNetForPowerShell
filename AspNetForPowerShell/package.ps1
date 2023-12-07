#!/usr/bin/env pwsh
# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

param($Configuration,$TargetFramework,$Platform,$IntDir,$OutDir,$PublishDir,$PowerShellSdkVersion)

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

$xmlDoc = [System.Xml.XmlDocument](Get-Content "$ModuleName.csproj")

$ModuleId = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/PackageId").FirstChild.Value
$ProjectUri = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/PackageProjectUrl").FirstChild.Value
$Description = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/Description").FirstChild.Value
$Author = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/Authors").FirstChild.Value
$Copyright = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/Copyright").FirstChild.Value
$AssemblyName = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/AssemblyName").FirstChild.Value

$SDKChannels = @{
	'net6.0' = '6.0';
	'net7.0' = '7.0';
	'net8.0' = '8.0'
}

$PackageReferences = $xmlDoc.SelectNodes("/Project/ItemGroup/PackageReference[@Include = 'Microsoft.PowerShell.SDK']")

$config = Import-PowerShellDataFile 'package.psd1'

$RuntimeVersion = $config[$TargetFramework][$PowerShellSdkVersion]

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

$CmdletsToExport = @('New-AspNetForPowerShellRequestDelegate')

if ([int32]$RuntimeVersion.Split('.')[0] -ge 6)
{
	$CmdletsToExport += 'New-AspNetForPowerShellWebApplication'
}

New-ModuleManifest -Path "$ModulePath/$ModuleId.psd1" `
				-RootModule "$AssemblyName.dll" `
				-ModuleVersion $PowerShellSdkVersion `
				-Guid '59727163-f9c0-447d-9176-fc455fe932ef' `
				-Author $Author `
				-CompanyName $CompanyName `
				-Copyright $Copyright `
				-PowerShellHostVersion $PowerShellSdkVersion `
				-CompatiblePSEditions @($compatiblePSEdition) `
				-Description $Description `
				-FunctionsToExport @() `
				-CmdletsToExport $CmdletsToExport `
				-VariablesToExport '*' `
				-AliasesToExport @() `
				-ProjectUri $ProjectUri

Import-PowerShellDataFile -LiteralPath "$ModulePath/$ModuleId.psd1" | Export-PowerShellDataFile | Out-File -LiteralPath "$ModulePath/$ModuleId.psd1.clean"

Remove-Item -LiteralPath "$ModulePath/$ModuleId.psd1"

Move-Item -LiteralPath "$ModulePath/$ModuleId.psd1.clean" -Destination "$ModulePath/$ModuleId.psd1"

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
	dotnet pwsh ./package-win.ps1 $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir

	If ( $LastExitCode -ne 0 )
	{
		throw "pwsh ./package-win.ps1 $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir error $LastExitCode"
	}
}
