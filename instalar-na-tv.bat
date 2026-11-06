@echo off
rem Instala o ST PLAY na TV Samsung usando o Apps2Samsung (certificado Samsung).
cd /d "%~dp0"

echo ============================================================
echo   INSTALAR O ST PLAY NA TV
echo.
echo   Vai abrir o login da sua conta Samsung Developers no
echo   navegador. E o unico passo que precisa de voce.
echo ============================================================
echo.

tools\apps2samsung\apps2samsung-cli.exe install "ST PLAY.wgt" --tv 192.168.100.14

echo.
echo Terminou. Se deu erro, copie a mensagem acima.
pause
