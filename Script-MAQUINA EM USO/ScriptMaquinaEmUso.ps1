$scriptBlock = {
cls
Write-Host ''
Write-Host '#########  INSERIR OS DADOS COM EXTREMA ATENCAO:  #########'
Write-Host ""

Write-Host "Qual o E-MAIL do colaborador que usara a maquina? Ex: breno.maini@empresa.com"
$email = Read-Host
Write-Host ""

Write-Host "Qual o HOSTNAME da maquina?"
$hostname= Read-Host
Write-Host ""

Write-Host "Qual o nome SETOR/CC do colaborador (Sera usado apenas para TAG)?"
$setor = Read-Host
Write-Host ""

$serial = (Get-WmiObject -class win32_bios).SerialNumber

cls

Write-Host ''
Write-Host '#########    DADOS QUE SERAO INFORMADOS NA NUVEM    #########'
Write-Host ""
Write-Host "E-mail:  " $email
Write-Host "Hostname:" $hostname
Write-Host "Setor/CC:" $setor
Write-Host "Serial:  " $serial
Write-Host ""
Write-Host ""
Pause

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-Script -Name Get-WindowsAutopilotInfo
Get-WindowsAutopilotInfo -AssignedUser $email -GroupTag $setor -AssignedComputerName $hostname -Online
}
Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList "-Command $scriptBlock -Answer S " 
