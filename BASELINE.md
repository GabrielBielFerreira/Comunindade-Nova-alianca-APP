# BASELINE — checkout real (Fase 0)

**Branch:** `feat/multi-igreja-painel`
**Base:** commit `b6aab1e` (v1.3.0+10)
**Data:** 2026-08-16
**Máquina:** Windows 10, Flutter 3.41.6 (stable, engine 425cfb54d0), Node presente, Java presente.

Este baseline foi gerado no checkout real deste repositório (não em cópia
temporária). É a referência de "antes" para as Fases 0 e 1.

## Ambiente / ferramentas

| Ferramenta | Estado |
|---|---|
| flutter | `C:\src\flutter\bin\flutter.bat` — 3.41.6 stable |
| dart | presente |
| node / npm / npx | presentes |
| java | presente |
| firebase CLI (global) | **AUSENTE** |
| flutterfire CLI | **AUSENTE** |
| firebase-tools (npm global) | **não instalado** |
| Autenticação Firebase | **nenhuma** (`~/.config/configstore/firebase-tools.json` vazio: sem `user`, sem `activeProjects`) |

## Configuração Firebase

- `lib/firebase_options.dart` — **AUSENTE** (ignorado pelo Git; existe `.example`).
- `android/app/google-services.json` — **AUSENTE** (ignorado pelo Git).
- `ios/Runner/GoogleService-Info.plist` — **AUSENTE**.
- `.env` — **AUSENTE** (existe `.env.example`).
- `firebase.json` declara `projectId: nova-alianca-app`, appId Android
  `1:335786267314:android:ff524d79e2c9c4296cafab`.

**Restauração da configuração:** BLOQUEADA nesta sessão. Não há CLI do Firebase
nem autenticação válida, e a configuração real não pode ser fabricada. Registrado
como bloqueio externo (ver relatório). O trabalho segue via Emulator Suite e
testes de Rules, que não dependem das credenciais de produção.

## Resultados

### `flutter pub get`
OK — `Changed 2 dependencies!` (resolução dentro das constraints do `pubspec.lock`).
89 pacotes têm versões novas incompatíveis com as constraints (upgrade amplo NÃO
foi feito — proibido misturar com a arquitetura).

### `flutter analyze`
Exit code 1 — **2 erros, ambos causados pela ausência de `firebase_options.dart`:**

```
error - Target of URI doesn't exist: 'firebase_options.dart' - lib\main.dart:15:8 - uri_does_not_exist
error - Undefined name 'DefaultFirebaseOptions' - lib\main.dart:52:16 - undefined_identifier
```

Nenhum outro erro/aviso de lint. Estes dois desaparecem assim que a configuração
Firebase for restaurada (bloqueio externo), sem alteração de código.

### `flutter test`
**79 testes — todos passaram** (`All tests passed!`). 14 arquivos de teste.
Cobertura concentrada em: modelos (`usuario_model`, `pedido_oracao`,
`transacao`/`pix_payload`), validadores, formatters, Bíblia, hinário, Palavra do
Dia e `SplashScreen`. Não há teste de Rules nem de integração (lacuna endereçada
na Fase 1).

### Build Android debug
**BLOQUEADO** — requer `android/app/google-services.json` (ausente). Não
executado para evitar um build longo e garantidamente falho. Desbloqueia junto
com a restauração da configuração Firebase.

## Conclusão do baseline

O código-fonte Dart está saudável (analyze limpo exceto pela config ausente;
todos os testes verdes). Os únicos impedimentos de compilação são externos
(configuração Firebase), não defeitos de código.
