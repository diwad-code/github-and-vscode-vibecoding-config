# github-and-vscode-vibecoding-config

Kompletny zestaw skryptów PowerShell do automatycznego przygotowania świeżego Windows 11 pod:
- VS Code / VS Code Insiders,
- GitHub Copilot Pro / Pro+,
- vibe-coding dla aplikacji web, stron firmowych, web games i Android hybrid apps,
- backend/API/devops oraz automatyzację Windows.

## Aktualny plan i TODO

Szczegółowy plan wdrożenia oraz lista TODO dla kolejnych AI znajduje się w:

- [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md)

## Co instaluje i konfiguruje

- Edytory: VS Code oraz opcjonalnie VS Code Insiders.
- Copilot/GitHub: Copilot, Copilot Chat, GitHub PR, GitHub Actions, GitHub CLI.
- Web/business: Node.js, pnpm, yarn, Vite, Next.js, Angular, Astro, Tailwind, ESLint, Prettier, Stylelint.
- Game/web: Live Server, Godot tools, Markdown/Mermaid, CLI pod prototypowanie web games.
- Android hybrid: Android Studio, JDK, Ionic, Capacitor, native-run, Cordova.
- Backend/devops: Docker, Dev Containers, Kubernetes, YAML, Terraform, Postman/Thunder Client.
- Python/.NET/Go/Rust: runtime’y, rozszerzenia i podstawowe narzędzia.
- Skille: lokalne workflow dla web games i profesjonalnych stron firmowych kopiowane do `~\.vibe-coding\skills`.

## Struktura

- `/scripts/Install-VibeCodingEnvironment.ps1` – główny, automatyczny instalator.
- `/scripts/Configure-VSCode.ps1` – konfiguracja rozszerzeń, ustawień i skilli VS Code/Insiders.
- `/scripts/Verify-Setup.ps1` – walidacja po instalacji.
- `/scripts/config/vscode-extensions.txt` – pełna lista rozszerzeń.
- `/scripts/config/vscode-settings.json` – szablon ustawień UI/UX i produktywności.
- `/scripts/config/skills-manifest.json` – manifest lokalnych i opcjonalnych zdalnych skilli.
- `/scripts/skills/` – lokalne skille startowe.

## Szybki start: pełny tryb z VS Code Insiders i Androidem

Uruchom PowerShell jako Administrator:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd "<ścieżka-do-repo>"
.\scripts\Install-VibeCodingEnvironment.ps1 -UseInsiders -InstallAndroidTooling
.\scripts\Verify-Setup.ps1 -UseInsiders -InstallAndroidTooling
```

## Tryb standardowy bez Androida

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd "<ścieżka-do-repo>"
.\scripts\Install-VibeCodingEnvironment.ps1
.\scripts\Verify-Setup.ps1
```

## Sama konfiguracja VS Code / Insiders

Przydatne po ręcznej instalacji narzędzi albo po aktualizacji listy rozszerzeń:

```powershell
.\scripts\Configure-VSCode.ps1
.\scripts\Configure-VSCode.ps1 -UseInsiders
```

## Zaawansowane fallbacki

Skrypty są idempotentne i kontynuują pracę przy błędach pojedynczych pakietów:

- `winget` ma retry i raport końcowy z ręcznymi linkami fallback.
- `npm` ma retry, próbuje włączyć Corepack i sugeruje `npx`/instalację lokalną, jeśli global install nie działa.
- `pip` ma retry i sugeruje instalację przez `py -m pip` albo venv.
- VS Code Insiders ma fallback do stable VS Code, jeśli `code-insiders` nie jest dostępny.
- Niepoprawny istniejący `settings.json` jest backupowany przed nadpisaniem ustawień z szablonu.
- Skille z manifestu mogą być lokalne albo zdalne; błędy pobierania nie blokują konfiguracji edytora.

## Po instalacji

1. Uruchom VS Code / VS Code Insiders.
2. Zaloguj się do GitHub i GitHub Copilot.
3. Uruchom Docker Desktop co najmniej raz, jeśli używasz kontenerów.
4. Uruchom Android Studio i doinstaluj SDK/emulator, jeśli używasz Androida.
5. Uruchom `Verify-Setup.ps1`, aby zobaczyć elementy OK/WARN/ERR.

## Uwagi bezpieczeństwa

- Nie commituj sekretów, tokenów ani plików `.env` z danymi produkcyjnymi.
- Zdalne skille dodawaj do `skills-manifest.json` tylko z zatwierdzonych źródeł.
- Dla firmowych projektów rozważ pinning wersji narzędzi w osobnych manifestach.
