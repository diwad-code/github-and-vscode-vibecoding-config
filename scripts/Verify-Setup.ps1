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

Write-Host "Weryfikacja narzędzi bazowych:`n"
@("git", "gh", "node", "npm", "python", "dotnet") | ForEach-Object { Test-RequiredCommand -Name $_ }

Write-Host "`nWeryfikacja narzędzi web/business/game/mobile:`n"
@("pnpm", "yarn", "npx", "tsc", "vite", "eslint", "prettier", "lighthouse", "vercel", "netlify", "firebase") | ForEach-Object { Test-OptionalCommand -Name $_ }
@("docker", "go", "rustc", "cargo", "java") | ForEach-Object { Test-OptionalCommand -Name $_ }

if ($InstallAndroidTooling) {
    Write-Host "`nWeryfikacja Android tooling:`n"
    @("adb", "sdkmanager", "avdmanager", "ionic", "capacitor", "native-run") | ForEach-Object { Test-OptionalCommand -Name $_ }

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
if (-not (Test-Command -Name $codeCmd) -and $UseInsiders -and (Test-Command -Name "code")) {
    Write-Result -Label "code-insiders" -Status "WARN" -Message "- fallback do stable VS Code dostępny jako code"
    $codeCmd = "code"
}
else {
    Test-RequiredCommand -Name $codeCmd
}

$expectedExtensions = @(
    "GitHub.copilot",
    "GitHub.copilot-chat",
    "GitHub.vscode-pull-request-github",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-typescript-next",
    "ms-azuretools.vscode-docker",
    "ms-vscode-remote.remote-containers",
    "ms-python.python",
    "ms-vscode.powershell",
    "geequlim.godot-tools"
)

try {
    if (Test-Command -Name $codeCmd) {
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
$skillsPath = Join-Path $HOME ".vibe-coding\skills"
foreach ($skill in @("web-game-vibe-coding.md", "business-websites-vibe-coding.md")) {
    $path = Join-Path $skillsPath $skill
    Write-Result -Label $skill -Status $(if (Test-Path $path) { "OK" } else { "WARN" }) -Message $(if (Test-Path $path) { "" } else { "- uruchom Configure-VSCode.ps1" })
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
