#!/bin/sh -e
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
Configuration="$1"
TargetFramework="$2"
Version="$3"
PowerShellSdkVer="$4"
ModuleId="$5"
Channel="$6"
BinDir="bin/$Configuration/$TargetFramework"
ObjDir="obj/$Configuration/$TargetFramework"
SdkDir="$ObjDir/sdk-$Version"
DebianDir="$BinDir/debian"

IsNotDebian=true

for d in $( . /etc/os-release ; echo $ID $ID_LIKE )
do
	case "$d" in
		debian )
			IsNotDebian=false
			;;
		* )
			;;
	esac
done

if $IsNotDebian
then
	exit 0
fi

case $PowerShellSdkVer in
	7.0.* | 7.1.* )
		PowerShellSuffix=$( . /etc/os-release ; echo $ID.$VERSION_ID )
		;;
	* )
		PowerShellSuffix=1.deb

		;;
esac

cleanup()
{
	chmod -R +w "$DebianDir"
	rm -rf "$DebianDir"
}

trap cleanup 0

mkdir -p "$DebianDir/data/opt/microsoft/powershell/7/Modules/$ModuleId"
mkdir -p "$DebianDir/control"

echo 2.0 > "$DebianDir/debian-binary"

cp "$BinDir"/*.dll "$BinDir/$ModuleId/$ModuleId.psd1" "$DebianDir/data/opt/microsoft/powershell/7/Modules/$ModuleId"

(
	set -e
	cd "$SdkDir/shared/Microsoft.AspNetCore.App/$Version"
	find * | grep -v "/"
) | (
	set -e
	cd "$DebianDir/data/opt/microsoft/powershell/7/Modules/$ModuleId"
	while read N
	do
		ln -s "/usr/share/dotnet/shared/Microsoft.AspNetCore.App/$Version/$N" "$N"
	done
)

InstalledSize=$(du -sk "$DebianDir/data")
InstalledSize=$(for d in $InstalledSize; do echo $d; break; done)
PackageName=rhubarb-geek-nz-aspnetforpowershell
cat > "$DebianDir/control/control" <<EOF
Package: $PackageName
Version: $PowerShellSdkVer-$PowerShellSuffix
Architecture: all
Depends: powershell (=$PowerShellSdkVer-$PowerShellSuffix), aspnetcore-runtime-$Channel (=$Version-1)
Section: devel
Priority: standard
Installed-Size: $InstalledSize
Maintainer: rhubarb-geek-nz@users.sourceforge.net
Description: AspNetCore For PowerShell
EOF

(
	set -e
	cd "$DebianDir"

	chmod -R -w data control debian-binary
	
	(
		set -e
		cd control
		tar --owner=0 --group=0 --gzip --create --file - control
	) > control.tar.gz

	(
		set -e
		cd data
		tar --owner=0 --group=0 --gzip --create --file - "opt/microsoft/powershell/7/Modules/$ModuleId"
	) > data.tar.gz

	ar r "$PackageName"_"$PowerShellSdkVer-$PowerShellSuffix"_all.deb debian-binary control.tar.* data.tar.*	
)

mv "$DebianDir"/*.deb "$BinDir"
