@echo off
rem Sobe o servidor do ST PLAY: entrega o app E o proxy na mesma porta.
rem Deixe esta janela aberta enquanto usar o app na TV.
cd /d "%~dp0"
if not exist "proxy\proxy-server.cjs" (
  echo proxy\proxy-server.cjs nao encontrado.
  pause
  exit /b 1
)
set PORT=80
echo.
echo   No navegador da TV, abra:  http://192.168.100.196/
echo.
echo   (porta 80 - nao precisa digitar porta)
echo.
node proxy\proxy-server.cjs
echo.
echo Servidor encerrado.
pause
