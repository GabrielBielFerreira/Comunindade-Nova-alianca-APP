# Guia de Instalação e Primeiro Build (Windows)

Passo a passo para deixar a máquina pronta para compilar, testar e gerar o APK do
app da Comunidade Nova Aliança. Depois disso, siga o `README.md` para a parte do
Firebase.

## 1. Pré-requisitos

| Ferramenta | Versão | Para quê |
|---|---|---|
| Git | qualquer recente | já instalado |
| Flutter SDK | stable recente (Dart ≥ 3.11) | compilar o app |
| Android Studio | recente | Android SDK + emulador |
| JDK | 17 | build Android (vem com o Android Studio) |

## 2. Instalar o Flutter

**Opção A — winget (mais simples):**
```powershell
winget install --id Google.Flutter -e
winget install --id Google.AndroidStudio -e
```

**Opção B — manual:**
1. Baixe o Flutter SDK (Windows) em https://docs.flutter.dev/get-started/install/windows
2. Extraia para `C:\src\flutter` (evite pastas com espaços ou acentos).
3. Adicione `C:\src\flutter\bin` ao PATH do usuário (Configurações → "Editar as
   variáveis de ambiente do sistema" → Variáveis de ambiente → Path → Novo).
4. Feche e reabra o terminal.

## 3. Configurar o Android SDK

1. Abra o **Android Studio** → assistente inicial → instale o **Android SDK**,
   **SDK Platform** e **Android SDK Command-line Tools**.
2. Aceite as licenças:
```powershell
flutter doctor --android-licenses
```

## 4. Verificar o ambiente
```powershell
flutter doctor -v
```
Resolva o que aparecer com ✗ (normalmente licenças do Android ou o caminho do JDK).

## 5. Primeiro build do projeto

No diretório do projeto (`Comunindade-Nova-alianca-APP-main`):
```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
- Se o `analyze` apontar algo (ex.: import não usado), corrija — são ajustes
  pequenos esperados por eu não ter compilado na máquina original.
- Os testes devem passar (Dart puro, sem device).

## 6. Rodar o app

Sem Firebase configurado, o app abre em modo degradado (tela pública; login não
funciona). Para testar a UI:
```powershell
flutter run --dart-define=GESTAO_PANEL_URL=https://exemplo.com
```

Para o fluxo completo (login/cadastro/aprovação), configure o Firebase antes —
seção "Configuração" do `README.md`.

## 7. Gerar o APK de teste
```powershell
flutter build apk --debug
```
Saída em: `build\app\outputs\flutter-apk\app-debug.apk`.
Instale num aparelho com depuração USB ativada:
```powershell
flutter install
```

## 8. Release (após Firebase + keystore)
Veja `README.md` seções 2 e 4. Só então:
```powershell
flutter build apk --release
# ou, para a Play Store:
flutter build appbundle --release
```

## Problemas comuns
- **"cmdline-tools component is missing"** → Android Studio → SDK Manager → SDK
  Tools → marque "Android SDK Command-line Tools" → Apply.
- **Licenças não aceitas** → `flutter doctor --android-licenses`.
- **Gradle lento no primeiro build** → normal (baixa dependências); aguarde.
- **`flutter` não reconhecido** → PATH não atualizado; reabra o terminal.
