# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

param($Configuration,$TargetFramework,$RuntimeVersion,$PowerShellSdkVersion,$ModuleId,$Channel,$Platform,$IntDir,$OutDir,$PublishDir)

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

if ( -not ( Test-Path $PublishDir ))
{
	throw "$PublishDir not found"
}

$UpgradeCode = 'C25994C4-64E2-4D7F-ADCC-DCB26E5D0803'
$IsWin64 = $True
$ProgramFilesFolder = 'ProgramFiles64Folder'
$Architecture = $Platform
$InstallerVersion = 200

Switch ($Platform)
{
	'x86' {
			$UpgradeCode = '258E2A88-F353-49F8-8626-D11851227C75'
			$IsWin64 = $False
			$ProgramFilesFolder = 'ProgramFilesFolder'
		}
	'arm32' {
			$UpgradeCode = '258E2A88-F353-49F8-8626-D11851227C75'
			$IsWin64 = $False
			$ProgramFilesFolder = 'ProgramFilesFolder'
			$Architecture = 'arm'
			$InstallerVersion = 500
		}
	'x64' {
		}
	'arm64' {
			$InstallerVersion = 500
		}
	default {
			throw "Unsupported Platform $Platform, must be one of x86, x64, arm32, arm64"
		}
}

Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile ( "$OutDir"+"dotnet-install.ps1" )

pwsh ($OutDir+'dotnet-install.ps1') -InstallDir ( $OutDir+'aspnetcore' ) -Runtime 'aspnetcore' -Channel $Channel -Version $RuntimeVersion -Architecture $Architecture

If ( $LastExitCode -ne 0 )
{
	throw 'dotnet-install.ps1'
}

try
{
	$xmlDoc = [System.Xml.XmlDocument]@'
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="rhubarb-geek-nz.AspNetForPowerShell" Language="1033" Version="0.0.0.0" Manufacturer="Microsoft Corporation" UpgradeCode="C25994C4-64E2-4D7F-ADCC-DCB26E5D0803">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" Platform="x64" Description="AspNetForPowerShell 0.0.0" Comments="AspNetForPowerShell 0.0.0" />
    <MediaTemplate EmbedCab="yes" />
    <Feature Id="ProductFeature" Title="setup" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>
    <Upgrade Id="{C25994C4-64E2-4D7F-ADCC-DCB26E5D0803}">
      <UpgradeVersion Maximum="0.0.0.0" Property="OLDPRODUCTFOUND" OnlyDetect="no" IncludeMinimum="yes" IncludeMaximum="no" />
    </Upgrade>
    <InstallExecuteSequence>
      <RemoveExistingProducts After="InstallInitialize" />
    </InstallExecuteSequence>
  </Product>
  <Fragment>
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLPRODUCT" Name="PowerShell">
          <Directory Id="INSTALLVERSION" Name="7">
            <Directory Id="INSTALLMODULES" Name="Modules">
              <Directory Id="INSTALLDIR" Name="rhubarb-geek-nz.AspNetForPowerShell" />
            </Directory>
          </Directory>
        </Directory>
      </Directory>
    </Directory>
  </Fragment>
  <Fragment>
    <ComponentGroup Id="ProductComponents">
      <Component Id="module" Guid="*" Directory="INSTALLDIR" Win64="yes">
        <File Id="module" KeyPath="yes" Source="rhubarb-geek-nz.AspNetForPowerShell\rhubarb-geek-nz.AspNetForPowerShell.psd1" />
      </Component>
    </ComponentGroup>
  </Fragment>
</Wix>
'@

	$nsMgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $xmlDoc.NameTable

	$nsmgr.AddNamespace("wix", "http://schemas.microsoft.com/wix/2006/wi")

	$productNode = $xmlDoc.SelectSingleNode("/wix:Wix/wix:Product", $nsmgr)

	$productNode.Name = "$ModuleId $PowerShellSdkVersion ($Platform)"
	$productNode.Version = "$PowerShellSdkVersion.0"
	$productNode.UpgradeCode = $UpgradeCode

	$packageNode = $xmlDoc.SelectSingleNode("/wix:Wix/wix:Product/wix:Package", $nsmgr)

	$packageNode.Description = "AspNetCore $RuntimeVersion for PowerShell $PowerShellSdkVersion $Platform"
	$packageNode.Comments = 'https://github.com/rhubarb-geek-nz/AspNetForPowerShell'

	$upgradeVersionNode = $xmlDoc.SelectSingleNode("/wix:Wix/wix:Product/wix:Upgrade/wix:UpgradeVersion", $nsmgr)

	$upgradeVersionNode.Maximum = "$PowerShellSdkVersion.0"
	$upgradeVersionNode.ParentNode.Id = ( '{' + $UpgradeCode + '}' )

	$componentGroup =  $xmlDoc.SelectSingleNode("/wix:Wix/wix:Fragment/wix:ComponentGroup", $nsmgr)

	$component =  $xmlDoc.SelectSingleNode("/wix:Wix/wix:Fragment/wix:ComponentGroup/wix:Component", $nsmgr)

	$null = $componentGroup.RemoveChild($component)

	$installDir =  $xmlDoc.SelectSingleNode("/wix:Wix/wix:Fragment/wix:Directory/wix:Directory", $nsmgr)
	$installDir.Id = $ProgramFilesFolder

	if ( -not $IsWin64 )
	{
		$null = $component.RemoveAttribute('Win64')
	}

	$packageNode.Platform = $Architecture
	$packageNode.InstallerVersion = "$InstallerVersion"

	foreach ($srcDir in "$PublishDir",("$OutDir"+"aspnetcore\shared\Microsoft.AspNetCore.App\$RuntimeVersion\"))
	{
		Get-ChildItem $srcDir | ForEach-Object {
			$name = $_.Name

			$clone = $component.CloneNode($true)
			$clone.Id = ('C'+(New-Guid).ToString().Replace('-',''))
			$clone.File.Source="$srcDir$name"
			$clone.File.Id = ('F'+(New-Guid).ToString().Replace('-',''))

			$null = $componentGroup.AppendChild($clone)
		}
	}

	$xmlDoc.Save("$OutDir$ModuleId.wsx")

	& "$ENV:WIX\bin\candle.exe" -nologo -out "$OutDir$ModuleId.wixobj" "$OutDir$ModuleId.wsx" -ext WixUtilExtension

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

	& "$ENV:WIX\bin\light.exe" -nologo -cultures:null -out "$OutDir$ModuleId-$PowerShellSdkVersion-win-$Platform.msi" "$OutDir$ModuleId.wixobj" -ext WixUtilExtension

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}
}
finally
{
	foreach ($p in ( $OutDir+'aspnetcore' ))
	{
		if ( Test-Path -LiteralPath $p )
		{
			Remove-Item $p -Force -Recurse
		}
	}
}

$codeSignCertificate = Get-ChildItem -path Cert:\ -Recurse -CodeSigningCert | Where-Object {$_.Thumbprint -eq '601A8B683F791E51F647D34AD102C38DA4DDB65F'}

if ( -not $codeSignCertificate )
{
	throw 'Codesign certificate not found'
}

Set-AuthenticodeSignature -Certificate $codeSignCertificate -TimestampServer 'http://timestamp.digicert.com' -HashAlgorithm SHA256 -FilePath "$OutDir$ModuleId-$PowerShellSdkVersion-win-$Platform.msi"
