[CmdletBinding()]
param(
    [switch]$UseInsiders,
    [switch]$InstallAndroidTooling,
    [switch]$SkipWingetPackages,
    [switch]$SkipNpmGlobals,
    [switch]$SkipPythonPackages
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-CommandPath {
    param([Parameter(Mandatory = $true)][string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id
    )

    $arguments = @(
        "install", "--id", $Id, "--exact",
        "--accept-source-agreements", "--accept-package-agreements",
        "--silent", "--disable-interactivity"
    )

    Write-Host "Installing: $Id"
    try {
        & winget @arguments | Out-Host
    }
    catch {
        Write-Warning "Nie udało się zainstalować pakietu $Id. Kontynuuję. Szczegóły: $($_.Exception.Message)"
    }
}

function Install-NpmGlobal {
    param([Parameter(Mandatory = $true)][string[]]$Packages)

    if (-not (Ensure-CommandPath -Command "npm")) {
        Write-Warning "npm nie jest dostępny, pomijam globalne paczki npm."
        return
    }

    Write-Step "Instalacja globalnych narzędzi npm"
    foreach ($package in $Packages) {
        try {
            Write-Host "npm i -g $package"
            npm install --global $package | Out-Host
        }
        catch {
            Write-Warning "Nie udało się zainstalować npm package '$package'. Kontynuuję."
        }
    }
}

function Install-PythonPackage {
    param([Parameter(Mandatory = $true)][string[]]$Packages)

    if (-not (Ensure-CommandPath -Command "python")) {
        Write-Warning "Python nie jest dostępny, pomijam paczki Python."
        return
    }

    Write-Step "Instalacja pakietów Python"
    foreach ($package in $Packages) {
        try {
            Write-Host "python -m pip install --upgrade $package"
            python -m pip install --upgrade $package | Out-Host
        }
        catch {
            Write-Warning "Nie udało się zainstalować python package '$package'. Kontynuuję."
        }
    }
}

if (-not (Test-IsAdministrator)) {
    throw "Uruchom ten skrypt jako Administrator (Windows PowerShell / PowerShell 7)."
}

if (-not (Ensure-CommandPath -Command "winget")) {
    throw "Nie znaleziono winget. Zaktualizuj App Installer ze sklepu Microsoft Store i uruchom ponownie."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$configureScriptPath = Join-Path $PSScriptRoot "Configure-VSCode.ps1"

$baseWingetPackages = @(
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.WindowsTerminal",
    "7zip.7zip",
    "Microsoft.VisualStudioCode",
    "OpenJS.NodeJS.LTS",
    "Python.Python.3.12",
    "Microsoft.DotNet.SDK.8",
    "GoLang.Go",
    "Rustlang.Rustup",
    "Docker.DockerDesktop",
    "Postman.Postman",
    "GitHub.cli",
    "GitHub.GitHubDesktop",
    "JanDeDobbeleer.OhMyPosh"
)

$androidWingetPackages = @(
    "Google.AndroidStudio"
)

if ($UseInsiders) {
    $baseWingetPackages += "Microsoft.VisualStudioCode.Insiders"
}

if (-not $SkipWingetPackages) {
    Write-Step "Instalacja pakietów przez winget"
    foreach ($package in $baseWingetPackages) {
        Install-WingetPackage -Id $package
    }

    if ($InstallAndroidTooling) {
        Write-Step "Instalacja narzędzi Android"
        foreach ($package in $androidWingetPackages) {
            Install-WingetPackage -Id $package
        }
    }
}

if (-not $SkipNpmGlobals) {
    $npmPackages = @(
        "pnpm",
        "yarn",
        "npm-check-updates",
        "typescript",
        "ts-node",
        "vite",
        "eslint",
        "prettier",
        "@angular/cli",
        "create-next-app",
        "create-vite",
        "firebase-tools",
        "netlify-cli",
        "vercel",
        "@ionic/cli",
        "native-run",
        "http-server",
        "serve"
    )
    Install-NpmGlobal -Packages $npmPackages
}

if (-not $SkipPythonPackages) {
    $pythonPackages = @(
        "pip",
        "setuptools",
        "wheel",
        "black",
        "ruff",
        "mypy",
        "pytest",
        "ipython",
        "poetry",
        "uv",
        "fastapi",
        "streamlit"
    )
    Install-PythonPackage -Packages $pythonPackages
}

Write-Step "Konfiguracja VS Code / VS Code Insiders"
& $configureScriptPath -UseInsiders:$UseInsiders -RepoRoot $repoRoot

Write-Host "`nGotowe. Uruchom teraz:" -ForegroundColor Green
if ($UseInsiders) {
    Write-Host "  .\scripts\Verify-Setup.ps1 -UseInsiders"
}
else {
    Write-Host "  .\scripts\Verify-Setup.ps1"
}
