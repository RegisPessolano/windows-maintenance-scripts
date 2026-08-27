# WSL1 + Debian sem conflito com undervolt

Instalador PowerShell para configurar **Debian sobre WSL1** sem habilitar a infraestrutura de virtualização usada pelo WSL2.

O objetivo é manter o Windows em um estado compatível com ferramentas como **ThrottleStop**, que podem perder acesso ao controle de tensão quando o hypervisor do Windows, VBS ou componentes do Hyper-V estão ativos.

> [!CAUTION]
> Este procedimento altera recursos opcionais e o BCD do Windows. Isso pode desativar WSL2, Windows Sandbox, Hyper-V, Memory Integrity/HVCI e outros recursos dependentes do hypervisor.

## O que o instalador faz

- cria um backup do estado anterior dos recursos de virtualização e do `hypervisorlaunchtype`;
- habilita `Microsoft-Windows-Subsystem-Linux`;
- desabilita `VirtualMachinePlatform`;
- desabilita `Windows Hypervisor Platform`;
- desabilita `Hyper-V` quando presente;
- define `hypervisorlaunchtype off` no BCD;
- define WSL1 como padrão;
- baixa e instala o pacote oficial do Debian para WSL;
- inicializa o Debian;
- valida que a distro está em `VERSION 1`;
- define o Debian como distro padrão;
- configura `pt_BR.UTF-8` por padrão;
- registra continuação automática após reboot quando necessário;
- grava log em `%ProgramData%\WSL1-Debian-Setup\setup.log`.

O backup é salvo em:

```text
%ProgramData%\WSL1-Debian-Setup\backup\state.json
```

A versão 1.1 também inclui `Restore-WindowsVirtualization.ps1`, que restaura o estado salvo antes da primeira alteração.

## Requisitos

- Windows 10/11 com suporte a WSL1;
- PowerShell 5.1 ou superior;
- acesso administrativo;
- conexão com a internet;
- virtualização Intel/AMD pode permanecer habilitada no BIOS/UEFI.

> [!IMPORTANT]
> O script **não usa `wsl --install`**, porque esse fluxo moderno pode habilitar automaticamente `VirtualMachinePlatform` e preparar o sistema para WSL2.

## Uso

Abra o PowerShell na pasta do script e execute:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Install-WSL1-Debian.ps1
```

O script solicita elevação administrativa automaticamente.

Quando o Debian for inicializado pela primeira vez, será aberta uma janela para criação do usuário UNIX e senha. Essa parte permanece interativa de propósito: nenhuma credencial é armazenada pelo script.

### Reiniciar automaticamente

```powershell
.\Install-WSL1-Debian.ps1 -AutoReboot
```

### Alterar locale

```powershell
.\Install-WSL1-Debian.ps1 -Locale en_US.UTF-8
```

### Reinstalar a distro Debian

```powershell
.\Install-WSL1-Debian.ps1 -ResetExistingDebian
```

> [!CAUTION]
> `-ResetExistingDebian` executa `wsl --unregister Debian` e apaga permanentemente todos os arquivos Linux dessa distro. Esse conteúdo não faz parte do backup de virtualização.

## Proteção de dados e comportamento idempotente

O instalador preserva o primeiro `state.json` encontrado. Assim, execuções posteriores não sobrescrevem o estado original com uma máquina que já foi modificada pelo próprio script.

Se um Debian já existir e não estiver em WSL1, o instalador **não converte automaticamente** a distro. Isso evita alterar uma instalação existente sem intenção explícita.

## Estado esperado

Após a configuração e um reboot:

```text
Microsoft-Windows-Subsystem-Linux   Enabled
VirtualMachinePlatform              Disabled
Windows Hypervisor Platform         Disabled
Hyper-V                             Disabled
hypervisorlaunchtype                Off
Debian                              WSL 1
```

Valide manualmente:

```powershell
wsl -l -v
```

Resultado esperado:

```text
  NAME      STATE      VERSION
* Debian    Stopped    1
```

Valide também o hypervisor:

```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object HypervisorPresent
```

Esperado após reboot:

```text
HypervisorPresent
-----------------
False
```

## ThrottleStop

Depois do reboot final, abra o ThrottleStop e confirme em **FIVR** que o `Offset Voltage` está sendo aplicado.

O script não altera valores de undervolt, PL1, PL2, Speed Shift ou qualquer configuração específica do processador.

## Limitações do WSL1

WSL1 é adequado para tarefas como:

- Bash e utilitários Unix;
- SSH;
- Git;
- Python;
- GCC/Make;
- rsync;
- curl/wget;
- automação e administração remota.

Ele não oferece a mesma integração de kernel, systemd, Docker e WSLg do WSL2.

## Segurança

Desligar o hypervisor impede ou limita recursos que dependem dele, como:

- WSL2;
- Windows Sandbox;
- Hyper-V;
- alguns cenários do Credential Guard;
- Memory Integrity/HVCI;
- VMs baseadas no hypervisor do Windows.

O instalador não desabilita HVCI diretamente no Registro. Se Memory Integrity estiver configurada, ela ficará indisponível enquanto `hypervisorlaunchtype` permanecer `off`.

## Reversão

Para restaurar exatamente os estados que o instalador encontrou antes da primeira alteração, execute:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Restore-WindowsVirtualization.ps1
```

O restaurador lê:

```text
%ProgramData%\WSL1-Debian-Setup\backup\state.json
```

e restaura:

- `Microsoft-Windows-Subsystem-Linux`;
- `VirtualMachinePlatform`;
- `HypervisorPlatform`;
- `Microsoft-Hyper-V-All`;
- `hypervisorlaunchtype`.

Depois, reinicie o Windows.

> [!NOTE]
> A reversão não apaga o Debian. Se o recurso WSL estava desabilitado originalmente, a distro permanecerá instalada, porém ficará indisponível até o recurso ser habilitado novamente.

## Referências

- [Microsoft Learn — Manual installation steps for older versions of WSL](https://learn.microsoft.com/windows/wsl/install-manual)
- [Microsoft Learn — Basic commands for WSL](https://learn.microsoft.com/windows/wsl/basic-commands)
- [Microsoft Learn — Comparing WSL 1 and WSL 2](https://learn.microsoft.com/windows/wsl/compare-versions)
- [Debian Wiki — Installing Debian on Microsoft Windows Subsystem for Linux](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux)

## Aviso

O software é fornecido “como está”, sem garantias. Leia o código antes de executar, mantenha backup dos dados importantes e valide as alterações em um ambiente controlado sempre que possível.
