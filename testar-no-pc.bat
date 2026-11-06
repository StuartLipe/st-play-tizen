@echo off
rem Abre o ST PLAY no PC numa janela 1920x1080, simulando a TV.
rem O app e o mesmo que a TV carrega: http://127.0.0.1/
cd /d "%~dp0"

set EDGE="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if not exist %EDGE% set EDGE="C:\Program Files\Microsoft\Edge\Application\msedge.exe"

echo Abrindo o ST PLAY em janela de TV (1920x1080)...
echo.
echo   Setas + Enter  = controle remoto
echo   Ctrl+Shift+I   = DevTools (console/rede)
echo   Ctrl+Shift+W   = fecha
echo.

start "" %EDGE% --app=http://127.0.0.1/ --window-size=1920,1080 --window-position=0,0 --user-data-dir="%LOCALAPPDATA%\STPLAY-TV-TEST"

echo Se a janela nao abrir, use o navegador normal em: http://127.0.0.1/
timeout /t 5 /nobreak >nul
