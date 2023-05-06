#!/bin/sh -e
# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

Configuration="$1"
TargetFramework="$2"
RuntimeVersion="$3"
PowerShellSdkVer="$4"
ModuleId="$5"
Channel="$6"
Platform="$7"
IntDir="$8"
OutDir="$9"

PackageIdentifier="nz.geek.rhubarb.aspnetforpowershell"

RuntimeDir="/usr/local/share/dotnet/shared/Microsoft.AspNetCore.App/$RuntimeVersion"
InstallDir="/usr/local/microsoft/powershell/7/Modules"

ls -ld "$IntDir" "$OutDir" "$OutDir/$ModuleId" "$RuntimeDir" "$InstallDir"

dotnet --list-runtimes | grep "Microsoft.AspNetCore.App $RuntimeVersion \[/usr/local/share/dotnet/shared/Microsoft.AspNetCore.App\]"
pwsh -c '$Env:PSModulePath' | grep ":$InstallDir"

WorkDir="$OutDir"osx

cleanup()
{
	if test -d "$WorkDir"
	then
		chmod -R +w "$WorkDir"
		rm -rf "$WorkDir"
	fi
}

cleanup

trap cleanup 0

mkdir "$WorkDir"

(
	mkdir -p "$WorkDir/root/$InstallDir/$ModuleId"

	cp "$OutDir/$ModuleId/"* "$WorkDir/root/$InstallDir/$ModuleId"

	(
		set -e
		cd "$RuntimeDir"
		ls * | while read N
		do
			echo $N
		done
	) | (
		set -e
		while read N
		do
			ln -s "$RuntimeDir/$N" "$WorkDir/root/$InstallDir/$ModuleId/$N"
		done
	)
)

echo Platform=$Platform

case "$Platform" in
	arm64 )
		HostArchitectures="arm64"
		RID="osx-arm64"
		;;
	x86_64 | x64 )
		HostArchitectures="x86_64"
		RID="osx-x64"
		;;
	* )
		HostArchitectures="arm64,x86_64"
		RID="osx"
		;;
esac

PackageName="aspnetforpowershell"
FullPackageName="$PackageName-$PowerShellSdkVer-$RID.pkg"

(
	set -e

	cd "$WorkDir"

	(
		cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>arch</key>
        <array>
EOF

		case "$Platform" in
			arm64 | AnyCPU)
				echo "                <string>arm64</string>"
				;;
			* )
				;;
		esac

		case "$Platform" in
			x86_64 | x64 | AnyCPU)
				echo "                <string>x86_64</string>"
				;;
			* )
				;;
		esac

		cat << EOF
        </array>
</dict>
</plist>
EOF
	) > requirements.plist 

	cat requirements.plist

	cat > distribution.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <pkg-ref id="$PackageIdentifier"/>
    <options customize="never" require-scripts="false" hostArchitectures="$HostArchitectures"/>
    <choices-outline>
        <line choice="default">
            <line choice="$PackageIdentifier"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$PackageIdentifier" visible="false">
        <pkg-ref id="$PackageIdentifier"/>
    </choice>
    <pkg-ref id="$PackageIdentifier" version="$PowerShellSdkVer" onConclusion="none">$PackageName.pkg</pkg-ref>
    <title>AspNetCore $RuntimeVersion for PowerShell $PowerShellSdkVer</title>
</installer-gui-script>
EOF

	cat distribution.xml

	pkgbuild \
		--identifier "$PackageIdentifier" \
		--version "$PowerShellSdkVer" \
		--root "root$InstallDir" \
		--install-location "$InstallDir" \
		--sign "Developer ID Installer: $APPLE_DEVELOPER" \
		"$PackageName.pkg"

	productbuild \
		--distribution ./distribution.xml \
		--product requirements.plist \
		--package-path . \
		"$FullPackageName" \
		--sign "Developer ID Installer: $APPLE_DEVELOPER"
)

mv "$WorkDir/$FullPackageName" "$OutDir$FullPackageName"
