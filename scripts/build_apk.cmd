@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_apk.ps1" %*
exit /b %ERRORLEVEL%
