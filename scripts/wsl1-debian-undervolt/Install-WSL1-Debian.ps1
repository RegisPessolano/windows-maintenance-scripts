#requires -version 5.1

[CmdletBinding()]
param(
    [switch]$Resume,
    [switch]$AutoReboot,
    [switch]$ResetExistingDebian,
    [ValidatePattern('^[A-Za-z]{2}_[A-Za-z]{2}\.UTF-8$')]
    [string]$Locale = 'pt_BR.UTF-8'
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '1.1.0'
$script:RestartRequired = $false
$DebianDownloadUri = 'https://aka.ms/wsl-debian-gnulinux'
$WorkDir = Join-Path $env:ProgramData 'WSL1-Debian-Setup'
$BackupDir = Join-Path $WorkDir 'backup'
$StateFile = Join-Path $BackupDir 'state.json'
$BcdBackupFile = Join-Path $BackupDir 'bcd-current.txt'
$LogFile = Join-Path $WorkDir 'setup.log'
$RunOncePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
$RunOnceName = 'WSL1DebianSetup'

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Elevated {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Resume) { $arguments += ' -Resume' }
    if ($AutoReboot) { $arguments += ' -AutoReboot' }
    if ($ResetExistingDebian) { $arguments += ' -ResetExistingDebian' }
    if ($Locale) { $arguments += " -Locale `"$Locale`"" }
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments
    exit
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Get-FeatureStateSafe {
    param([Parameter(Mandatory)][string]$Name)
    try {
        return (Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction Stop).State
    }
    catch {
        return $null
    }
}

function Get-BcdHypervisorLaunchType {
    $output = & bcdedit.exe /enum '{current}' 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Não foi possível ler a entrada BCD atual.'
    }

    $line = $output | Where-Object { $_ -match '^hypervisorlaunchtype\s+' } | Select-Object -First 1
    if ($line -match '^hypervisorlaunchtype\s+(\S+)') {
        return $Matches[1]
    }

    return 'NotSet'
}

function Save-PreChangeState {
    if (Test-Path -LiteralPath $StateFile) {
        Write-Host "Backup anterior preservado: $StateFile"
        return
    }

    Write-Step 'Salvando o estado atual antes das alterações'
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

    $featureNames = @(
        'Microsoft-Windows-Subsystem-Linux',
        'VirtualMachinePlatform',
        'HypervisorPlatform',
        'Microsoft-Hyper-V-All'
    )

    $featureStates = [ordered]@{}
    foreach ($feature in $featureNames) {
        $state = Get-FeatureStateSafe -Name $feature
        $featureStates[$feature] = if ($null -eq $state) { 'Unavailable' } else { $state.ToString() }
    }

    $backup = [ordered]@{
        SchemaVersion = 1
        ScriptVersion = $ScriptVersion
        Timestamp = (Get-Date).ToString('o')
        ComputerName = $env:COMPUTERNAME
        WindowsVersion = [Environment]::OSVersion.Version.ToString()
        FeatureStates = $featureStates
        BcdHypervisorLaunchType = Get-BcdHypervisorLaunchType
    }

    $backup | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $StateFile -Encoding UTF8
    & bcdedit.exe /enum '{current}' | Out-File -LiteralPath $BcdBackupFile -Encoding utf8

    if (-not (Test-Path -LiteralPath $StateFile)) {
        throw 'Falha ao criar o backup do estado atual. Nenhuma alteração será aplicada.'
    }

    Write-Host "Backup salvo em: $BackupDir" -ForegroundColor Green
}

function Enable-FeatureIfNeeded {
    param([Parameter(Mandatory)][string]$Name)
    $state = Get-FeatureStateSafe -Name $Name
    if ($null -eq $state) {
        Write-Host "Recurso '$Name' não existe nesta edição do Windows; ignorando."
        return
    }
    if ($state -ne 'Enabled') {
        Write-Host "Habilitando $Name..."
        Enable-WindowsOptionalFeature -Online -FeatureName $Name -All -NoRestart | Out-Null
        $script:RestartRequired = $true
    }
    else {
        Write-Host "$Name já está habilitado."
    }
}

function Disable-FeatureIfNeeded {
    param([Parameter(Mandatory)][string]$Name)
    $state = Get-FeatureStateSafe -Name $Name
    if ($null -eq $state) {
        Write-Host "Recurso '$Name' não existe nesta edição do Windows; ignorando."
        return
    }
    if ($state -ne 'Disabled') {
        Write-Host "Desabilitando $Name..."
        Disable-WindowsOptionalFeature -Online -FeatureName $Name -NoRestart | Out-Null
        $script:RestartRequired = $true
    }
    else {
        Write-Host "$Name já está desabilitado."
    }
}

function Get-DistroNames {
    $output = & wsl.exe -l -q 2>$null
    if ($LASTEXITCODE -ne 0) { return @() }
    return @($output | ForEach-Object { (($_ -replace "`0", '')).Trim() } | Where-Object { $_ })
}

function Get-DebianPackage {
    return Get-AppxPackage | Where-Object {
        $_.Name -like '*Debian*' -or $_.PackageFamilyName -like '*Debian*'
    } | Sort-Object Version -Descending | Select-Object -First 1
}

function Install-DebianPackageIfNeeded {
    $package = Get-DebianPackage
    if ($package) {
        Write-Host "Pacote Debian já instalado: $($package.Name) $($package.Version)"
        return $package
    }

    Write-Step 'Baixando o pacote oficial do Debian para WSL'
    $bundlePath = Join-Path $WorkDir 'Debian.AppxBundle'

    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L --fail --silent --show-error -o $bundlePath $DebianDownloadUri
        if ($LASTEXITCODE -ne 0) {
            throw 'Falha ao baixar o pacote oficial do Debian com curl.exe.'
        }
    }
    else {
        $oldProgress = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri $DebianDownloadUri -OutFile $bundlePath -UseBasicParsing
        }
        finally {
            $ProgressPreference = $oldProgress
        }
    }

    Write-Step 'Instalando o pacote AppxBundle do Debian'
    Add-AppxPackage -Path $bundlePath
    Remove-Item -LiteralPath $bundlePath -Force -ErrorAction SilentlyContinue

    $package = Get-DebianPackage
    if (-not $package) {
        throw 'O pacote do Debian foi instalado, mas não pôde ser localizado.'
    }
    return $package
}

function Register-ResumeAfterLogon {
    if (-not (Test-Path $RunOncePath)) {
        New-Item -Path $RunOncePath -Force | Out-Null
    }

    $stagedScript = Join-Path $WorkDir 'Install-WSL1-Debian.ps1'
    if ($PSCommandPath -ne $stagedScript) {
        Copy-Item -LiteralPath $PSCommandPath -Destination $stagedScript -Force
    }

    $command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$stagedScript`" -Resume -Locale `"$Locale`""
    if ($ResetExistingDebian) { $command += ' -ResetExistingDebian' }

    New-ItemProperty -Path $RunOncePath -Name $RunOnceName -Value $command -PropertyType String -Force | Out-Null
    Write-Host 'Continuação registrada para o próximo logon.'
}

function Find-DebianLauncher {
    $command = Get-Command debian.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $package = Get-DebianPackage
    if (-not $package) { return $null }

    $candidate = Join-Path $package.InstallLocation 'debian.exe'
    if (Test-Path $candidate) { return $candidate }

    $exe = Get-ChildItem -LiteralPath $package.InstallLocation -Filter '*.exe' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '(?i)debian' } |
        Select-Object -First 1

    if ($exe) { return $exe.FullName }
    return $null
}

function Initialize-DebianIfNeeded {
    $distros = Get-DistroNames
    if ($distros -contains 'Debian') {
        Write-Host 'A distribuição Debian já está registrada.'
        return
    }

    $launcher = Find-DebianLauncher
    if (-not $launcher) {
        throw 'Não foi possível localizar o launcher debian.exe.'
    }

    Write-Step 'Inicializando o Debian em WSL1'
    Write-Host 'Uma janela do Debian será aberta para criar o usuário UNIX e a senha.' -ForegroundColor Yellow
    Write-Host 'Conclua a criação do usuário e digite "exit" nessa janela para o script continuar.' -ForegroundColor Yellow
    Start-Process -FilePath $launcher -Wait

    $distros = Get-DistroNames
    if ($distros -notcontains 'Debian') {
        throw 'O Debian não foi registrado. Execute o script novamente e conclua a primeira inicialização.'
    }
}

function Assert-DebianIsWSL1 {
    $lines = & wsl.exe -l -v 2>&1 | ForEach-Object { ($_ -replace "`0", '') }
    $debianLine = $lines | Where-Object { $_ -match '(?i)\bDebian\b' } | Select-Object -First 1

    if (-not $debianLine) {
        throw 'Não foi possível localizar o Debian na saída de "wsl -l -v".'
    }

    if ($debianLine -notmatch '\s1\s*$') {
        throw "O Debian não foi registrado como WSL1. Estado detectado: $debianLine`nNenhuma conversão automática foi feita para proteger os dados de uma distro existente."
    }

    Write-Host "Confirmado: $($debianLine.Trim())" -ForegroundColor Green
}

function Configure-DebianLocale {
    if (-not $Locale) { return }

    Write-Step "Configurando locale do Debian para $Locale"
    $linuxCommand = "export DEBIAN_FRONTEND=noninteractive; apt-get update; apt-get install -y locales; sed -i 's/^# *$Locale UTF-8/$Locale UTF-8/' /etc/locale.gen; grep -q '^$Locale UTF-8' /etc/locale.gen || echo '$Locale UTF-8' >> /etc/locale.gen; locale-gen $Locale; update-locale LANG=$Locale"

    & wsl.exe -d Debian -u root -- bash -lc $linuxCommand
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao configurar o locale dentro do Debian.'
    }
}

function Show-FinalValidation {
    Write-Step 'Validação final'

    $wslState = Get-FeatureStateSafe -Name 'Microsoft-Windows-Subsystem-Linux'
    $vmpState = Get-FeatureStateSafe -Name 'VirtualMachinePlatform'
    $whpState = Get-FeatureStateSafe -Name 'HypervisorPlatform'
    $hyperVState = Get-FeatureStateSafe -Name 'Microsoft-Hyper-V-All'
    $computerSystem = Get-CimInstance Win32_ComputerSystem
    $hypervisorPresent = [bool]$computerSystem.HypervisorPresent

    Write-Host "WSL optional feature:           $wslState"
    Write-Host "VirtualMachinePlatform:         $vmpState"
    Write-Host "Windows Hypervisor Platform:    $whpState"
    Write-Host "Hyper-V:                        $hyperVState"
    Write-Host "Hypervisor ativo neste boot:    $hypervisorPresent"
    Write-Host ''
    & wsl.exe -l -v

    if ($hypervisorPresent) {
        Write-Warning 'O hypervisor ainda está ativo neste boot. Reinicie antes de validar o undervolt.'
    }
    else {
        Write-Host 'Hypervisor não detectado. Ambiente adequado para WSL1 + ThrottleStop.' -ForegroundColor Green
    }

    $hvciPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
    $hvci = (Get-ItemProperty -Path $hvciPath -Name Enabled -ErrorAction SilentlyContinue).Enabled
    if ($hvci -eq 1) {
        Write-Warning 'Memory Integrity/HVCI está configurada no Windows. Com hypervisorlaunchtype=off ela não deve iniciar, mas essa proteção ficará indisponível enquanto o hypervisor permanecer desligado.'
    }
}

if (-not (Test-Administrator)) {
    Restart-Elevated
}

New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
try { Start-Transcript -Path $LogFile -Append | Out-Null } catch { }

try {
    Write-Host "WSL1 + Debian / undervolt compatibility setup v$ScriptVersion" -ForegroundColor Cyan
    Save-PreChangeState

    Write-Step 'Preparando Windows para WSL1 sem Virtual Machine Platform'

    if ($ResetExistingDebian) {
        $distros = Get-DistroNames
        if ($distros -contains 'Debian') {
            Write-Warning 'ResetExistingDebian apagará todos os arquivos da distro Debian existente.'
            & wsl.exe --terminate Debian 2>$null
            & wsl.exe --unregister Debian
            if ($LASTEXITCODE -ne 0) {
                throw 'Falha ao remover a distro Debian existente.'
            }
        }
    }

    Disable-FeatureIfNeeded -Name 'VirtualMachinePlatform'
    Disable-FeatureIfNeeded -Name 'HypervisorPlatform'
    Disable-FeatureIfNeeded -Name 'Microsoft-Hyper-V-All'
    Enable-FeatureIfNeeded -Name 'Microsoft-Windows-Subsystem-Linux'

    Write-Step 'Desabilitando o carregamento do hypervisor'
    & bcdedit.exe /set '{current}' hypervisorlaunchtype off | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw 'BCDEdit não conseguiu definir hypervisorlaunchtype=off.'
    }

    if ((Get-CimInstance Win32_ComputerSystem).HypervisorPresent) {
        $script:RestartRequired = $true
    }

    Install-DebianPackageIfNeeded | Out-Null

    if ($script:RestartRequired) {
        Register-ResumeAfterLogon

        if ($AutoReboot) {
            Write-Step 'Reiniciando o Windows para aplicar as alterações'
            Restart-Computer -Force
            return
        }

        Write-Host ''
        Write-Host 'É necessário reiniciar o Windows.' -ForegroundColor Yellow
        Write-Host 'O instalador continuará automaticamente no próximo logon.' -ForegroundColor Yellow
        Write-Host "Backup para reversão: $StateFile"
        return
    }

    Write-Step 'Definindo WSL1 como padrão'
    & wsl.exe --set-default-version 1
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao definir WSL1 como versão padrão.'
    }

    Initialize-DebianIfNeeded
    Assert-DebianIsWSL1

    & wsl.exe --set-default Debian
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao definir Debian como distribuição padrão.'
    }

    Configure-DebianLocale
    Show-FinalValidation

    Remove-ItemProperty -Path $RunOncePath -Name $RunOnceName -ErrorAction SilentlyContinue

    Write-Host ''
    Write-Host 'Configuração concluída.' -ForegroundColor Green
    Write-Host "Log: $LogFile"
    Write-Host "Backup para reversão: $StateFile"
    Write-Host 'Para restaurar o estado anterior, use Restore-WindowsVirtualization.ps1.'
    Write-Host 'Abra o ThrottleStop e valide o Offset Voltage/FIVR.'
}
catch {
    Write-Error $_
    Write-Host "Log: $LogFile"
    if (Test-Path -LiteralPath $StateFile) {
        Write-Host "Backup disponível em: $StateFile"
    }
    exit 1
}
finally {
    try { Stop-Transcript | Out-Null } catch { }
}
