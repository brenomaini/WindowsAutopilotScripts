# WindowsAutopilotScripts

---
Esse repositório visa permitir que outros alcancem as informações que levei certo tempo a encontrar.
Visto que muitas delas estão em inglês, algumas coisas não ficam tão simples de acharmos ou nem mesmo sabemos como procurá-las.
---
# Problemas solucionados no post

- Registro de máquina no INTUNE + Azure AD sem que o "registrante" fique com privilégios administrativos na máquina.
- Script para o registro de máquinas no Windows Autopilot sem a necessidade do upload em CSV.

# Contextualizando o problema
## Como surgiu a necessidade de resolver os problemas citados?

Um dos principais problemas que nosso time de Suporte Técnico tinha na empresa era:

**REGISTRO/INSERÇAO DAS MÁQUINAS NO AZURE AD SEM PERFIL DE ADMINISTRADOR**

Apenas colaboradores do time de Suporte Técnico com perfil de administrador podiam fazer o registro/inserção de novas máquinas e nós não entendíamos o porque.(Configuração havia sido feita por um parceiro terceirizado).

Com a chegada de um novo gerente, tal trava foi questionada e os testes começaram. Algumas configurações foram alteradas e a partir desse momento *QUALQUER COLABORADOR da companhia poderia registrar sua máquina no AD com a conta empresarial*. 

E ai surgia outro problema: Quem fizesse o registro, se tornaria o administrador local da máquina. E não, não havia nada que pudéssemos fazer ele se tornaria o dono da máquina.

E aqui começou a saga do Windows Autopilot...

# WINDOWS AUTOPILOT

Já no inicio das pesquisas sobre como gerenciar os administradores locais das máquinas via AD, entendemos que seria possível apenas de dois modos: [LINK REFERÊNCIA](https://medium.com/r?url=https%3A%2F%2Flearn.microsoft.com%2Fpt-br%2Fazure%2Factive-directory%2Fdevices%2Fassign-local-admin)

1. Via Windows Autopilot
2. Via Registro em massa (Nem fomos atrás, pois era uma explicaçao horrenda)

Como o Windows autopilot já era um desejo nosso, apenas abordaremos essa alternativa por aqui.

### Problema: REGISTRO WINDOWS AUTOPILOT - COMO É FEITO?
Mais uma vez, temos apenas duas alternativas:

1. Que o computador já venha configurado direto da fábrica de seu fornecedor.
2. Que você faça o registro manualmente através do upload de um CSV contendo o Hash do Hardware.

E aqui o post começa a entrar na parte legal..

# Solução: REGISTRANDO A MÁQUINA NO WINDOWS AUTOPILOT SEM UM ARQUIVO CSV

No site da Microsoft eles orientam a fazer o registro com o CSV utilizando o seguinte código (Via PowerShell elevado c/ direitos administrativos)

```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -Type Directory -Path "C:\HWID"
Set-Location -Path "C:\HWID"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-Script -Name Get-WindowsAutopilotInfo
Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv
```
> O comando acima funciona em qualquer máquina, esteja ela inserida no Azure AD ou não.
> No entanto, se imagine na seguinte situação (se já não é a que você se encontra agora): Você precisa registrar +500 máquinas para serem passíveis de controle via Windows Autopilot e precisará rodar esse código em todas essas máquinas, gerar o CSV, agrupá-lo para depois enviá-lo ao Graph.
> Um saco, né?

Contudo, se você ler um pouco mais abaixo, há um script um pouquinho diferente em que você pode utilizar na tela de OOBE (Out-of-box experience), aquela primeira telinha do Windows quando você liga um PC novo, retirado da caixa, em que você seleciona o País, idioma e etc..
O código:

```[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
PowerShell.exe -ExecutionPolicy Bypass
Install-Script -name Get-WindowsAutopilotInfo -Force
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Get-WindowsAutopilotInfo -Online
```

O Código acima, registra de forma online, solicitando apenas um login de administrador do INTUNE, todas as informações necessárias da máquina.(Hash e Serial number) sem a necessidade do export e upload do CSV.
Acredito que você já entendeu onde chegaremos..


# Personalizando o script para execução local em máquinas já no nosso parque. (Máquinas em uso)


```$scriptBlock = {
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
```

O Código acima registra uma máquina já em uso para o Windows Autopilot, ONLINE, e envia também as informações de "Usuário vinculado" e "GroupTag" que nada mais é que uma TAG que por aqui usamos para fazer o vinculo com o setor do colaborador.

## COMO RODAR O SCRIPT?


1. Copie o Script acima e salve-o com a extensão ".PS1" (PowerShell script).

2. Habilite a execução de scripts no computador. 
No menu iniciar, busque por "Script". Selecione -> Sistema -> Para desenvolvedores -> e altere a política de execução de Scripts na máquina, permitindo que sejam executados através de arquivos.

3. Execute o Script, responda as perguntas e confirme que a máquina foi registrada.


> Vale citar que os métodos de registro de máquinas já utilizadas são todos "péssimos" contudo, esse método foi uma das maneiras que encontramos de contornar a necessidade de -> Executar o Script -> Gerar o arquivo -> enviar pra outro PC-> Subir o arquivo.
> 
> Dessa forma, trocamos 4 Passos por apenas 2 quando já temos o script pronto. Ativar script -> Rodar Script.

---

## Script para execução em máquinas NOVAS, sem configuração prévia feita por fabricante. (Na tela OOBE).

---
Muito parecido com o script acima, nós coletamos algumas informações com o agente (que deve possuir privilégios de administrador do intune), realizamos o login na tela que abrirá e aguardamos até a conclusão do registro, religamos a máquina apenas para confirmar que tudo correu bem e a enviamos para o colaborador. (Segue passo a passo abaixo)
Script + BAT para a elevação

### SCRIPT .ps1


```cls
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
```
*Copie e Salve o script acima, em um pendrive, com o nome que desejar e a extensão .ps1 (Este nome será importante para o nosso próximo arquivo)*

### ARQUIVO BAT

```cls
PowerShell.exe -ExecutionPolicy Bypass -File .\NomeDoSeuScript.ps1 -Verb RunAs 
```
*Salve a linha acima em um arquivo com a extensão .bat (Atente-se para o nome do seu script, substitua o nome antes de salvá-lo.*

**Tanto o script quanto o bat devem estar na RAIZ DO PENDRIVE para que possam ser acessados de forma mais prática.**

### Explicando o porque de dois arquivos e não apenas um

Neste cenário, por se tratar de uma máquina nova ou formatada o processo deve ser executado na tela de OOBE do Windows, onde não temos acessos a pesquisas e interfaces muito práticas para o agente, pensando nisso, o arquivo .bat foi idealizado, pois ao invés de copiar e digitar todo o script ele apenas executaria uma linha Ex: "D:/ScriptAutopilot.bat" e tudo seguiria um fluxo determinado já pelo script. Facilitando a vida de todo mundo.

## Passo a passo MÁQUINA NOVA/FORMATADA

*Com os arquivos já na raiz do pendrive (como na imagem), insira o pendrive na máquina que deseja registrar.*

1.Inicie a máquina formatada ou tirada da caixa e aguarda na tela de seleção de país.

2. Pressione SHIT+F10 para que o Prompt de comando se abra. (Em alguns casos será necessário pressionar FN + SHIFT + F10 pois a tecla vem lockada por padrão em notebooks)
3.No prompt de comando, digite a letra atribuída a seu prendrive e execute o script com o nome informado.

> Exemplo de código de execução: "D:\ScriptAutopilot.bat"

Feito. Após isso, basta seguir os passos e finalizar o registro

Neste caso em específico, após a finalização do script aconselho fortemente que **ACOMPANHE O REGISTRO NA TELA DO INTUNE** pois é necessário aguardar que o perfil seja atribuído antes de reiniciar a máquina, caso você não espere e volte para a tela de OOBE e prossiga, será necessário formatar o computador novamente.
Caso isso ocorra, a parte boa é: se o computador já estiver registrado, após toda formatação ele voltará na tela do Autopilot com os registros "upados" previamente.


