# Limpar caches do Windows e navegadores

`Limpar-Cache.bat` substitui e funde os scripts antigos `Limpar Cache.bat` e `Limpar Cache II.BAT`.

## O que foi corrigido

Os originais percorriam indiscriminadamente todos os perfis, removiam pastas inteiras do Firefox, confundiam cache com cookies e continham caminhos incorretos para Brave, Opera e `%SystemDrive%\Temp`. A versão unificada:

- limpa somente o conteúdo de diretórios de cache conhecidos;
- preserva perfis, favoritos, cookies, senhas, extensões e configurações;
- trata separadamente caches `Cache`, `Code Cache` e `GPUCache` de navegadores Chromium;
- oferece simulação antes da exclusão;
- usa o perfil atual por padrão;
- exige administrador para limpar todos os perfis e o Temp do Windows;
- preserva automaticamente arquivos que estiverem em uso.

## Uso

Simular a limpeza do usuário atual:

```bat
Limpar-Cache.bat /dry-run
```

Limpar o usuário atual:

```bat
Limpar-Cache.bat
```

Simular ou limpar todos os perfis locais, executando como administrador:

```bat
Limpar-Cache.bat /dry-run /all-users
Limpar-Cache.bat /all-users
```

Feche os navegadores antes da execução. O script não encerra processos automaticamente.

## Dados preservados

O script não foi projetado para apagar cookies, histórico, downloads, sessões, senhas ou dados sincronizados. Para remover esses dados, use os controles de privacidade do próprio navegador.
