# Desabilitar Windows Hello for Business

O script define a política local de dispositivo `PassportForWork\Enabled` como `0`, impedindo novos provisionamentos do Windows Hello for Business.

## Alteração realizada

```text
HKLM\SOFTWARE\Policies\Microsoft\PassportForWork
Enabled (REG_DWORD) = 0
```

O script verifica privilégios administrativos, solicita confirmação e valida o resultado da alteração.

## Execução

Abra o Prompt de Comando como administrador e execute:

```bat
Desabilitar_Windows_Hello.bat
```

Para remover a configuração criada pelo script:

```bat
Desabilitar_Windows_Hello.bat /undo
```

O modo `/undo` remove o valor local em vez de forçar `Enabled=1`, permitindo que a configuração volte a ser determinada pelas demais políticas do ambiente.

## Observações

- Reinicie o computador após a alteração.
- Credenciais já provisionadas podem permanecer no equipamento.
- Em dispositivos gerenciados, políticas de domínio ou MDM podem substituir ou conflitar com a configuração local.

Referência: [Configurar o Windows Hello para Empresas — Microsoft Learn](https://learn.microsoft.com/pt-br/windows/security/identity-protection/hello-for-business/configure).
