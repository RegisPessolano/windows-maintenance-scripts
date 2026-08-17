# Segurança

## Uso seguro

Os scripts deste repositório modificam recursos sensíveis do Windows. Antes da execução:

- mantenha um backup verificável;
- crie um ponto de restauração quando possível;
- confirme que possui a chave de recuperação do BitLocker;
- teste primeiro fora do ambiente de produção;
- revise políticas corporativas de Microsoft Entra ID, Intune e domínio.

O script `Clear-FingerPrint.bat` remove o contêiner do Windows Hello do usuário atual. O script `Mitigar-BugDesligamento.bat` reduz proteções como VBS e HVCI. Revise o impacto e a documentação individual antes da execução.

## Relato de vulnerabilidades

Não publique credenciais, chaves de recuperação, identificadores de tenant ou outros dados sensíveis em uma issue pública. Use o recurso de relato privado de vulnerabilidade do GitHub, caso esteja habilitado no repositório.
