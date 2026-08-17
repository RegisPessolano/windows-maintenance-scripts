@echo off
setlocal EnableExtensions

set "POLICY_KEY=HKLM\SOFTWARE\Policies\Microsoft\Edge"
set "BACKUP_DIR=%~dp0backup"
set "BACKUP_FILE=%BACKUP_DIR%\edge-policy-before-clean.reg"
set "ABSENT_MARKER=%BACKUP_DIR%\edge-policy-key-was-absent.marker"

net session >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Execute este script como Administrador.
    exit /b 1
)

if /i "%~1"=="/undo" goto :undo
if /i "%~1"=="/strict" goto :strict
if not "%~1"=="" goto :usage
set "STRICT=0"
goto :apply

:strict
set "STRICT=1"
goto :apply

:apply
tasklist /fi "imagename eq msedge.exe" 2>nul | find /i "msedge.exe" >nul
if not errorlevel 1 (
    echo [ERRO] Feche todas as janelas e processos do Microsoft Edge antes de continuar.
    exit /b 1
)

echo Este script aplica politicas documentadas para reduzir promocoes e recursos extras do Edge.
echo O provedor de pesquisa atual nao sera alterado.
if "%STRICT%"=="1" echo [STRICT] Login, sincronizacao, senhas e preenchimento automatico tambem serao desativados.
choice /c SN /n /m "Aplicar as politicas? [S/N]: "
if errorlevel 2 (
    echo Operacao cancelada.
    exit /b 0
)

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1
if not exist "%BACKUP_DIR%" (
    echo [ERRO] Nao foi possivel criar a pasta de backup.
    exit /b 1
)

if not exist "%BACKUP_FILE%" if not exist "%ABSENT_MARKER%" (
    reg query "%POLICY_KEY%" >nul 2>&1
    if errorlevel 1 (
        type nul > "%ABSENT_MARKER%"
    ) else (
        reg export "%POLICY_KEY%" "%BACKUP_FILE%" /y >nul
        if errorlevel 1 (
            echo [ERRO] Nao foi possivel criar o backup. Nenhuma politica foi aplicada.
            exit /b 1
        )
    )
)

call :set_policy ShowRecommendationsEnabled 0 || exit /b 1
call :set_policy SpotlightExperiencesAndRecommendationsEnabled 0 || exit /b 1
call :set_policy PromotionalTabsEnabled 0 || exit /b 1
call :set_policy EdgeShoppingAssistantEnabled 0 || exit /b 1
call :set_policy EdgeWalletCheckoutEnabled 0 || exit /b 1
call :set_policy HubsSidebarEnabled 0 || exit /b 1
call :set_policy Microsoft365CopilotChatIconEnabled 0 || exit /b 1
call :set_policy MicrosoftEdgeInsiderPromotionEnabled 0 || exit /b 1
call :set_policy PersonalizationReportingEnabled 0 || exit /b 1
call :set_policy UserFeedbackAllowed 0 || exit /b 1
call :set_policy NewTabPageContentEnabled 0 || exit /b 1
call :set_policy NewTabPageQuickLinksEnabled 0 || exit /b 1
call :set_policy NewTabPageHideDefaultTopSites 1 || exit /b 1
call :set_policy BackgroundModeEnabled 0 || exit /b 1
call :set_policy StartupBoostEnabled 0 || exit /b 1

if "%STRICT%"=="1" (
    call :set_policy BrowserSignin 0 || exit /b 1
    call :set_policy SyncDisabled 1 || exit /b 1
    call :set_policy PasswordManagerEnabled 0 || exit /b 1
    call :set_policy AutofillAddressEnabled 0 || exit /b 1
    call :set_policy AutofillCreditCardEnabled 0 || exit /b 1
)

echo.
echo [OK] Politicas aplicadas. Abra edge://policy e clique em Recarregar politicas.
echo Reinicie o Edge. O navegador exibira "Gerenciado pela sua organizacao" por usar politicas locais.
exit /b 0

:undo
tasklist /fi "imagename eq msedge.exe" 2>nul | find /i "msedge.exe" >nul
if not errorlevel 1 (
    echo [ERRO] Feche o Microsoft Edge antes de restaurar as politicas.
    exit /b 1
)
call :delete_managed_values
if exist "%BACKUP_FILE%" (
    reg import "%BACKUP_FILE%" >nul
    if errorlevel 1 (
        echo [ERRO] Falha ao importar o backup "%BACKUP_FILE%".
        exit /b 1
    )
)
if exist "%ABSENT_MARKER%" (
    reg delete "%POLICY_KEY%" /f >nul 2>&1
)
echo [OK] Politicas deste script removidas e configuracao anterior restaurada quando disponivel.
echo Reinicie o Edge.
exit /b 0

:set_policy
reg add "%POLICY_KEY%" /v "%~1" /t REG_DWORD /d %~2 /f >nul
if errorlevel 1 (
    echo [ERRO] Falha ao configurar %~1.
    exit /b 1
)
echo [OK] %~1 = %~2
exit /b 0

:delete_managed_values
for %%V in (ShowRecommendationsEnabled SpotlightExperiencesAndRecommendationsEnabled PromotionalTabsEnabled EdgeShoppingAssistantEnabled EdgeWalletCheckoutEnabled HubsSidebarEnabled Microsoft365CopilotChatIconEnabled MicrosoftEdgeInsiderPromotionEnabled PersonalizationReportingEnabled UserFeedbackAllowed NewTabPageContentEnabled NewTabPageQuickLinksEnabled NewTabPageHideDefaultTopSites BackgroundModeEnabled StartupBoostEnabled BrowserSignin SyncDisabled PasswordManagerEnabled AutofillAddressEnabled AutofillCreditCardEnabled) do reg delete "%POLICY_KEY%" /v "%%V" /f >nul 2>&1
exit /b 0

:usage
echo Uso: %~nx0 [/strict ^| /undo]
echo.
echo   sem opcao Modo limpo, preservando login, sincronizacao e senhas.
echo   /strict   Tambem desativa recursos de conta e preenchimento automatico.
echo   /undo     Remove as politicas do script e restaura o backup anterior.
exit /b 2
