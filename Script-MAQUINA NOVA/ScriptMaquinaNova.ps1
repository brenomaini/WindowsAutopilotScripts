cls
Write-Host ""
Write-Host "#########  INSERIR OS DADOS COM EXTREMA ATENCAO:  #########"
Write-Host ""

Write-Host "Qual o E-MAIL do colaborador que usara a maquina? Ex: breno.maini@empresa.com"
$emailGL = Read-Host
Write-Host ""

Write-Host "Qual o HOSTNAME da maquina?"
$patrimonio = Read-Host
Write-Host ""

Write-Host "Qual o nome SETOR/CC do colaborador?"
$setor = Read-Host
Write-Host ""

$serial = (Get-WmiObject -class win32_bios).SerialNumber

cls

Write-Host ""
Write-Host ""
Write-Host "#########    DADOS QUE SERAO INFORMADOS NA NUVEM    #########"
Write-Host ""
Write-Host "E-mail:  " $email
Write-Host "Hostname:" $hostname
Write-Host "Setor/CC:" $setor
Write-Host "Serial:  " $serial
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""

Install-Script -name Get-WindowsAutopilotInfo -Force
Get-WindowsAutoPilotInfo -AssignedUser $email -GroupTag $setor -AssignedComputerName $hostname-Online