#!/usr/bin/env pwsh
# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

param($Configuration,$TargetFramework,$Platform,$IntDir,$OutDir,$PublishDir,$PowerShellSdkVersion)

$ModuleName = 'AspNetForPowerShell'

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$compatiblePSEdition = 'Core'

trap
{
	throw $PSItem
}

$xmlDoc = [System.Xml.XmlDocument](Get-Content "$ModuleName.csproj")

$ModuleId = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/PackageId").FirstChild.Value
$ProjectUri = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/PackageProjectUrl").FirstChild.Value
$Description = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/Description").FirstChild.Value
$Author = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/Authors").FirstChild.Value
$Copyright = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/Copyright").FirstChild.Value
$AssemblyName = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/AssemblyName").FirstChild.Value
$CompanyName = $xmlDoc.SelectSingleNode("/Project/PropertyGroup/Company").FirstChild.Value

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

$Channel = $SDKChannels[$TargetFramework]

New-ModuleManifest -Path "$OutDir$ModuleId.psd1" `
				-RootModule "$AssemblyName.PSCmdlet.dll" `
				-ModuleVersion $PowerShellSdkVersion `
				-Guid '59727163-f9c0-447d-9176-fc455fe932ef' `
				-Author $Author `
				-CompanyName $CompanyName `
				-Copyright $Copyright `
				-PowerShellHostVersion $PowerShellSdkVersion `
				-CompatiblePSEditions @($compatiblePSEdition) `
				-Description $Description `
				-FunctionsToExport @() `
				-CmdletsToExport @('New-AspNetForPowerShellRequestDelegate','New-AspNetForPowerShellWebApplication') `
				-VariablesToExport '*' `
				-AliasesToExport @() `
				-ProjectUri $ProjectUri

Import-PowerShellDataFile -LiteralPath "$OutDir$ModuleId.psd1" | Export-PowerShellDataFile | Out-File -LiteralPath "$PublishDir$ModuleId.psd1"

if ($IsLinux)
{
	./package-linux.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir $PublishDir

	If ( $LastExitCode -ne 0 )
	{
		throw "./package-linux.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir $PublishDir error $LastExitCode"
	}
}

if ($IsMacOs)
{
	./package-osx.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir $PublishDir

	If ( $LastExitCode -ne 0 )
	{
		throw "./package-osx.sh $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir $PublishDir error $LastExitCode"
	}
}

if ($IsWindows)
{
	dotnet pwsh -ExecutionPolicy Bypass -File ./package-win.ps1 $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir $PublishDir

	If ( $LastExitCode -ne 0 )
	{
		throw "pwsh ./package-win.ps1 $Configuration $TargetFramework $RuntimeVersion $PowerShellSdkVersion $ModuleId $Channel $Platform $IntDir $OutDir $PublishDir error $LastExitCode"
	}
}
