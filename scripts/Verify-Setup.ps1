[CmdletBinding()]
param(
    [switch]$UseInsiders
)

$ErrorActionPreference = "Stop"

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Write-Result {
    param(
        [string]$Label,
        [bool]$Passed
    )

    if ($Passed) {
        Write-Host "[OK]  $Label" -ForegroundColor Green
    }
    else {
        Write-Host "[ERR] $Label" -ForegroundColor Red
    }
}

$requiredCommands = @("git", "node", "npm", "python", "dotnet")
if ($UseInsiders) {
    $requiredCommands += "code-insiders"
}
else {
    $requiredCommands += "code"
}

$failed = $false

Write-Host "Weryfikacja narzędzi bazowych:`n"
foreach ($cmd in $requiredCommands) {
    $ok = Test-Command -Name $cmd
    Write-Result -Label $cmd -Passed $ok
    if (-not $ok) { $failed = $true }
}

Write-Host "`nWeryfikacja rozszerzeń Copilot:`n"
$codeCmd = if ($UseInsiders) { "code-insiders" } else { "code" }
$expectedExtensions = @("GitHub.copilot", "GitHub.copilot-chat")

try {
    $installedExtensions = & $codeCmd --list-extensions
    foreach ($ext in $expectedExtensions) {
        $ok = $installedExtensions -contains $ext
        Write-Result -Label $ext -Passed $ok
        if (-not $ok) { $failed = $true }
    }
}
catch {
    Write-Warning "Nie udało się pobrać listy rozszerzeń: $($_.Exception.Message)"
    $failed = $true
}

if ($failed) {
    throw "Weryfikacja zakończona błędami. Sprawdź logi powyżej."
}

Write-Host "`nŚrodowisko wygląda poprawnie. Możesz zaczynać vibe-coding." -ForegroundColor Green
