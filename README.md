# Comunidade Nova Aliança — App

Aplicativo Flutter da **Comunidade Nova Aliança** (Olinda-PE), para visitantes,
membros e liderança. O painel administrativo completo é um sistema **externo**;
dentro do app, a tela **Gestão** é apenas a porta de entrada para esse painel.

> **Estado atual (V1 estrutural):** app unificado com autenticação real (Firebase
> Auth), roteamento por perfil e telas visuais aprovadas em produção. Integrações
> externas (Firebase, Mercado Pago, painel de Gestão) ficam **prontas para
> configurar** — veja [Configuração](#configuração) e `STATUS_FINAL_CNA_APP.md`.

## Visão geral

- **Perfis:** visitante, membro (pendente/aprovado/inativo), líder, pastor, diácono.
- **Fluxo único de produção:** `lib/main.dart` → `RootGate` decide a tela por
  sessão/perfil. Não há mais dois apps paralelos (visual x produção).
- **Navegação:**
  - Membro: Início · Avisos · Programação · Oração · Contribuir · Perfil
  - Liderança: as acima + **Gestão**
  - Visitante: Início · Conhecer · Programação · Contribuir · Entrar
- **Identidade visual:** tema claro, vinho `#7A0022`, Montserrat (títulos) + Inter
  (texto). Sem dark mode, sem dourado.

## Requisitos

- Flutter SDK compatível com Dart `^3.11.4` (canal stable recente).
- Android SDK (compileSdk 36, minSdk 23) + JDK 17.
- Conta/projeto **Firebase** (Auth, Firestore, Storage, Messaging).
- Para pagamentos: conta **Mercado Pago** (uso server-side) + Cloud Functions.

## Configuração

### 1. Dependências
```bash
flutter pub get
```

### 2. Firebase (obrigatório para login e dados)
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Isso gera `lib/firebase_options.dart` e `android/app/google-services.json`.
Depois, em `lib/main.dart`, troque a inicialização por:
```dart
import 'firebase_options.dart';
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```
Habilite no Console: **Authentication → E-mail/senha**, **Firestore**, **Storage**,
**Cloud Messaging**. Publique as regras:
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```
> Enquanto o Firebase não estiver configurado, o app abre em modo degradado e
> mostra a tela pública (o login não funciona). O plugin Google Services é
> aplicado automaticamente **apenas** quando `android/app/google-services.json`
> existir, então o build continua funcionando sem ele.

### 3. Variáveis de build (`--dart-define`)
Configuração pública injetada no build (sem segredos):
```bash
flutter run \
  --dart-define=GESTAO_PANEL_URL=https://painel.suaigreja.com.br \
  --dart-define=MULTI_IGREJA=false
```
- `GESTAO_PANEL_URL`: URL do painel externo (botão "Abrir painel de gestão").
- `MULTI_IGREJA`: habilita seleção/troca de igreja (padrão `false` — V1 é só CNA).

Veja `.env.example` para variáveis de **backend** (Mercado Pago/webhook) —
**nunca** coloque segredos no app Flutter.

### 4. Assinatura de release (Android)
```bash
keytool -genkey -v -keystore android/nova-alianca-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias nova-alianca
```
Copie `android/key.properties.example` para `android/key.properties` e preencha.
Sem esse arquivo, qualquer tarefa de release é bloqueada antes da compilação;
o projeto nunca usa a chave de debug como fallback de produção.

## Execução
```bash
flutter run                 # debug
flutter run --release       # requer Firebase + keystore configurados
```

## Testes
```bash
flutter analyze                 # meta: 0 erros
flutter test                    # testes unitários/widget
flutter test --coverage         # com cobertura
```
Testes atuais (Dart puro, sem device): `validators`, `formatters`,
`usuario_model` (serialização), `auth_error` (mensagens), `splash` (widget).

## Build
```bash
flutter build apk --debug                 # APK de teste
flutter build apk --release               # após configurar Firebase + keystore
flutter build appbundle --release         # para a Play Store
```

## Estrutura do projeto
```
lib/
  main.dart                 # entrypoint único de produção
  app/
    root_gate.dart          # roteamento por sessão/perfil
    screens/                # splash, aguardando-aprovação, conta-inativa
  core/
    config/app_config.dart  # flags/URLs via --dart-define
    constants/              # strings, dados da igreja
    services/               # firestore, fcm
    theme/                  # cores, tipografia, tema
    utils/                  # validators, formatters
  features/
    auth/                   # AuthService, AuthActions, modelo de usuário
    avisos/ eventos/ oracao/ contribuir/ campanhas/  # modelos por feature
  visual/
    screens/                # 33 telas aprovadas (UI)
    widgets/                # componentes compartilhados (nav, cards)
    mock/                   # dados de exemplo (a substituir por Firestore)
    visual_router.dart      # mapa de rotas nomeadas + constantes
```

## Segurança
- Sem segredos no repositório (`.gitignore` cobre chaves, `google-services.json`,
  `firebase_options.dart`, `.env`).
- Regras de Firestore/Storage restritivas (`firestore.rules`, `storage.rules`):
  perfil próprio, pedidos privados protegidos, transações só-leitura no cliente
  (confirmação de pagamento é server-side).
- Cartão/boleto via Mercado Pago devem passar por Cloud Functions — **nunca**
  processe dados de cartão nem exponha access token no app.

## Bíblia (Palavra e Louvor)

- **Tradução:** João Ferreira de Almeida (**domínio público**).
- **Provedor:** [bible-api.com](https://bible-api.com) — **gratuito e sem chave de API**.
- **Configuração** (opcional, para trocar provedor/tradução):
  ```bash
  flutter run \
    --dart-define=BIBLE_API_BASE_URL=https://bible-api.com \
    --dart-define=BIBLE_TRANSLATION=almeida
  ```
- **Arquitetura:** `BibleRepository` (interface agnóstica) →
  `BibleApiRepository` (HTTP) + `BibleLocalStore` (cache offline via
  SharedPreferences). Trocar de provedor não afeta a UI.
- **Recursos:** AT/NT, livro/capítulo, versículos numerados, capítulo
  anterior/seguinte (cruza livros), busca por referência, favoritos, histórico,
  último capítulo lido, tamanho de fonte, copiar/compartilhar versículo,
  loading/erro/offline (capítulos já lidos funcionam sem internet).
- **Limitações:** a bible-api.com não oferece busca textual — a busca é por
  referência (ex.: "João 3", "Salmos 23"). Nenhum versículo é inventado; o
  texto vem sempre do provedor. A Bíblia inteira **não** é armazenada no
  Firestore; apenas os capítulos acessados são cacheados localmente.

## Cantor Cristão

- **Conteúdo:** deve ser fornecido pelo responsável em arquivo **autorizado**
  `assets/hinos/cantor_cristao.json` (ver formato em
  `assets/hinos/cantor_cristao.exemplo.json`). **Nenhuma letra é embutida ou
  inventada** — sem o arquivo autorizado, o módulo exibe um estado vazio honesto.
- **Formato JSON:**
  ```json
  {
    "edicao": "Cantor Cristão — edição autorizada",
    "direitos": "detentor / licença",
    "hinos": [
      {"numero": 1, "titulo": "...", "autoria": "...",
       "coro": "...", "estrofes": ["estrofe 1", "estrofe 2"]}
    ]
  }
  ```
- **Arquitetura:** `HymnalRepository` → `AssetHymnalRepository` (lê e valida o
  JSON) + `HymnalLocalStore` (favoritos/histórico/fonte). Validador em
  `validarHinario` (número, título, estrofes, duplicidade).
- **Recursos:** lista por número, busca por número/título, página do hino
  (número/título em destaque, estrofes, coro), anterior/seguinte, favoritos,
  histórico, tamanho de fonte, compartilhamento apenas da **referência**
  (número/título) para respeitar direitos. Áudio/partituras/cifras fora do escopo.
- **Pendência externa:** fornecer `assets/hinos/cantor_cristao.json` autorizado.

## Documentos relacionados
- `AUDITORIA_TECNICA_CNA_APP.md` — inventário e estado de cada tela/feature.
- `PLANO_FECHAMENTO_CNA_APP.md` — backlog P0–P3 e critérios de aceite.
- `STATUS_FINAL_CNA_APP.md` — o que foi feito, pendências e bloqueios externos.
