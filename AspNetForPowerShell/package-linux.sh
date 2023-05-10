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

RuntimeDir="usr/share/dotnet/shared/Microsoft.AspNetCore.App/$RuntimeVersion"
InstallDir="opt/microsoft/powershell/7/Modules"

ls -ld "$IntDir" "$OutDir" "/$InstallDir" > /dev/null

LinuxDir="$OutDir"linux
IsAnyCPU=false
IsDebian=false
IsRpm=false
PowerShellSuffix=1

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

case "$Platform" in
	"AnyCPU" )
		IsAnyCPU=true
		if $IsDebian
		then
			Arch="all"
		else
			Arch="noarch"
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

mkdir -p "$LinuxDir/data/$InstallDir"
mkdir -p "$LinuxDir/control"

echo 2.0 > "$LinuxDir/debian-binary"

cp -R "$OutDir$ModuleId" "$LinuxDir/data/$InstallDir/$ModuleId"

AspNetCoreDir="$LinuxDir/aspnetcore-$RuntimeVersion"

case "$Platform" in
	AnyCPU )
		Architecture='<auto>'
		;;
	arm32 )
		 Architecture='arm'
		;;
	* )
		Architecture="$Platform"
		;;
esac

curl --silent --fail --location --output "$LinuxDir/dotnet-install.sh" "https://dot.net/v1/dotnet-install.sh"
		
mkdir "$AspNetCoreDir"

chmod +x "$LinuxDir/dotnet-install.sh"

"$LinuxDir/dotnet-install.sh" --install-dir "$AspNetCoreDir" --runtime aspnetcore --channel "$Channel" --version "$RuntimeVersion" --architecture "$Architecture"

AspNetCoreDir="$AspNetCoreDir/shared/Microsoft.AspNetCore.App/$RuntimeVersion"

ls -ld "$AspNetCoreDir" >/dev/null

if $IsAnyCPU
then
	(
		set -e
		cd "$AspNetCoreDir"
		for d in *
		do
			echo "$d"
		done
	) | (
		set -e
		cd "$LinuxDir/data/$InstallDir/$ModuleId"
		while read N
		do
			ln -s "/$RuntimeDir/$N" "$N"
		done
	)
else
	cp -R "$AspNetCoreDir"/* "$LinuxDir/data/$InstallDir/$ModuleId/"
fi

if $IsDebian
then
	if $IsAnyCPU
	then
		Depends="powershell (=$PowerShellSdkVer-$PowerShellSuffix), aspnetcore-runtime-$Channel (=$RuntimeVersion-1)"
	else
		Depends="powershell (=$PowerShellSdkVer-$PowerShellSuffix)"
	fi

	InstalledSize=$(du -sk "$LinuxDir/data")
	InstalledSize=$(for d in $InstalledSize; do echo $d; break; done)
	PackageName=rhubarb-geek-nz-aspnetforpowershell

	Maintainer=$(git config user.email)

	cat > "$LinuxDir/control/control" <<EOF
Package: $PackageName
Version: $PowerShellSdkVer-$PowerShellSuffix
Architecture: $Arch
Depends: $Depends
Section: devel
Priority: standard
Installed-Size: $InstalledSize
Maintainer: $Maintainer
Description: AspNetCore $RuntimeVersion For PowerShell $PowerShellSdkVer
EOF

	(
		set -e
		cd "$LinuxDir"

		chmod -R -w data control debian-binary
	
		tar --owner=0 --group=0 --gzip --create --file control.tar.gz -C control control

		tar --owner=0 --group=0 --gzip --create --file data.tar.gz -C data "$InstallDir/$ModuleId"

		ar r "$PackageName"_"$PowerShellSdkVer-$PowerShellSuffix"_"$Arch".deb debian-binary control.tar.* data.tar.*
	)

	mv "$LinuxDir"/*.deb "$OutDir"
fi

if $IsRpm
then
	MajorVersion=$(echo $PowerShellSdkVer | sed "y/./ /" | while read A B C; do echo $A; done)
	MinorVersion=$(echo $PowerShellSdkVer | sed "y/./ /" | while read A B C; do pwsh -c $B+1; done)

	RuntimeSummary="$RuntimeVersion"
	if $IsAnyCPU
	then
		Requires="powershell >= $PowerShellSdkVer, powershell < $MajorVersion.$MinorVersion, aspnetcore-runtime-$Channel = $RuntimeVersion"
	else
		Requires="powershell >= $PowerShellSdkVer, powershell < $MajorVersion.$MinorVersion"
	fi

	PackageName=rhubarb-geek-nz-aspnetforpowershell

	(
		set -e
		cd "$LinuxDir"

		(
			cat << EOF
Summary: AspNetCore $RuntimeSummary For PowerShell $PowerShellSdkVer
Name: $PackageName
Requires: $Requires
Version: $PowerShellSdkVer
Release: $PowerShellSuffix
Group: Development/Libraries
License: MIT
BuildArch: $Arch
Prefix: /$InstallDir

%description
PowerShell Cmdlets for AspNet

%files
%defattr(-,root,root)
EOF
			(
				set -e
				cd data
				find $InstallDir/$ModuleId | while read N
				do
					if test -h "$N"
					then
						echo "/$N"
					else
						if test -d "$N"
						then
							echo "%dir %attr(555,-,-) /$N"
						else
							echo "%attr(444,-,-) /$N"
						fi
					fi
				done
			)
			
			echo "%clean"
		) > rpm.spec

		PWD=$(pwd)
		rpmbuild --buildroot "$PWD/data" --define "_rpmdir $PWD/rpms" -bb "$PWD/rpm.spec"
	)

	find "$LinuxDir/rpms" -type f -name "*.rpm" | while read N
	do
		ls -ld "$N"
		mv "$N" "$OutDir"
	done
fi
