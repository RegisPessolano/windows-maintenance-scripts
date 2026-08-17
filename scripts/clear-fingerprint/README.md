# Redefinir o Windows Hello do usuário atual

O script `Clear-FingerPrint.bat` exclui o contêiner do Windows Hello do usuário atual por meio do `certutil`. PIN, reconhecimento facial e impressões digitais deverão ser configurados novamente.

## Correções de segurança

A versão original também apagava uma pasta NGC diretamente, executava `dsregcmd /leave` e tentava executar `Clear-Tpm` como comando em lote. Essas ações foram removidas porque não são necessárias para redefinir o Windows Hello e podem desconectar o equipamento do Microsoft Entra ID, afetar o BitLocker ou falhar por incompatibilidade entre Batch e PowerShell.

O script corrigido:

- verifica privilégios administrativos e a presença do `certutil`;
- explica o impacto e exige confirmação;
- atua somente no contêiner do Windows Hello do usuário atual;
- verifica o código de saída;
- não limpa o TPM nem altera a associação corporativa do dispositivo.

## Execução

Abra o Prompt de Comando como administrador, usando a conta cujo Windows Hello deve ser redefinido, e execute:

```bat
Clear-FingerPrint.bat
```

Depois, saia da sessão ou reinicie o computador e configure novamente o Windows Hello em **Configurações > Contas > Opções de entrada**.

## Reversão

A exclusão do contêiner não possui reversão automática. As credenciais do Windows Hello devem ser provisionadas novamente.
