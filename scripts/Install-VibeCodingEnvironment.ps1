[CmdletBinding()]
param(
    [switch]$UseInsiders,
    [switch]$InstallAndroidTooling,
    [switch]$SkipWingetPackages,
    [switch]$SkipNpmGlobals,
    [switch]$SkipPythonPackages,
    [int]$RetryCount = 2
)

$ErrorActionPreference = "Stop"
$script:InstallResults = New-Object System.Collections.Generic.List[object]

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Add-InstallResult {
    param(
        [string]$Category,
        [string]$Name,
        [string]$Status,
        [string]$Message = ""
    )

    $script:InstallResults.Add([pscustomobject]@{
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
        [Parameter(Mandatory = $true)][string]$Id,
        [string]$Fallback = "Zainstaluj ręcznie przez winget lub oficjalny instalator producenta."
    )

    $arguments = @(
        "install", "--id", $Id, "--exact",
        "--accept-source-agreements", "--accept-package-agreements",
        "--silent", "--disable-interactivity"
    )

    Write-Host "Installing winget package: $Id"
    try {
        Invoke-WithRetry -Attempts $RetryCount -Label "winget $Id" -Action {
            & winget @arguments | Out-Host
            if ($LASTEXITCODE -ne 0) {
                throw "winget exit code $LASTEXITCODE"
            }
        } | Out-Null
        Add-InstallResult -Category "winget" -Name $Id -Status "OK"
    }
    catch {
        $message = "$($_.Exception.Message). Fallback: $Fallback"
        Write-Warning "Nie udało się zainstalować pakietu $Id. $message"
        Add-InstallResult -Category "winget" -Name $Id -Status "WARN" -Message $message
    }
}

function Enable-CorepackIfAvailable {
    if (-not (Ensure-CommandPath -Command "corepack")) {
        Add-InstallResult -Category "corepack" -Name "corepack" -Status "WARN" -Message "Corepack nie jest dostępny. pnpm/yarn zostaną zainstalowane przez npm, jeśli możliwe."
        return
    }

    try {
        Invoke-WithRetry -Attempts $RetryCount -Label "corepack enable" -Action {
            corepack enable | Out-Host
        } | Out-Null
        Add-InstallResult -Category "corepack" -Name "corepack enable" -Status "OK"
    }
    catch {
        Add-InstallResult -Category "corepack" -Name "corepack enable" -Status "WARN" -Message $_.Exception.Message
    }
}

function Install-NpmGlobal {
    param([Parameter(Mandatory = $true)][string[]]$Packages)

    if (-not (Ensure-CommandPath -Command "npm")) {
        $message = "npm nie jest dostępny. Po instalacji Node.js uruchom skrypt ponownie albo użyj: npm install --global <package>."
        Write-Warning $message
        Add-InstallResult -Category "npm" -Name "npm" -Status "WARN" -Message $message
        return
    }

    Enable-CorepackIfAvailable
    Write-Step "Instalacja globalnych narzędzi npm"
    foreach ($package in $Packages) {
        try {
            Write-Host "npm i -g $package"
            Invoke-WithRetry -Attempts $RetryCount -Label "npm $package" -Action {
                npm install --global $package | Out-Host
                if ($LASTEXITCODE -ne 0) {
                    throw "npm exit code $LASTEXITCODE"
                }
            } | Out-Null
            Add-InstallResult -Category "npm" -Name $package -Status "OK"
        }
        catch {
            $message = "$($_.Exception.Message). Fallback: użyj npx/npm create albo instalacji lokalnej w projekcie."
            Write-Warning "Nie udało się zainstalować npm package '$package'. $message"
            Add-InstallResult -Category "npm" -Name $package -Status "WARN" -Message $message
        }
    }
}

function Install-PythonPackage {
    param([Parameter(Mandatory = $true)][string[]]$Packages)

    if (-not (Ensure-CommandPath -Command "python")) {
        $message = "Python nie jest dostępny. Po instalacji Python uruchom skrypt ponownie."
        Write-Warning $message
        Add-InstallResult -Category "python" -Name "python" -Status "WARN" -Message $message
        return
    }

    Write-Step "Instalacja pakietów Python"
    foreach ($package in $Packages) {
        try {
            Write-Host "python -m pip install --upgrade $package"
            Invoke-WithRetry -Attempts $RetryCount -Label "pip $package" -Action {
                python -m pip install --upgrade $package | Out-Host
                if ($LASTEXITCODE -ne 0) {
                    throw "pip exit code $LASTEXITCODE"
                }
            } | Out-Null
            Add-InstallResult -Category "python" -Name $package -Status "OK"
        }
        catch {
            $message = "$($_.Exception.Message). Fallback: użyj py -m pip install --upgrade $package albo instalacji w venv."
            Write-Warning "Nie udało się zainstalować python package '$package'. $message"
            Add-InstallResult -Category "python" -Name $package -Status "WARN" -Message $message
        }
    }
}

function Write-InstallSummary {
    Write-Step "Raport końcowy instalacji"
    if ($script:InstallResults.Count -eq 0) {
        Write-Host "Brak kroków do raportowania."
        return
    }

    $script:InstallResults | Format-Table Category, Name, Status, Message -AutoSize
    $warnings = $script:InstallResults | Where-Object { $_.Status -ne "OK" }
    if ($warnings) {
        Write-Warning "Część elementów wymaga ręcznego fallbacku. Skrypt kontynuował, aby zainstalować możliwie dużo środowiska."
    }
}

if (-not (Test-IsAdministrator)) {
    throw "Uruchom ten skrypt jako Administrator (Windows PowerShell / PowerShell 7)."
}

if (-not $SkipWingetPackages -and -not (Ensure-CommandPath -Command "winget")) {
    throw "Nie znaleziono winget. Zaktualizuj App Installer ze sklepu Microsoft Store i uruchom ponownie."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$configureScriptPath = Join-Path $PSScriptRoot "Configure-VSCode.ps1"

$baseWingetPackages = @(
    @{ Id = "Git.Git"; Fallback = "https://git-scm.com/download/win" },
    @{ Id = "Microsoft.PowerShell"; Fallback = "https://github.com/PowerShell/PowerShell" },
    @{ Id = "Microsoft.WindowsTerminal"; Fallback = "Microsoft Store: Windows Terminal" },
    @{ Id = "7zip.7zip"; Fallback = "https://www.7-zip.org/" },
    @{ Id = "Microsoft.VisualStudioCode"; Fallback = "https://code.visualstudio.com/" },
    @{ Id = "OpenJS.NodeJS.LTS"; Fallback = "https://nodejs.org/" },
    @{ Id = "Python.Python.3.12"; Fallback = "https://www.python.org/downloads/windows/" },
    @{ Id = "Microsoft.DotNet.SDK.8"; Fallback = "https://dotnet.microsoft.com/download" },
    @{ Id = "GoLang.Go"; Fallback = "https://go.dev/dl/" },
    @{ Id = "Rustlang.Rustup"; Fallback = "https://rustup.rs/" },
    @{ Id = "Docker.DockerDesktop"; Fallback = "https://www.docker.com/products/docker-desktop/" },
    @{ Id = "Postman.Postman"; Fallback = "https://www.postman.com/downloads/" },
    @{ Id = "GitHub.cli"; Fallback = "https://cli.github.com/" },
    @{ Id = "GitHub.GitHubDesktop"; Fallback = "https://desktop.github.com/" },
    @{ Id = "JanDeDobbeleer.OhMyPosh"; Fallback = "https://ohmyposh.dev/docs/installation/windows" },
    @{ Id = "EclipseAdoptium.Temurin.21.JDK"; Fallback = "https://adoptium.net/" },
    @{ Id = "OpenJS.NodeJS"; Fallback = "Alternatywa dla Node LTS, jeśli potrzebna nowsza wersja." },
    @{ Id = "Microsoft.Edge"; Fallback = "https://www.microsoft.com/edge" },
    @{ Id = "Google.Chrome"; Fallback = "https://www.google.com/chrome/" },
    @{ Id = "Mozilla.Firefox.DeveloperEdition"; Fallback = "https://www.mozilla.org/firefox/developer/" },
    @{ Id = "WinSCP.WinSCP"; Fallback = "https://winscp.net/" }
)

$androidWingetPackages = @(
    @{ Id = "Google.AndroidStudio"; Fallback = "https://developer.android.com/studio" }
)

if ($UseInsiders) {
    $baseWingetPackages += @{ Id = "Microsoft.VisualStudioCode.Insiders"; Fallback = "https://code.visualstudio.com/insiders/" }
}

if (-not $SkipWingetPackages) {
    Write-Step "Instalacja pakietów przez winget"
    foreach ($package in $baseWingetPackages) {
        Install-WingetPackage -Id $package.Id -Fallback $package.Fallback
    }

    if ($InstallAndroidTooling) {
        Write-Step "Instalacja narzędzi Android"
        foreach ($package in $androidWingetPackages) {
            Install-WingetPackage -Id $package.Id -Fallback $package.Fallback
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
        "tsx",
        "vite",
        "eslint",
        "prettier",
        "stylelint",
        "@angular/cli",
        "create-next-app",
        "create-vite",
        "firebase-tools",
        "netlify-cli",
        "vercel",
        "wrangler",
        "lighthouse",
        "@lhci/cli",
        "@axe-core/cli",
        "@ionic/cli",
        "@capacitor/cli",
        "native-run",
        "cordova",
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
        "streamlit",
        "pre-commit"
    )
    Install-PythonPackage -Packages $pythonPackages
}

Write-Step "Konfiguracja VS Code / VS Code Insiders"
try {
    & $configureScriptPath -UseInsiders:$UseInsiders -RepoRoot $repoRoot -RetryCount $RetryCount
    Add-InstallResult -Category "vscode" -Name "Configure-VSCode" -Status "OK"
}
catch {
    Add-InstallResult -Category "vscode" -Name "Configure-VSCode" -Status "WARN" -Message $_.Exception.Message
    Write-Warning "Konfiguracja VS Code wymaga ręcznej naprawy: $($_.Exception.Message)"
}

Write-InstallSummary

Write-Host "`nGotowe. Uruchom teraz:" -ForegroundColor Green
if ($UseInsiders) {
    Write-Host "  .\scripts\Verify-Setup.ps1 -UseInsiders$(if ($InstallAndroidTooling) { ' -InstallAndroidTooling' })"
}
else {
    Write-Host "  .\scripts\Verify-Setup.ps1$(if ($InstallAndroidTooling) { ' -InstallAndroidTooling' })"
}
