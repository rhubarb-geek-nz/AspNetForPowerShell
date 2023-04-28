param($app,$iss,$handler)
$delegate = New-PowerShellDelegate $handler $iss
Set-PowerShellDelegate $app $delegate
