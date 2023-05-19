# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

param($app,$env,$log,$res)

trap
{
	throw $PSItem
}

$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

foreach ($var in
	('ContentRootPath',$env.ContentRootPath,'Content Root Path'),
	('WebRootPath',$env.WebRootPath,'Web Root Path'),
	('Logger',$log,'Logger')
)
{
	$iss.Variables.Add((New-Object -TypeName 'System.Management.Automation.Runspaces.SessionStateVariableEntry' -ArgumentList $var))
}

$script = $res.GetProperty('RequestDelegate',[System.Reflection.BindingFlags]'Static, NonPublic').GetValue($null)

$delegate = New-AspNetForPowerShellRequestDelegate -Script $script -InitialSessionState $iss

[Microsoft.AspNetCore.Builder.RunExtensions]::Run($app,$delegate)
