#requires -version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$WorkDir = Join-Path $env:ProgramData 'WSL1-Debian-Setup'
$BackupDir = Join-Path $WorkDir 'backup'
$StateFile = Join-Path $BackupDir 'state.json'

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Elevated {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

function Get-FeatureStateSafe {
    param([Parameter(Mandatory)][string]$Name)
    try {
        return (Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction Stop).State.ToString()
    }
    catch {
        return 'Unavailable'
    }
}

function Set-FeatureToState {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$State
    )

    $current = Get-FeatureStateSafe -Name $Name
    if ($current -eq 'Unavailable' -or $State -eq 'Unavailable') {
        Write-Host "Ignorando $Name (indisponível nesta edição do Windows)."
        return
    }

    if ($current -eq $State) {
        Write-Host "$Name já está em $State."
        return
    }

    switch ($State) {
        'Enabled' {
            Write-Host "Restaurando $Name para Enabled..."
            Enable-WindowsOptionalFeature -Online -FeatureName $Name -All -NoRestart | Out-Null
        }
        'Disabled' {
            Write-Host "Restaurando $Name para Disabled..."
            Disable-WindowsOptionalFeature -Online -FeatureName $Name -NoRestart | Out-Null
        }
        default {
            Write-Warning "Estado '$State' de $Name não é suportado para restauração automática."
        }
    }
}

if (-not (Test-Administrator)) {
    Restart-Elevated
}

if (-not (Test-Path -LiteralPath $StateFile)) {
    throw "Backup não encontrado em '$StateFile'. Execute primeiro Install-WSL1-Debian.ps1 v1.1 ou superior."
}

$state = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json

Write-Host 'Restaurando o estado de virtualização salvo antes da instalação...' -ForegroundColor Cyan
Write-Host "Backup criado em: $($state.Timestamp)"
Write-Host ''

$features = @(
    'Microsoft-Windows-Subsystem-Linux',
    'VirtualMachinePlatform',
    'HypervisorPlatform',
    'Microsoft-Hyper-V-All'
)

foreach ($feature in $features) {
    $savedProperty = $state.FeatureStates.PSObject.Properties[$feature]
    if ($null -ne $savedProperty) {
        Set-FeatureToState -Name $feature -State ([string]$savedProperty.Value)
    }
}

$launchType = [string]$state.BcdHypervisorLaunchType
if ([string]::IsNullOrWhiteSpace($launchType) -or $launchType -eq 'NotSet') {
    Write-Host 'Restaurando hypervisorlaunchtype para o comportamento padrão do BCD...'
    & bcdedit.exe /deletevalue '{current}' hypervisorlaunchtype 2>$null | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'Não foi possível remover hypervisorlaunchtype. O valor pode já estar ausente.'
    }
}
else {
    Write-Host "Restaurando hypervisorlaunchtype para $launchType..."
    & bcdedit.exe /set '{current}' hypervisorlaunchtype $launchType | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao restaurar hypervisorlaunchtype com BCDEdit.'
    }
}

Write-Host ''
Write-Host 'Restauração aplicada. Reinicie o Windows para concluir.' -ForegroundColor Green
Write-Host 'A distro Debian não foi apagada. Se o estado original do recurso WSL era Disabled, ela ficará indisponível até o WSL ser habilitado novamente.'
