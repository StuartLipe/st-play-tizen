@echo off
rem Sobe tudo: servidor do app (porta 80) + tunel publico do Cloudflare.
cd /d "%~dp0"

echo [1/3] Servidor do app na porta 80...
start "STPLAY servidor" /min cmd /c "set PORT=80&& set LOG_FILE=%~dp0tools\requests.log&& node proxy\proxy-server.cjs"

echo [2/3] Tunel publico...
if exist "%~dp0tools\cloudflared.log" del /q "%~dp0tools\cloudflared.log"
start "STPLAY tunel" /min cmd /c "tools\cloudflared.exe tunnel --url http://localhost:80 --no-autoupdate --logfile %~dp0tools\cloudflared.log"

echo [3/3] Aguardando o tunel (15s)...
timeout /t 15 /nobreak >nul

echo.
echo ============================================================
echo   NA TV, abra o app Internet e entre em:
echo.
for /f "tokens=*" %%L in ('findstr /C:"trycloudflare.com" "%~dp0tools\cloudflared.log" ^| findstr /C:"https://"') do @echo   %%L
echo.
echo   Na rede local tambem funciona:  http://192.168.100.196/
echo ============================================================
echo.
echo Deixe esta janela aberta (os dois processos rodam minimizados).
pause
