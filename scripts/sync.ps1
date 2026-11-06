#Requires -Version 5.1
<#
.SYNOPSIS
    Builda o st-app (Vite), copia o dist/ para a raiz deste projeto Tizen e
    injeta a configuracao do proxy.

.DESCRIPTION
    O build do Vite usa base: './', entao os caminhos dos assets ja saem
    relativos - que e o que o motor do Tizen (carregando de file://) precisa.

    O alvo do build e rebaixado por padrao para chrome63 (Tizen 4.0 / 2018).
    TVs 2015-2017 tem Chromium mais antigo: use -Target chrome49.

    A configuracao do proxy vai em stplay-config.js, carregado antes do bundle.
    Nao da para usar script inline: a CSP do build e script-src 'self'.

.PARAMETER AppDir
    Pasta do st-app. Padrao: ..\st-app

.PARAMETER SkipBuild
    So copia o dist/ existente, sem rodar npm run build.

.PARAMETER ProxyHost
    IP deste PC na LAN, o mesmo que esta no campo Host PC IP da TV.

.PARAMETER ProxyPort
    Porta do proxy-server.cjs. Padrao: 8787

.PARAMETER Target
    Alvo do esbuild. Padrao: chrome63

.EXAMPLE
    .\scripts\sync.ps1
    .\scripts\sync.ps1 -ProxyHost 192.168.100.196 -Target chrome49
#>
[CmdletBinding()]
param(
    [string]$AppDir,
    [switch]$SkipBuild,
    [string]$ProxyHost = '192.168.100.196',
    [int]$ProxyPort = 80,
    [string]$Target = 'chrome63',
    [string]$PanelHost = 'http://gmaster1.shop',
    [string]$PanelUser = '639563670',
    [string]$PanelPass = '334918348',
    [string]$TunnelUrl = 'https://cst-first-frequencies-tremendous.trycloudflare.com'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $AppDir) { $AppDir = Join-Path $root '..\st-app' }

if (-not (Test-Path $AppDir)) { throw "Pasta do app nao encontrada: $AppDir" }
$AppDir = (Resolve-Path $AppDir).Path

if (-not $SkipBuild) {
    Write-Host ">> npm run build -- --target $Target  (em $AppDir)"
    Push-Location $AppDir
    try {
        npm run build -- --target $Target
        if ($LASTEXITCODE -ne 0) { throw "npm run build falhou (exit $LASTEXITCODE)" }
    }
    finally { Pop-Location }
}

$dist = Join-Path $AppDir 'dist'
if (-not (Test-Path (Join-Path $dist 'index.html'))) {
    throw "dist/index.html nao existe. Rode o build primeiro."
}

# Limpa so o que veio do dist. config.xml, .project, res/, scripts/, proxy/ e
# stplay-config.js ficam intactos.
Get-ChildItem $dist -Force | ForEach-Object {
    $destino = Join-Path $root $_.Name
    if (Test-Path $destino) { Remove-Item $destino -Recurse -Force }
}
Get-ChildItem $dist -Force | Copy-Item -Destination $root -Recurse -Force

$index = Join-Path $root 'index.html'
if (-not (Select-String -Path $index -Pattern 'src="\./assets/' -Quiet)) {
    Write-Warning "index.html nao aponta para ./assets/ - confira base: './' no vite.config.ts."
}

# ---------------------------------------------------------------------------
# Proxy: o renderer le window.sturplay.proxyBase (src/lib/proxy.ts) e monta
# "<base>?url=<encoded>". Sem isso ele cai no fallback /api/proxy, que no
# Tizen nao existe.
# ---------------------------------------------------------------------------
$proxyBase = "http://${ProxyHost}:${ProxyPort}/proxy"
$proxyTunnel = $TunnelUrl.TrimEnd('/') + '/proxy'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$config = Join-Path $root 'stplay-config.js'
$template = Join-Path $PSScriptRoot 'stplay-config.template.js'
$js = Get-Content $template -Raw
$js = $js.Replace('__PROXY_LAN__', $proxyBase).Replace('__PROXY_TUNNEL__', $proxyTunnel).Replace('__HOST__', $PanelHost).Replace('__USER__', $PanelUser).Replace('__PASS__', $PanelPass)
$bundle = ''
$m = Select-String -Path $index -Pattern 'assets/(index-[^"]+\.js)' | Select-Object -First 1
if ($m) { $bundle = $m.Matches[0].Groups[1].Value }
$js = $js.Replace('__BUILD__', $bundle)
[System.IO.File]::WriteAllText($config, $js, $utf8)
Copy-Item (Join-Path $PSScriptRoot 'tizen-ui.js') (Join-Path $root 'tizen-ui.js') -Force

$html = Get-Content $index -Raw
$versao = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$html = $html -replace '\s*<script src="\./(stplay-config|tizen-ui)\.js(\?v=\d+)?"></script>', ''
if ($html -notmatch '<head>') { throw 'index.html sem <head> - nao deu para injetar os scripts.' }
$tag = "<script src=""./stplay-config.js?v=$versao""></script>" + [Environment]::NewLine + "    <script src=""./tizen-ui.js?v=$versao""></script>"
$newline = [Environment]::NewLine
$html = $html -replace '<head>', ('<head>' + $newline + '    ' + $tag)
[System.IO.File]::WriteAllText($index, $html, $utf8)

Write-Host ""
Write-Host "OK: dist sincronizado em $root" -ForegroundColor Green
Write-Host "Proxy configurado: $proxyBase"
Write-Host ""
Write-Host "Falta: .\scripts\pack.ps1  e  .\scripts\install.ps1 -TvIp <ip-da-tv>"
