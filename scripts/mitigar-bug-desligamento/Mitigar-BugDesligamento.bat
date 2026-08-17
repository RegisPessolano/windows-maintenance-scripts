@echo off
setlocal

net session >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Execute este script como Administrador.
    exit /b 1
)

set "CURRENT_BUILD="
for /f "tokens=3" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul') do set "CURRENT_BUILD=%%A"
if not defined CURRENT_BUILD (
    echo [ERRO] Nao foi possivel identificar a build do Windows.
    exit /b 1
)

set "PRODUCT_NAME="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "PRODUCT_NAME=%%B"

echo Sistema detectado: %PRODUCT_NAME% ^(build %CURRENT_BUILD%^)
echo.
echo Esta mitigacao desabilita VBS, HVCI, Inicializacao Rapida e hibernacao.
echo Isso reduz protecoes de seguranca e remove a capacidade de hibernar.
echo Use somente apos confirmar que esses recursos causam o problema de desligamento.
choice /c SN /n /m "Aplicar a mitigacao? [S/N]: "
if errorlevel 2 (
    echo Operacao cancelada.
    exit /b 0
)

set "BACKUP_DIR=%~dp0backup"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1
if not exist "%BACKUP_DIR%" (
    echo [ERRO] Nao foi possivel criar a pasta de backup.
    exit /b 1
)

reg export "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "%BACKUP_DIR%\DeviceGuard.reg" /y >nul
if errorlevel 1 (
    echo [ERRO] Nao foi possivel salvar DeviceGuard. Nenhuma alteracao foi aplicada.
    exit /b 1
)

reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "%BACKUP_DIR%\Power.reg" /y >nul
if errorlevel 1 (
    echo [ERRO] Nao foi possivel salvar as configuracoes de energia. Nenhuma alteracao foi aplicada.
    exit /b 1
)

call :set_dword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0 || exit /b 1
call :set_dword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "RequirePlatformSecurityFeatures" 0 || exit /b 1
call :set_dword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0 || exit /b 1
call :set_dword "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0 || exit /b 1

powercfg.exe /hibernate off >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Falha ao desabilitar a hibernacao.
    echo Importe os arquivos da pasta backup para restaurar o Registro.
    exit /b 1
)

echo [OK] Mitigacao aplicada. Reinicie o computador.
echo Backups do Registro: "%BACKUP_DIR%"
exit /b 0

:set_dword
reg add "%~1" /v "%~2" /t REG_DWORD /d %~3 /f >nul
if errorlevel 1 (
    echo [ERRO] Falha ao configurar %~2.
    exit /b 1
)
echo [OK] %~2 = %~3
exit /b 0
