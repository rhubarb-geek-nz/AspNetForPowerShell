# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

param($args)

trap
{
	throw $PSItem
}

$app = New-AspNetForPowerShellWebApplication -ArgumentList $args

$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

$env = $app.Services.GetService([Microsoft.AspNetCore.Hosting.IWebHostEnvironment])
$log = $app.Services.GetService([Microsoft.Extensions.Logging.ILogger[RhubarbGeekNz.AspNetForPowerShell.NewRequestDelegate]])

foreach ($var in
	('ContentRootPath',$env.ContentRootPath,'Content Root Path'),
	('WebRootPath',$env.WebRootPath,'Web Root Path'),
	('Logger',$log,'Logger')
)
{
	$iss.Variables.Add((New-Object -TypeName 'System.Management.Automation.Runspaces.SessionStateVariableEntry' -ArgumentList $var))
}

$bindingFlags = [int32][System.Reflection.BindingFlags]::Static + [int32][System.Reflection.BindingFlags]::NonPublic

$script = $Resources.GetProperty('RequestDelegate',$bindingFlags).GetValue($null)

$delegate = New-AspNetForPowerShellRequestDelegate -Script $script -InitialSessionState $iss

[Microsoft.AspNetCore.Builder.RunExtensions]::Run($app,$delegate)

$app.Run()
