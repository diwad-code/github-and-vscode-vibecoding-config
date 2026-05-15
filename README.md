# github-and-vscode-vibecoding-config

Kompletny zestaw skryptów PowerShell do automatycznego przygotowania świeżego Windows 11 pod:
- VS Code / VS Code Insiders
- GitHub Copilot Pro / Pro+
- vibe-coding dla: aplikacji web, stron firmowych, retro gier pixel-art w przeglądarce (z opcją Android), automatyzacji Windows

## Plan wdrożenia (najpierw plan)

- [x] Zainstalować narzędzia bazowe i runtime’y (winget + automatyzacja)
- [x] Zainstalować edytory VS Code / VS Code Insiders
- [x] Zainstalować rozszerzenia pod Copilot, web, UI/UX, game/web, automatyzację systemu
- [x] Wgrać gotowe ustawienia VS Code (nowoczesny, produktywny UX)
- [x] Doinstalować CLI/tooling dla frontend/backend/mobile/desktop
- [x] Zapewnić skrypt weryfikacji środowiska po instalacji

## Struktura

- `/scripts/Install-VibeCodingEnvironment.ps1` – główny, automatyczny instalator
- `/scripts/Configure-VSCode.ps1` – konfiguracja rozszerzeń i ustawień VS Code/Insiders
- `/scripts/Verify-Setup.ps1` – szybka walidacja po instalacji
- `/scripts/config/vscode-extensions.txt` – pełna lista rozszerzeń
- `/scripts/config/vscode-settings.json` – szablon ustawień UI/UX i produktywności

## Szybki start (PowerShell jako Administrator)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd "<ścieżka-do-repo>"
.\scripts\Install-VibeCodingEnvironment.ps1 -UseInsiders -InstallAndroidTooling
.\scripts\Verify-Setup.ps1 -UseInsiders
```

## Uwagi

- Logowanie do GitHub Copilot odbywa się interaktywnie po uruchomieniu VS Code / Insiders.
- Skrypt działa idempotentnie: próbuje instalować brakujące elementy i kontynuuje przy błędach pojedynczych pakietów.
