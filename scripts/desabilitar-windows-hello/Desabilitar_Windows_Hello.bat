@echo off
setlocal

net session >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Execute este script como Administrador.
    exit /b 1
)

set "POLICY_KEY=HKLM\SOFTWARE\Policies\Microsoft\PassportForWork"

if /i "%~1"=="/undo" goto :undo
if not "%~1"=="" goto :usage

echo Este script desabilita o provisionamento do Windows Hello for Business.
echo Credenciais ja provisionadas podem continuar presentes.
choice /c SN /n /m "Deseja continuar? [S/N]: "
if errorlevel 2 (
    echo Operacao cancelada.
    exit /b 0
)

reg add "%POLICY_KEY%" /v Enabled /t REG_DWORD /d 0 /f >nul
if errorlevel 1 (
    echo [ERRO] Nao foi possivel alterar a politica.
    exit /b 1
)

echo [OK] Windows Hello for Business desabilitado por politica local.
echo Reinicie o computador para aplicar a alteracao.
exit /b 0

:undo
reg delete "%POLICY_KEY%" /v Enabled /f >nul 2>&1
if errorlevel 1 (
    echo [AVISO] O valor nao existia ou nao pode ser removido.
    exit /b 1
)
echo [OK] Configuracao local removida. Uma politica corporativa ainda pode ser aplicada.
echo Reinicie o computador para aplicar a alteracao.
exit /b 0

:usage
echo Uso: %~nx0 [/undo]
exit /b 2
