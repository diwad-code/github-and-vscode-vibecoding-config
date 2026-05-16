[CmdletBinding()]
param(
    [switch]$UseInsiders,
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [int]$RetryCount = 2
)

$ErrorActionPreference = "Stop"
$script:ConfigResults = New-Object System.Collections.Generic.List[object]

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Add-ConfigResult {
    param(
        [string]$Category,
        [string]$Name,
        [string]$Status,
        [string]$Message = ""
    )

    $script:ConfigResults.Add([pscustomobject]@{
        Category = $Category
        Name = $Name
        Status = $Status
        Message = $Message
    }) | Out-Null
}

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [int]$Attempts = 2,
        [int]$DelaySeconds = 3,
        [string]$Label = "operation"
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            & $Action
            return $true
        }
        catch {
            $lastError = $_.Exception.Message
            Write-Warning "$Label failed (attempt $attempt/$Attempts): $lastError"
            if ($attempt -lt $Attempts) {
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }

    throw $lastError
}

function Resolve-CodeCommand {
    param([switch]$UseInsiders)

    if ($UseInsiders) {
        $insidersCommand = Get-Command "code-insiders" -ErrorAction SilentlyContinue
        if ($insidersCommand) { return $insidersCommand.Source }

        $fallback = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd"
        if (Test-Path $fallback) { return $fallback }

        $stableCommand = Get-Command "code" -ErrorAction SilentlyContinue
        if ($stableCommand) {
            Write-Warning "Nie znaleziono code-insiders. Fallback do stabilnego VS Code."
            return $stableCommand.Source
        }
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
            Invoke-WithRetry -Attempts $RetryCount -Label "extension $extension" -Action {
                & $CodeCommand --install-extension $extension --force | Out-Host
                if ($LASTEXITCODE -ne 0) {
                    throw "VS Code CLI exit code $LASTEXITCODE"
                }
            } | Out-Null
            Add-ConfigResult -Category "extension" -Name $extension -Status "OK"
        }
        catch {
            $message = "$($_.Exception.Message). Fallback: zainstaluj ręcznie w Extensions Marketplace."
            Write-Warning "Nie udało się zainstalować rozszerzenia '$extension'. $message"
            Add-ConfigResult -Category "extension" -Name $extension -Status "WARN" -Message $message
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
            $backupPath = "$SettingsPath.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item -Path $SettingsPath -Destination $backupPath -Force
            Write-Warning "Istniejący settings.json ma niepoprawny JSON. Backup: $backupPath"
            $currentSettings = @{}
        }
    }

    foreach ($key in $templateSettings.Keys) {
        $currentSettings[$key] = $templateSettings[$key]
    }

    $json = $currentSettings | ConvertTo-Json -Depth 20
    Set-Content -Path $SettingsPath -Value $json -Encoding utf8
    Add-ConfigResult -Category "settings" -Name $SettingsPath -Status "OK"
}

function Install-Skills {
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    if (-not (Test-Path $ManifestPath)) {
        Add-ConfigResult -Category "skills" -Name "manifest" -Status "WARN" -Message "Brak manifestu skilli: $ManifestPath"
        return
    }

    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
    $installRootName = if ($manifest.installRootName) { [string]$manifest.installRootName } else { ".vibe-coding\skills" }
    $installRoot = Join-Path $HOME $installRootName
    New-Item -Path $installRoot -ItemType Directory -Force | Out-Null

    foreach ($item in $manifest.items) {
        $name = [string]$item.name
        $destination = Join-Path $installRoot "$name.md"
        try {
            if ($item.source -eq "local") {
                $sourcePath = Join-Path $RepoRoot ([string]$item.path)
                if (-not (Test-Path $sourcePath)) {
                    throw "Nie znaleziono lokalnego skilla: $sourcePath"
                }
                Copy-Item -Path $sourcePath -Destination $destination -Force
            }
            elseif ($item.source -eq "url") {
                Invoke-WithRetry -Attempts $RetryCount -Label "skill $name" -Action {
                    Invoke-WebRequest -Uri ([string]$item.url) -OutFile $destination -UseBasicParsing
                } | Out-Null
            }
            else {
                throw "Nieobsługiwane źródło skilla: $($item.source)"
            }

            Add-ConfigResult -Category "skills" -Name $name -Status "OK" -Message $destination
        }
        catch {
            $message = "$($_.Exception.Message). Fallback: skopiuj skill ręcznie do $installRoot."
            Write-Warning "Nie udało się zainstalować skilla '$name'. $message"
            Add-ConfigResult -Category "skills" -Name $name -Status "WARN" -Message $message
        }
    }
}

$codeCommand = Resolve-CodeCommand -UseInsiders:$UseInsiders
if (-not $codeCommand) {
    throw "Nie znaleziono polecenia code/code-insiders. Zainstaluj VS Code i upewnij się, że CLI jest dostępne."
}

$extensionListPath = Join-Path $RepoRoot "scripts\config\vscode-extensions.txt"
$settingsTemplatePath = Join-Path $RepoRoot "scripts\config\vscode-settings.json"
$skillsManifestPath = Join-Path $RepoRoot "scripts\config\skills-manifest.json"

if ($UseInsiders -and $codeCommand -like "*Insiders*") {
    $settingsPath = Join-Path $env:APPDATA "Code - Insiders\User\settings.json"
}
else {
    $settingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
}

Write-Step "Instalacja rozszerzeń"
Install-Extensions -CodeCommand $codeCommand -ExtensionListPath $extensionListPath

Write-Step "Konfiguracja settings.json"
Merge-VSCodeSettings -SettingsPath $settingsPath -TemplatePath $settingsTemplatePath

Write-Step "Instalacja lokalnych skilli vibe-coding"
Install-Skills -ManifestPath $skillsManifestPath -RepoRoot $RepoRoot

Write-Step "Raport konfiguracji VS Code"
$script:ConfigResults | Format-Table Category, Name, Status, Message -AutoSize

Write-Host "Konfiguracja zakończona." -ForegroundColor Green
