# WSL1 + Debian sem conflito com undervolt

Instalador PowerShell para configurar **Debian sobre WSL1** sem habilitar a infraestrutura de virtualização usada pelo WSL2.

O objetivo é manter o Windows em um estado compatível com ferramentas como **ThrottleStop**, que podem perder acesso ao controle de tensão quando o hypervisor do Windows, VBS ou componentes do Hyper-V estão ativos.

## O que o script faz

- habilita somente `Microsoft-Windows-Subsystem-Linux`;
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

## Requisitos

- Windows 10/11 com suporte a WSL1;
- PowerShell 5.1 ou superior;
- acesso administrativo;
- conexão com a internet;
- virtualização Intel/AMD pode permanecer habilitada no BIOS/UEFI.

> [!IMPORTANT]
> O script **não usa `wsl --install`**, porque esse fluxo moderno pode habilitar automaticamente `VirtualMachinePlatform` e preparar o sistema para WSL2.

## Uso

Abra o PowerShell e execute:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Install-WSL1-Debian.ps1
```

O script solicitará elevação administrativa automaticamente.

Quando o Debian for inicializado pela primeira vez, será aberta uma janela para criação do usuário UNIX e senha. Essa parte permanece interativa de propósito: o script não armazena credenciais.

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
> `-ResetExistingDebian` executa `wsl --unregister Debian` e apaga permanentemente todos os arquivos Linux dessa distro.

## Estado esperado

Após a configuração:

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

Também pode ser útil:

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

WSL1 é adequado para:

- bash;
- SSH;
- Git;
- Python;
- GCC/Make;
- rsync;
- curl/wget;
- automação e ferramentas Unix.

Ele não oferece a mesma integração de kernel, systemd, Docker e WSLg do WSL2.

## Segurança

Desligar Hyper-V/hypervisor impede o funcionamento de recursos que dependem dele, como:

- WSL2;
- Windows Sandbox;
- alguns cenários do Credential Guard;
- Memory Integrity/HVCI;
- VMs Hyper-V.

Se esses recursos forem necessários, este perfil de sistema não é adequado.

## Reversão

Para voltar a permitir o hypervisor:

```powershell
bcdedit /set {current} hypervisorlaunchtype auto
```

E, se necessário:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All
```

Reinicie o Windows.

## Referências

- Microsoft Learn — Install WSL manually
- Microsoft Learn — Basic commands for WSL
- Microsoft Learn — Comparing WSL 1 and WSL 2
- Debian Wiki — Installing Debian on WSL

## Aviso

Este script altera componentes opcionais e configuração de boot do Windows. Leia o código antes de executar e mantenha backup dos dados importantes.
