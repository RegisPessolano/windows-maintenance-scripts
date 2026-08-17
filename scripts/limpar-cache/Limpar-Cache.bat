@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "DRY_RUN=0"
set "ALL_USERS=0"

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="/dry-run" (
    set "DRY_RUN=1"
    shift
    goto :parse_args
)
if /i "%~1"=="/all-users" (
    set "ALL_USERS=1"
    shift
    goto :parse_args
)
goto :usage

:args_done
if "%ALL_USERS%"=="1" (
    net session >nul 2>&1
    if errorlevel 1 (
        echo [ERRO] O modo /all-users exige execucao como Administrador.
        exit /b 1
    )
)

echo Limpador conservador de caches do Windows e navegadores.
if "%DRY_RUN%"=="1" echo [SIMULACAO] Nenhum arquivo sera removido.
echo Feche os navegadores antes de continuar.
choice /c SN /n /m "Continuar? [S/N]: "
if errorlevel 2 (
    echo Operacao cancelada.
    exit /b 0
)

if "%ALL_USERS%"=="1" (
    for /d %%P in ("%SystemDrive%\Users\*") do call :clean_profile "%%~fP"
    call :clean_dir "%SystemRoot%\Temp" "Temporarios do Windows"
) else (
    call :clean_profile "%USERPROFILE%"
)

echo.
echo [OK] Limpeza concluida. Arquivos em uso foram preservados automaticamente.
exit /b 0

:clean_profile
set "PROFILE_ROOT=%~1"
if not exist "!PROFILE_ROOT!\AppData\Local" exit /b 0
echo.
echo Perfil: !PROFILE_ROOT!
call :clean_dir "!PROFILE_ROOT!\AppData\Local\Temp" "Temporarios do usuario"
call :clean_dir "!PROFILE_ROOT!\AppData\Local\Microsoft\Windows\INetCache" "Cache de Internet do Windows"
call :clean_dir "!PROFILE_ROOT!\AppData\Local\Microsoft\Windows\WER\ReportArchive" "Relatorios WER arquivados"
call :clean_dir "!PROFILE_ROOT!\AppData\Local\Microsoft\Terminal Server Client\Cache" "Cache do cliente RDP"
call :clean_chromium "!PROFILE_ROOT!\AppData\Local\Google\Chrome\User Data" "Google Chrome"
call :clean_chromium "!PROFILE_ROOT!\AppData\Local\Microsoft\Edge\User Data" "Microsoft Edge"
call :clean_chromium "!PROFILE_ROOT!\AppData\Local\BraveSoftware\Brave-Browser\User Data" "Brave"
call :clean_chromium "!PROFILE_ROOT!\AppData\Local\Vivaldi\User Data" "Vivaldi"
call :clean_chromium "!PROFILE_ROOT!\AppData\Roaming\Opera Software\Opera Stable" "Opera"
for /d %%F in ("!PROFILE_ROOT!\AppData\Local\Mozilla\Firefox\Profiles\*") do call :clean_dir "%%~fF\cache2" "Firefox cache2"
exit /b 0

:clean_chromium
if not exist "%~1" exit /b 0
for /d %%D in ("%~1\*") do (
    call :clean_dir "%%~fD\Cache" "%~2 Cache"
    call :clean_dir "%%~fD\Code Cache" "%~2 Code Cache"
    call :clean_dir "%%~fD\GPUCache" "%~2 GPUCache"
)
exit /b 0

:clean_dir
if not exist "%~1" exit /b 0
echo   - %~2
if "%DRY_RUN%"=="1" (
    echo     [SIMULACAO] "%~1"
    exit /b 0
)
del /f /s /q "%~1\*" >nul 2>&1
for /d %%D in ("%~1\*") do rd /s /q "%%~fD" >nul 2>&1
exit /b 0

:usage
echo Uso: %~nx0 [/dry-run] [/all-users]
echo.
echo   /dry-run   Lista os locais sem excluir arquivos.
echo   /all-users Limpa perfis locais e Temp do Windows; exige Administrador.
exit /b 2
