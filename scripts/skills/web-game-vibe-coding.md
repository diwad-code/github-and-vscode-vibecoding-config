# Web Game Vibe Coding Skill

> Wersja dokumentu: gpt5.5-2026.05.19-0.3.1

## Cel
Tworzenie webowych gier 2D/3D i przygotowanie ich do dystrybucji jako aplikacje Android.

## Preferowane modele
- Chat/agent: GPT-5.5
- Completions/inline suggestions: GPT-5.4
## Zasada dokumentacji
- Każda zmiana workflow, stacku albo checklisty wymaga natychmiastowej aktualizacji tego dokumentu.
- Przy każdej zmianie trzeba też podnieść oznaczenie wersji w formacie `model-data-wersja`.

## Stack
- Vite + TypeScript jako domyślny starter.
- Phaser lub PixiJS dla 2D/pixel-art.
- Three.js albo Babylon.js dla 3D.
- Capacitor/Ionic do pakowania web game jako Android app.
- Lighthouse i axe do sprawdzania jakości powłoki webowej.

## Workflow
- Najpierw wygeneruj minimalny prototyp gry.
- Utrzymuj assets w oddzielnym katalogu i dokumentuj licencje.
- Projektuj sterowanie pod desktop i touch.
- Przed buildem Android sprawdź responsywność, performance i rozmiar bundla.
