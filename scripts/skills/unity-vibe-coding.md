# Unity Vibe Coding Skill

## Cel
Tworzenie prototypów i produkcyjnych workflow w Unity z naciskiem na czysty C#, szybkie iteracje i stabilne buildy.

## Preferowane modele
- Chat/agent: GPT-5.5
- Completions/inline suggestions: GPT-5.4

## Stack
- Unity extension + C# tooling w VS Code.
- Prefaby, ScriptableObject i małe systemy gameplayowe zamiast monolitów.
- URP/HDRP tylko gdy projekt faktycznie ich potrzebuje.
- Profilowanie, logowanie i automatyczne buildy odpalane wcześnie, nie na końcu.

## Workflow
- Zaczynaj od sceny testowej i zamkniętej pętli gameplayowej.
- Trzymaj dane konfiguracyjne poza klasami runtime, najlepiej w ScriptableObject lub prostych assetach.
- Rozdzielaj input, logikę gry, UI i audio, żeby agent łatwo mógł iterować po modułach.
- Każdą zmianę scen/prefabów/domknięć builda waliduj na małym, powtarzalnym flow.
