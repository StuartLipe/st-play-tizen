#Requires -Version 5.1
<#
.SYNOPSIS
    Empacota e assina o projeto como .wgt, usando uma pasta de staging.

.DESCRIPTION
    O `tizen package` empacota TUDO que esta na pasta do projeto. Se apontar
    para a raiz, entram tambem cert/author.p12 (chave privada!), proxy/,
    scripts/ e README.md.

    Por isso o pacote e montado em build/package com apenas os arquivos do app.

.PARAMETER Profile
    Nome do security profile. Padrao: STPlayTV

.PARAMETER TizenHome
    Raiz do Tizen Studio. Padrao: C:\tizen-studio

.EXAMPLE
    .\scripts\pack.ps1
#>
[CmdletBinding()]
param(
    [string]$Profile = 'STPlayTV',
    [string]$TizenHome = 'C:\tizen-studio'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$tizen = Join-Path $TizenHome 'tools\ide\bin\tizen.bat'

if (-not (Test-Path $tizen)) {
    throw "Tizen CLI nao encontrado em $tizen."
}
if (-not (Test-Path (Join-Path $root 'config.xml'))) {
    throw 'config.xml ausente na raiz do projeto.'
}

$stage = Join-Path $root 'build\package'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force $stage | Out-Null

# Arquivos do app (gerados pelo sync.ps1)
$files = @('config.xml', '.project', 'index.html', 'stplay-config.js', 'tizen-ui.js', 'favicon.svg', 'hamster.jpg', 'hamster.png', 'icon.ico', 'icons.svg')
foreach ($f in $files) {
    $src = Join-Path $root $f
    if (Test-Path $src) { Copy-Item $src $stage -Force }
}
foreach ($d in @('assets', 'res')) {
    $src = Join-Path $root $d
    if (Test-Path $src) { Copy-Item $src $stage -Recurse -Force }
}

# Trava de seguranca: nenhuma chave privada pode entrar no pacote.
$vazamento = Get-ChildItem $stage -Recurse -File -Include *.p12, *.pwd, *.pem -ErrorAction SilentlyContinue
if ($vazamento) { throw "Chave privada na pasta de pacote: $($vazamento.FullName -join ', ')" }

if (-not (Test-Path (Join-Path $stage 'index.html'))) { throw 'index.html nao esta no staging. Rode .\scripts\sync.ps1.' }

Get-ChildItem $root -Filter *.wgt -File -ErrorAction SilentlyContinue | Remove-Item -Force

$env:JAVA_HOME = Join-Path $TizenHome 'jdk'
Write-Host ">> tizen package -t wgt -s $Profile (staging: $stage)"
& $tizen package -t wgt -s $Profile -o $root -- $stage
if ($LASTEXITCODE -ne 0) { throw "tizen package falhou (exit $LASTEXITCODE)" }

$wgt = Get-ChildItem $root -Filter *.wgt -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $wgt) { throw 'Nenhum .wgt foi gerado.' }

Write-Host ""
Write-Host ("WGT: {0} ({1:N2} MB)" -f $wgt.FullName, ($wgt.Length / 1MB)) -ForegroundColor Green
Write-Host "Agora: .\scripts\install.ps1 -TvIp 192.168.100.14"
