[CmdletBinding()]
param(
    [switch]$UseInsiders,
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Resolve-CodeCommand {
    param([switch]$UseInsiders)

    if ($UseInsiders) {
        $insidersCommand = Get-Command "code-insiders" -ErrorAction SilentlyContinue
        if ($insidersCommand) { return $insidersCommand.Source }

        $fallback = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd"
        if (Test-Path $fallback) { return $fallback }
    }
    else {
        $codeCommand = Get-Command "code" -ErrorAction SilentlyContinue
        if ($codeCommand) { return $codeCommand.Source }

        $fallback = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
        if (Test-Path $fallback) { return $fallback }
    }

    return $null
}

function Install-Extensions {
    param(
        [Parameter(Mandatory = $true)][string]$CodeCommand,
        [Parameter(Mandatory = $true)][string]$ExtensionListPath
    )

    if (-not (Test-Path $ExtensionListPath)) {
        throw "Nie znaleziono listy rozszerzeń: $ExtensionListPath"
    }

    $extensions = Get-Content -Path $ExtensionListPath |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith("#") }

    foreach ($extension in $extensions) {
        try {
            Write-Host "Installing extension: $extension"
            & $CodeCommand --install-extension $extension --force | Out-Host
        }
        catch {
            Write-Warning "Nie udało się zainstalować rozszerzenia '$extension'. Kontynuuję."
        }
    }
}

function Merge-VSCodeSettings {
    param(
        [Parameter(Mandatory = $true)][string]$SettingsPath,
        [Parameter(Mandatory = $true)][string]$TemplatePath
    )

    if (-not (Test-Path $TemplatePath)) {
        throw "Nie znaleziono pliku ustawień: $TemplatePath"
    }

    $settingsDir = Split-Path -Parent $SettingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
    }

    $templateSettings = Get-Content -Path $TemplatePath -Raw | ConvertFrom-Json -AsHashtable
    $currentSettings = @{}

    if (Test-Path $SettingsPath) {
        try {
            $currentSettings = Get-Content -Path $SettingsPath -Raw | ConvertFrom-Json -AsHashtable
        }
        catch {
            Write-Warning "Istniejący settings.json ma niepoprawny JSON. Zastępuję szablonem."
            $currentSettings = @{}
        }
    }

    foreach ($key in $templateSettings.Keys) {
        $currentSettings[$key] = $templateSettings[$key]
    }

    $json = $currentSettings | ConvertTo-Json -Depth 20
    Set-Content -Path $SettingsPath -Value $json -Encoding utf8
}

$codeCommand = Resolve-CodeCommand -UseInsiders:$UseInsiders
if (-not $codeCommand) {
    throw "Nie znaleziono polecenia code/code-insiders. Zainstaluj VS Code i upewnij się, że CLI jest dostępne."
}

$extensionListPath = Join-Path $RepoRoot "scripts\config\vscode-extensions.txt"
$settingsTemplatePath = Join-Path $RepoRoot "scripts\config\vscode-settings.json"

if ($UseInsiders) {
    $settingsPath = Join-Path $env:APPDATA "Code - Insiders\User\settings.json"
}
else {
    $settingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
}

Write-Step "Instalacja rozszerzeń"
Install-Extensions -CodeCommand $codeCommand -ExtensionListPath $extensionListPath

Write-Step "Konfiguracja settings.json"
Merge-VSCodeSettings -SettingsPath $settingsPath -TemplatePath $settingsTemplatePath

Write-Host "Konfiguracja zakończona pomyślnie." -ForegroundColor Green
