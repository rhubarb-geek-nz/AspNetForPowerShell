param($app,$env,$res)

$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

$var = New-Object -TypeName 'System.Management.Automation.Runspaces.SessionStateVariableEntry' -ArgumentList 'ContentRoot',$env.ContentRootPath,'Content Root Path'

$iss.Variables.Add($var)

$handler = $res.GetProperty('Handler',40).GetValue($null)

$delegate = New-PowerShellDelegate $handler $iss

Set-PowerShellDelegate $app $delegate
