param($app,$env,$log,$res)

$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

foreach ($var in
	('ContentRootPath',$env.ContentRootPath,'Content Root Path'),
	('WebRootPath',$env.WebRootPath,'Web Root Path'),
	('Logger',$log,'Logger')
)
{
	$iss.Variables.Add((New-Object -TypeName 'System.Management.Automation.Runspaces.SessionStateVariableEntry' -ArgumentList $var))
}

$bindingFlags = [int32][System.Reflection.BindingFlags]::Static + [int32][System.Reflection.BindingFlags]::NonPublic

$script = $res.GetProperty('RequestDelegate',$bindingFlags).GetValue($null)

$delegate = New-PowerShellDelegate -Script $script -InitialSessionState $iss

Set-PowerShellDelegate -ApplicationBuilder $app -RequestDelegate $delegate
