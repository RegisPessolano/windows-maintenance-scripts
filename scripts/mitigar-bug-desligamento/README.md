# Mitigação de problema de desligamento no Windows

O script `Mitigar-BugDesligamento.bat` aplica uma mitigação agressiva que desabilita VBS, HVCI, Inicialização Rápida e hibernação.

> [!CAUTION]
> VBS e HVCI são mecanismos de proteção do Windows. Desabilitá-los reduz a postura de segurança. Use somente depois de diagnosticar que um desses recursos participa do problema.

## Correções realizadas

A versão original considerava as builds 22621, 22631 e 26100 automaticamente “afetadas”. Esses números identificam versões do Windows 11, mas não comprovam a presença de um bug. A versão corrigida apenas informa o sistema e a build, explica o impacto e exige confirmação explícita.

Antes de alterar o sistema, o script exporta as configurações atuais para a pasta `backup` ao lado do arquivo `.bat`. Se o backup falhar, nenhuma alteração é aplicada.

## Alterações realizadas

- `EnableVirtualizationBasedSecurity = 0`;
- `RequirePlatformSecurityFeatures = 0`;
- `HypervisorEnforcedCodeIntegrity\Enabled = 0`;
- `HiberbootEnabled = 0`;
- `powercfg /hibernate off`.

## Execução

Abra o Prompt de Comando como administrador e execute:

```bat
Mitigar-BugDesligamento.bat
```

Reinicie o computador após a conclusão.

## Reversão

Importe `backup\DeviceGuard.reg` e `backup\Power.reg`, reabilite a hibernação e reinicie:

```bat
reg import "backup\DeviceGuard.reg"
reg import "backup\Power.reg"
powercfg /hibernate on
```

Políticas de domínio ou MDM podem reaplicar valores diferentes.

Referência de builds: [Informações de versão do Windows 11 — Microsoft Learn](https://learn.microsoft.com/windows/release-health/windows11-release-information).
