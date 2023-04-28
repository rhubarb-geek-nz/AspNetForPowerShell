param($app,$env,$res)

$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

$var = New-Object -TypeName 'System.Management.Automation.Runspaces.SessionStateVariableEntry' -ArgumentList 'ContentRoot',$env.ContentRootPath,'Content Root Path'

$iss.Variables.Add($var)

$script = $res.GetProperty('RequestDelegate',40).GetValue($null)

$delegate = New-PowerShellDelegate $script $iss

Set-PowerShellDelegate $app $delegate
