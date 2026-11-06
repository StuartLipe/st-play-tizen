#Requires -Version 5.1
<#
.SYNOPSIS
    Instala o .wgt na TV Samsung via sdb e abre o app.

.DESCRIPTION
    A TV precisa estar com Developer Mode ligado, Host PC IP preenchido com o
    IP deste PC e - importante - ter sido REINICIADA depois disso. Sem o
    restart, a porta 26101 nao abre e o sdb nao conecta.

.PARAMETER TvIp
    IP da TV (Configuracoes > Rede > Status da Rede). Ex.: 192.168.100.14

.PARAMETER Wgt
    Caminho do .wgt. Se omitido, usa o .wgt mais recente da pasta do projeto.

.PARAMETER AppId
    Application ID do config.xml (package.nome).

.EXAMPLE
    .\scripts\install.ps1 -TvIp 192.168.100.14
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TvIp,

    [string]$Wgt,

    [string]$AppId = 'stplay0001.STPlayTV',

    [string]$TizenHome = 'C:\tizen-studio'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$sdb = Join-Path $TizenHome 'tools\sdb.exe'

if (-not (Test-Path $sdb)) { throw "sdb nao encontrado em $sdb." }

if (-not $Wgt) {
    $Wgt = Get-ChildItem $root -Filter *.wgt -File -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $Wgt -or -not (Test-Path $Wgt)) { throw 'Nenhum .wgt encontrado. Rode .\scripts\pack.ps1 primeiro.' }

# Pre-checagem: sem a porta 26101 o sdb nunca conecta, e o erro dele nao
# explica o motivo. Aqui explica.
$tcp = Test-NetConnection -ComputerName $TvIp -Port 26101 -WarningAction SilentlyContinue
if (-not $tcp.TcpTestSucceeded) {
    throw @"
A porta 26101 da TV ($TvIp) esta fechada - o modo desenvolvedor nao subiu.

Checklist:
  1. Apps > 12345 > Developer mode = ON
  2. Host PC IP = 192.168.100.196 (este PC)
  3. REINICIAR a TV: segurar o power do controle por 5s ate aparecer o logo,
     ou tirar da tomada por 30s
  4. Esperar ~30s depois de ligar e rodar de novo

Obs.: a TV responde em 8001/8002 mesmo com o modo dev desligado, entao ping
funcionando NAO significa que o sdb esta disponivel.
"@
}

Write-Host ">> sdb connect ${TvIp}:26101"
& $sdb connect "${TvIp}:26101"
Start-Sleep -Seconds 2

Write-Host ">> sdb devices"
& $sdb devices
if ($LASTEXITCODE -ne 0) { throw "sdb devices falhou (exit $LASTEXITCODE)" }

Write-Host ">> sdb install `"$Wgt`""
& $sdb install $Wgt
if ($LASTEXITCODE -ne 0) {
    throw @"
sdb install falhou (exit $LASTEXITCODE). Checklist:
  - .wgt assinado com author + distributor (erro 118 = assinatura)
  - TV reiniciada depois de ligar o modo dev
  - Firewall do Windows liberando sdb.exe na porta 26101
"@
}

Write-Host ">> abrindo $AppId"
& $sdb shell 0 was_execute $AppId

Write-Host ""
Write-Host "Instalado. Logs: & `"$sdb`" dlog" -ForegroundColor Green
