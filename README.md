# Windows Maintenance Scripts

Coleção de scripts administrativos para diagnóstico e manutenção do Windows.

> [!WARNING]
> Estes scripts alteram configurações de segurança, identidade, Registro, energia e recursos opcionais do Windows. Leia a documentação de cada script, faça backup e teste em um ambiente controlado antes de usar em produção.

## Scripts

| Script | Finalidade | Impacto |
| --- | --- | --- |
| [`Desabilitar_Windows_Hello.bat`](scripts/desabilitar-windows-hello/) | Desabilita novos provisionamentos do Windows Hello for Business por política local. | Alto |
| [`Clear-FingerPrint.bat`](scripts/clear-fingerprint/) | Redefine o contêiner do Windows Hello somente para o usuário atual. | Alto |
| [`Mitigar-BugDesligamento.bat`](scripts/mitigar-bug-desligamento/) | Com confirmação e backup, desabilita VBS, HVCI, Inicialização Rápida e hibernação. | Crítico |
| [`Limpar-Cache.bat`](scripts/limpar-cache/) | Limpa caches conhecidos sem apagar perfis, cookies, senhas ou configurações. | Moderado |
| [`Edge-Clean.bat`](scripts/edge-clean/) | Remove recomendações do Bing e recursos extras do Edge usando políticas oficiais. | Alto |
| [`Install-WSL1-Debian.ps1`](scripts/wsl1-debian-undervolt/) | Configura Debian em WSL1 com Hyper-V/VMP desabilitados para evitar conflito com undervolt via ThrottleStop, incluindo backup e reversão do estado anterior. | Crítico |

## Requisitos gerais

- Windows 10/11, conforme indicado na documentação de cada script;
- terminal adequado ao formato do script, executado como administrador quando exigido;
- backup e, quando aplicável, chave de recuperação do BitLocker disponível;
- validação prévia em um equipamento de teste.

## Uso

1. Abra a pasta do script desejado e leia o respectivo `README.md`.
2. Revise o conteúdo do arquivo (`.bat` ou `.ps1`) antes de executá-lo.
3. Abra o Prompt de Comando ou PowerShell apropriado como administrador quando indicado.
4. Execute o script e reinicie o computador quando a documentação solicitar.

## Aviso de responsabilidade

O software é fornecido “como está”, sem garantias. O uso é de responsabilidade exclusiva de quem o executa. Consulte também [`SECURITY.md`](SECURITY.md).

## Contribuição

Issues e pull requests são bem-vindos. Ao relatar um problema, informe a edição e a build do Windows, o contexto de gerenciamento do dispositivo e a saída do script, removendo dados sensíveis.

## Licença

Distribuído sob a licença MIT. Consulte [`LICENSE`](LICENSE).
