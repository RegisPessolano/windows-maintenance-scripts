# Microsoft Edge limpo e sem recomendações do Bing

`Edge-Clean.bat` aplica políticas oficiais do Microsoft Edge para reduzir solicitações de retorno ao Bing, recomendações, promoções e recursos extras. Ele substitui o script original `Stop Edge to ask you change search engine to Bing.bat`.

## Proteção contra solicitações do Bing

As políticas mais diretamente relacionadas são:

- `ShowRecommendationsEnabled=0`: desativa recomendações de recursos e notificações de assistência;
- `SpotlightExperiencesAndRecommendationsEnabled=0`: desativa sugestões, notificações e dicas de serviços Microsoft;
- `PromotionalTabsEnabled=0`: bloqueia conteúdo promocional de página inteira em versões que ainda aceitam a política legada.

O script não força Google, DuckDuckGo ou qualquer outro provedor: a escolha atual do usuário é preservada. Políticas documentadas são a mitigação mais estável disponível, mas nenhuma ferramenta pode garantir o comportamento de versões futuras ainda não lançadas do Edge.

## Debloat padrão

Além das recomendações, o modo padrão desativa:

- Shopping e Wallet Checkout;
- sidebar e ícone do Microsoft 365 Copilot Chat;
- promoção do Edge Insider e feedback;
- personalização de anúncios e serviços usando dados de navegação;
- feed, links rápidos e sites sugeridos da nova guia;
- Startup Boost e execução em segundo plano.

Login no navegador, sincronização, gerenciador de senhas e preenchimento automático são preservados.

## Uso

Feche o Edge e execute o Prompt de Comando como administrador.

Modo recomendado:

```bat
Edge-Clean.bat
```

Modo estrito, que também desativa login, sincronização, senhas e preenchimento automático:

```bat
Edge-Clean.bat /strict
```

Restaurar as políticas anteriores:

```bat
Edge-Clean.bat /undo
```

O primeiro uso salva a configuração anterior na pasta local `backup`. Não apague essa pasta se quiser restaurar o estado original.

## Verificação

Abra `edge://policy`, clique em **Recarregar políticas** e confirme os valores. Reinicie o navegador para políticas que não aceitam atualização dinâmica.

O Edge mostrará **Gerenciado pela sua organização** porque políticas administrativas locais estão ativas, mesmo em um computador pessoal.

## Referências

- [Políticas do Microsoft Edge](https://learn.microsoft.com/deployedge/microsoft-edge-policies)
- [ShowRecommendationsEnabled](https://learn.microsoft.com/deployedge/microsoft-edge-browser-policies/showrecommendationsenabled)
- [SpotlightExperiencesAndRecommendationsEnabled](https://learn.microsoft.com/deployedge/microsoft-edge-browser-policies/spotlightexperiencesandrecommendationsenabled)
- [EdgeShoppingAssistantEnabled](https://learn.microsoft.com/deployedge/microsoft-edge-policies/edgeshoppingassistantenabled)
- [Gerenciar a sidebar](https://learn.microsoft.com/deployedge/microsoft-edge-sidebar)
