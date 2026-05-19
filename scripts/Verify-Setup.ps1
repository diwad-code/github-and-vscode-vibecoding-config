[CmdletBinding()]
param(
    [switch]$UseInsiders,
    [switch]$InstallAndroidTooling
)

$ErrorActionPreference = "Stop"
$script:Failed = $false
$script:Warnings = $false

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Write-Result {
    param(
        [string]$Label,
        [string]$Status,
        [string]$Message = ""
    )

    switch ($Status) {
        "OK" { Write-Host "[OK]   $Label $Message" -ForegroundColor Green }
        "WARN" { Write-Host "[WARN] $Label $Message" -ForegroundColor Yellow; $script:Warnings = $true }
        default { Write-Host "[ERR]  $Label $Message" -ForegroundColor Red; $script:Failed = $true }
    }
}

function Test-RequiredCommand {
    param([string]$Name)
    Write-Result -Label $Name -Status $(if (Test-Command -Name $Name) { "OK" } else { "ERR" })
}

function Test-OptionalCommand {
    param([string]$Name)
    Write-Result -Label $Name -Status $(if (Test-Command -Name $Name) { "OK" } else { "WARN" }) -Message $(if (Test-Command -Name $Name) { "" } else { "- opcjonalne, sprawdź fallback w README" })
}

function Test-OptionalCommandAny {
    param(
        [string]$Label,
        [string[]]$Names
    )

    $ok = $false
    foreach ($name in $Names) {
        if (Test-Command -Name $name) {
            $ok = $true
            break
        }
    }

    Write-Result -Label $Label -Status $(if ($ok) { "OK" } else { "WARN" }) -Message $(if ($ok) { "" } else { "- opcjonalne, sprawdź fallback w README" })
}

function Get-ConfiguredExtensions {
    param([Parameter(Mandatory = $true)][string]$ExtensionListPath)

    if (-not (Test-Path $ExtensionListPath)) {
        throw "Nie znaleziono listy rozszerzeń: $ExtensionListPath"
    }

    return Get-Content -Path $ExtensionListPath | ForEach-Object { $_.Trim() } | Where-Object {
        $_ -and -not $_.StartsWith("#")
    }
}

function Get-SkillsManifest {
    param([Parameter(Mandatory = $true)][string]$ManifestPath)

    if (-not (Test-Path $ManifestPath)) {
        throw "Nie znaleziono manifestu skilli: $ManifestPath"
    }

    return Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
}

Write-Host "Weryfikacja narzędzi bazowych:`n"
@("git", "gh", "node", "npm", "python", "dotnet") | ForEach-Object { Test-RequiredCommand -Name $_ }

Write-Host "`nWeryfikacja narzędzi web/business/game/mobile:`n"
@("pnpm", "yarn", "npx", "tsc", "vite", "eslint", "prettier", "lighthouse", "vercel", "netlify", "firebase") | ForEach-Object { Test-OptionalCommand -Name $_ }
@("docker", "go", "rustc", "cargo", "java") | ForEach-Object { Test-OptionalCommand -Name $_ }

if ($InstallAndroidTooling) {
    Write-Host "`nWeryfikacja Android tooling:`n"
    @("adb", "sdkmanager", "avdmanager", "ionic", "native-run") | ForEach-Object { Test-OptionalCommand -Name $_ }
    Test-OptionalCommandAny -Label "Capacitor CLI (cap/capacitor)" -Names @("cap", "capacitor")

    $androidHome = $env:ANDROID_HOME
    $androidSdkRoot = $env:ANDROID_SDK_ROOT
    if ($androidHome -or $androidSdkRoot) {
        Write-Result -Label "ANDROID_HOME/ANDROID_SDK_ROOT" -Status "OK"
    }
    else {
        Write-Result -Label "ANDROID_HOME/ANDROID_SDK_ROOT" -Status "WARN" -Message "- ustaw po pierwszym uruchomieniu Android Studio"
    }
}

Write-Host "`nWeryfikacja VS Code:`n"
$codeCmd = if ($UseInsiders) { "code-insiders" } else { "code" }
$extensionListPath = Join-Path $PSScriptRoot "config\vscode-extensions.txt"
$skillsManifestPath = Join-Path $PSScriptRoot "config\skills-manifest.json"
if (-not (Test-Command -Name $codeCmd) -and $UseInsiders -and (Test-Command -Name "code")) {
    Write-Result -Label "code-insiders" -Status "WARN" -Message "- fallback do stable VS Code dostępny jako code"
    $codeCmd = "code"
}
else {
    Test-RequiredCommand -Name $codeCmd
}

try {
    if (Test-Command -Name $codeCmd) {
        $expectedExtensions = Get-ConfiguredExtensions -ExtensionListPath $extensionListPath
        $installedExtensions = & $codeCmd --list-extensions
        foreach ($ext in $expectedExtensions) {
            $ok = $installedExtensions -contains $ext
            Write-Result -Label $ext -Status $(if ($ok) { "OK" } else { "WARN" }) -Message $(if ($ok) { "" } else { "- brak rozszerzenia, uruchom Configure-VSCode.ps1" })
        }
    }
}
catch {
    Write-Result -Label "VS Code extensions" -Status "ERR" -Message $_.Exception.Message
}

Write-Host "`nWeryfikacja lokalnych skilli:`n"
try {
    $skillsManifest = Get-SkillsManifest -ManifestPath $skillsManifestPath
    $installRootName = if ($skillsManifest.installRootName) { [string]$skillsManifest.installRootName } else { ".vibe-coding\skills" }
    $skillsPath = Join-Path $HOME $installRootName

    foreach ($item in $skillsManifest.items) {
        $skillFileName = "$([string]$item.name).md"
        $path = Join-Path $skillsPath $skillFileName
        Write-Result -Label $skillFileName -Status $(if (Test-Path $path) { "OK" } else { "WARN" }) -Message $(if (Test-Path $path) { "" } else { "- uruchom Configure-VSCode.ps1" })
    }
}
catch {
    Write-Result -Label "skills manifest" -Status "ERR" -Message $_.Exception.Message
}

if ($script:Failed) {
    throw "Weryfikacja zakończona błędami. Sprawdź logi powyżej. Ostrzeżenia można naprawiać fallbackami z README."
}

if ($script:Warnings) {
    Write-Host "`nŚrodowisko działa częściowo. Uzupełnij ostrzeżenia lub użyj fallbacków z README." -ForegroundColor Yellow
}
else {
    Write-Host "`nŚrodowisko wygląda poprawnie. Możesz zaczynać vibe-coding." -ForegroundColor Green
}
