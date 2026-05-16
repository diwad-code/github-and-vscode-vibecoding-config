# Plan wdrożenia vibe-coding environment

Ten plik jest źródłem kontekstu dla kolejnych AI i ludzi kontynuujących pracę.

## Cel

Zbudować potężny, automatyczny zestaw skryptów dla Windows 11, VS Code i VS Code Insiders do vibe-codingu:
- web apps i profesjonalne strony firmowe,
- web games / pixel-art / 2D/3D,
- hybrydowe aplikacje Android z web stacku,
- backend/API/devops/automatyzacja,
- GitHub Copilot Pro/Pro+ i agentowe workflow.

## Zakres wdrożenia

- [x] Utworzyć ten plik planu/TODO dla kontynuacji prac.
- [x] Rozszerzyć główny instalator o retry, raport końcowy i fallbacki.
- [x] Rozszerzyć listy pakietów winget/npm/pip pod web/game/mobile/business.
- [x] Rozszerzyć konfigurację VS Code i VS Code Insiders.
- [x] Dodać lokalny katalog skilli oraz manifest do automatycznej instalacji.
- [x] Rozszerzyć weryfikację środowiska po instalacji.
- [x] Zaktualizować README.
- [x] Uruchomić końcową walidację składni/JSON.
- [x] Uruchomić CodeQL checker.
- [x] Follow-up review: poprawić weryfikację Capacitor CLI, aby akceptowała `cap` z `@capacitor/cli`.
- [x] Final review: rozszerzyć realnie przydatny gamedev stack (Godot/Unity/Blender/C++/CMake), dodać brakujące skille i przepiąć domyślne modele na GPT-5.4/GPT-5.5.

## Architektura

- `scripts/Install-VibeCodingEnvironment.ps1` pozostaje głównym orkiestratorem.
- `scripts/Configure-VSCode.ps1` instaluje rozszerzenia, scala ustawienia i instaluje lokalne skille.
- `scripts/Verify-Setup.ps1` sprawdza gotowość środowiska.
- `scripts/config/vscode-extensions.txt` zawiera rozszerzenia dla VS Code i Insiders.
- `scripts/config/vscode-settings.json` zawiera bazowe ustawienia UX/productivity/Copilot.
- `scripts/config/skills-manifest.json` wskazuje lokalne i opcjonalne zdalne skille.
- `scripts/skills/` zawiera lokalne skille startowe dla web/business oraz gamedev.

## Kolejne rekomendowane kroki

- [ ] Dodać profile `.code-profile`, jeśli zespół zdecyduje się wersjonować profile VS Code jako eksporty.
- [ ] Dodać opcjonalny manifest z firmowymi, zatwierdzonymi zdalnymi skillami po wskazaniu URL-i.
- [ ] Dodać test uruchamiany na Windows runnerze, jeżeli repo dostanie CI.
- [ ] Rozważyć pinning wersji narzędzi npm/pip w osobnych manifestach enterprise.
- [ ] Rozważyć osobny, opcjonalny przełącznik do ciężkich tooli gamedev (np. Unity Hub/Blender/Tiled), jeśli repo zacznie zarządzać też instalacją silników i asset toolchain poza VS Code.
