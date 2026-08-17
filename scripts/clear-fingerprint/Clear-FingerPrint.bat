@echo off
setlocal

net session >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Execute este script como Administrador.
    exit /b 1
)

where certutil.exe >nul 2>&1
if errorlevel 1 (
    echo [ERRO] certutil.exe nao foi encontrado.
    exit /b 1
)

echo Este script exclui o container do Windows Hello do usuario atual.
echo PIN, reconhecimento facial e impressoes digitais precisarao ser configurados novamente.
echo O dispositivo NAO sera removido do Microsoft Entra ID e o TPM NAO sera limpo.
choice /c SN /n /m "Deseja continuar? [S/N]: "
if errorlevel 2 (
    echo Operacao cancelada.
    exit /b 0
)

certutil.exe -deleteHelloContainer
if errorlevel 1 (
    echo [ERRO] Nao foi possivel excluir o container do Windows Hello.
    exit /b 1
)

echo [OK] Container do Windows Hello excluido para o usuario atual.
echo Saia da sessao ou reinicie o computador e configure o Windows Hello novamente.
exit /b 0
