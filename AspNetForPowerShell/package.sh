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
Platform="$7"
OutDir="$8"
RuntimeDir="$9"

LinuxDir="$OutDir"linux
IsAnyCPU=false
IsDebian=false
IsRpm=false
PowerShellSuffix=1
PowerShellDependsDotnetRuntime=false

for d in $( . /etc/os-release ; echo $ID $ID_LIKE )
do
	case "$d" in
		debian )
			IsDebian=true
			PowerShellSuffix=1.deb
			;;
		fedora | rhel )
			IsRpm=true
			PowerShellSuffix=1.rh
			;;
		mariner )
			IsRpm=true
			PowerShellSuffix=1.cm
			;;
		* )
			;;
	esac
done

if $IsRpm
then
	if ( rpm -qR powershell | grep "^dotnet-runtime-" )
	then
		PowerShellDependsDotnetRuntime=true
	fi
fi

case "$Platform" in
	"AnyCPU" )
		IsAnyCPU=true
		if $IsDebian
		then
			Arch="all"
		else
			Arch="any"
		fi
		;;
	"arm64" )
		if $IsDebian
		then
			Arch="arm64"
		else
			Arch="aarch64"
		fi
		;;
	"arm32" | "arm" )
		if $IsDebian
		then
			Arch="armhf"
		else
			Arch="armhfp"
		fi
		;;
	"x64" )
		if $IsDebian
		then
			Arch="amd64"
		else
			Arch="x86_64"
		fi
		;;
	"x86" )
		Arch="i386"
		;;
	* )
		if $IsDebian
		then
			Arch=$(dpkg --print-architecture)
		else
			Arch=$(arch)
		fi
		;;
esac

case $PowerShellSdkVer in
	7.0.* | 7.1.* )
		PowerShellSuffix=$( . /etc/os-release ; echo 1.$ID.$VERSION_ID )
		;;
	* )
		;;
esac

cleanup()
{
	chmod -R +w "$LinuxDir"
	rm -rf "$LinuxDir"
}

trap cleanup 0

mkdir -p "$LinuxDir/data/opt/microsoft/powershell/7/Modules/$ModuleId"
mkdir -p "$LinuxDir/control"

echo 2.0 > "$LinuxDir/debian-binary"

if $PowerShellDependsDotnetRuntime
then
	for d in "$OutDir$ModuleId/"*
	do
		N=$(basename "$d")
		if test ! -e "$RuntimeDir/$N"
		then
			cp "$d" "$LinuxDir/data/opt/microsoft/powershell/7/Modules/$ModuleId"
		fi
	done
else
	cp -R "$OutDir$ModuleId/"* "$LinuxDir/data/opt/microsoft/powershell/7/Modules/$ModuleId"

	if $IsAnyCPU
	then
		(
			set -e
			cd "$RuntimeDir"
			for d in *
			do
				echo "$d"
			done
		) | (
			set -e
			cd "$LinuxDir/data/opt/microsoft/powershell/7/Modules/$ModuleId"
			while read N
			do
				ln -s "/usr/share/dotnet/shared/Microsoft.AspNetCore.App/$Version/$N" "$N"
			done
		)
	fi
fi

if $IsDebian
then
	if $IsAnyCPU
	then
		Depends="powershell (=$PowerShellSdkVer-$PowerShellSuffix), aspnetcore-runtime-$Channel (=$Version-1)"
	else
		Depends="powershell (=$PowerShellSdkVer-$PowerShellSuffix)"
	fi

	InstalledSize=$(du -sk "$LinuxDir/data")
	InstalledSize=$(for d in $InstalledSize; do echo $d; break; done)
	PackageName=rhubarb-geek-nz-aspnetforpowershell

	cat > "$LinuxDir/control/control" <<EOF
Package: $PackageName
Version: $PowerShellSdkVer-$PowerShellSuffix
Architecture: $Arch
Depends: $Depends
Section: devel
Priority: standard
Installed-Size: $InstalledSize
Maintainer: rhubarb-geek-nz@users.sourceforge.net
Description: AspNetCore For PowerShell $PowerShellSdkVer
EOF

	(
		set -e
		cd "$LinuxDir"

		chmod -R -w data control debian-binary
	
		tar --owner=0 --group=0 --gzip --create --file control.tar.gz -C control control

		tar --owner=0 --group=0 --gzip --create --file data.tar.gz -C data  "opt/microsoft/powershell/7/Modules/$ModuleId"

		ar r "$PackageName"_"$PowerShellSdkVer-$PowerShellSuffix"_"$Arch".deb debian-binary control.tar.* data.tar.*
	)

	mv "$LinuxDir"/*.deb "$OutDir"
fi
