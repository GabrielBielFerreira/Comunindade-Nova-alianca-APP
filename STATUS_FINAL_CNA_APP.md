# Status Final — Comunidade Nova Aliança App

Resumo honesto do que foi feito nesta sessão, o que ficou pendente e o que
depende de recursos externos. Escopo acordado: **Núcleo Estrutural (P0/P1)**,
modo **"codificar agora, compilar/validar depois"** (a máquina de trabalho não
tinha Flutter/Dart/Java/Android SDK instalados).

## 1. O que foi implementado

### Arquitetura / unificação
- **App unificado**: removidos os entrypoints paralelos (`main_producao.dart`,
  `main_visual.dart`, `visual/visual_app.dart`) e o roteador de placeholders
  (`core/router/app_router.dart` + `shared/widgets/placeholder_tela.dart`).
- **`lib/main.dart`** agora é o único entrypoint: `ProviderScope` + `MaterialApp`
  usando as **telas visuais reais** (mapa `visualRoutes`) e o **`RootGate`** como
  raiz.
- **`lib/app/root_gate.dart`**: decide a tela por sessão/perfil
  (não autenticado → Welcome; pendente → Aguardando aprovação; inativo → Conta
  inativa; aprovado → Home de membro ou de liderança).
- Telas de estado criadas: `splash_screen`, `aguardando_aprovacao_screen`,
  `conta_inativa_screen`.

### Autenticação (Firebase Auth real)
- Login (`entraconta_screen`), cadastro (`cadastro_screen`) e recuperação
  (`recuperar_senha_screen`) convertidos para Riverpod e ligados ao `AuthService`.
- **Removidas as credenciais de demonstração** e o autofill/logo-tap.
- Logout real com confirmação em `perfil_screen`, incluindo **desativação do
  token FCM**.
- `AuthService` órfão (`core/services/auth_service.dart`) removido; criado
  `AuthActions` (`features/auth/providers/auth_controller.dart`) e o mapeador de
  erros PT-BR (`features/auth/data/auth_error.dart`); status `inativo` tratado.

### Remoção de célula (completa)
- Excluídos `features/celula/`, campo `celulaId` (modelo + serialização), valores
  de enum (`SegmentoAviso`, `TipoEvento`), string `minhasCelula` e o culto
  "Células de Jovens" (→ "Culto de Jovens"). **Zero** referências restantes.

### Android / Firebase (config-ready)
- `build.gradle.kts`: assinatura de release via `key.properties` (fallback debug),
  `minSdk 23`, `multiDexEnabled`; plugin `google-services` aplicado **apenas** se
  `google-services.json` existir (não quebra o build sem Firebase).
- `AndroidManifest.xml`: `INTERNET`, `POST_NOTIFICATIONS`, canal FCM padrão.
- Regras de segurança reais: `firestore.rules`, `storage.rules`,
  `firestore.indexes.json`, `firebase.json`.
- Arquivos de exemplo seguros: `lib/firebase_options.dart.example`,
  `android/key.properties.example`, `android/app/google-services.json.example`,
  `.env.example`.
- `.gitignore` atualizado para proteger segredos.

### FCM
- `FcmService.init()` chamado ao autenticar (RootGate); background handler
  registrado em `main.dart`; token desativado no logout.

### Gestão
- Botão "Abrir painel de gestão" agora usa `url_launcher` com **URL configurável**
  (`AppConfig.gestaoPanelUrl` via `--dart-define`), validação de esquema http(s)
  e mensagens de erro amigáveis (sem simular conexão).

### Qualidade / acessibilidade
- `TextScaler.noScaling` global substituído por **clamp acessível** (0.85–1.3).
- Correção de encoding UTF-8 no `pubspec.yaml`.
- `AppConfig` com feature flag `multiIgrejaHabilitada` (CNA como padrão).

### Testes
- Placeholder substituído por suítes reais (Dart puro): `validators_test`,
  `formatters_test`, `usuario_model_test`, `auth_error_test`, `widget_test`
  (SplashScreen).

## 2. Arquivos alterados (45 arquivos; +1269 / −676 linhas)
Principais adições: `lib/app/**`, `lib/core/config/app_config.dart`,
`lib/features/auth/data/auth_error.dart`, `lib/features/auth/providers/auth_controller.dart`,
`firestore.rules`, `storage.rules`, `firebase.json`, `firestore.indexes.json`,
exemplos de config, testes.
Remoções: `main_producao.dart`, `main_visual.dart`, `visual/visual_app.dart`,
`core/router/app_router.dart`, `core/services/auth_service.dart`,
`shared/widgets/placeholder_tela.dart`, `features/celula/**`.
Histórico em git (branch local, baseline preservado como primeiro commit).

## 3. Testes executados / resultados
- **Não executados nesta máquina**: Flutter/Dart/Java/Android SDK **não instalados**
  (somente `git`). Portanto `flutter pub get`, `dart format`, `flutter analyze`,
  `flutter test` e `flutter build apk` **não puderam ser rodados aqui**.
- Os testes foram escritos para rodar sem device/Firebase. Execute no seu ambiente:
  ```bash
  flutter pub get && flutter analyze && flutter test
  ```
- Correções feitas com revisão estática cuidadosa; **é esperado** que o primeiro
  `flutter analyze` possa apontar pequenos ajustes (ex.: imports não usados) —
  corrigir conforme apontado.

## 4. APK gerado
- **Não gerado** (sem toolchain nesta máquina). Após instalar o Flutter:
  ```bash
  flutter build apk --debug   # APK de teste em build/app/outputs/flutter-apk/
  ```

## 5. Configurações pendentes (bloqueios externos)
| Bloqueio | O que falta | Onde configurar | Quem fornece |
|---|---|---|---|
| Firebase | `flutterfire configure` + `google-services.json` + habilitar Auth/Firestore/Storage/FCM + `firebase deploy` das rules | Console Firebase + raiz do projeto | Responsável técnico |
| Assinatura release | Gerar keystore + `android/key.properties` | pasta `android/` | Responsável pela publicação |
| Painel de Gestão | URL do painel externo | `--dart-define=GESTAO_PANEL_URL=...` | Administração |
| Pagamentos | Credenciais Mercado Pago (server) + Cloud Functions (cartão/boleto/webhook) | backend/Functions | Responsável financeiro/TI |
| Toolchain | Instalar Flutter + Android SDK | máquina de build | Desenvolvedor |

## 6. Riscos restantes
- Sem compilação local, pode haver ajuste fino no primeiro `analyze` (baixo risco).
- Navegação por abas ainda usa `Navigator.pushNamed` dentro do shell de cada tela
  (pilha pode crescer). Migração para `StatefulShellRoute.indexedStack` é o próximo
  passo recomendado (P1-10) — não feita agora para não introduzir regressão não
  verificável em 97 pontos de navegação.
- Telas de conteúdo (Avisos/Programação/Oração/Contribuir/Perfil) ainda exibem
  **dados mock**; o wiring com Firestore depende do Firebase ativo (fora do escopo
  desta sessão). O login/perfil já é real, mas o nome exibido na Home vem de mock
  até o wiring.
- Camada de repositórios não foi criada como abstração especulativa (evitar código
  morto); recomenda-se introduzi-la junto ao wiring de dados.

## 7. Próximos passos mínimos
1. Instalar Flutter/Android SDK; `flutter pub get`; `flutter analyze` (corrigir avisos).
2. `flutterfire configure` + publicar rules; testar login/cadastro/aprovação ponta a ponta.
3. Gerar keystore + `key.properties`; `flutter build apk --release`.
4. Migrar navegação para shell (P1-10) e iniciar wiring de dados por feature.
5. Integrar Mercado Pago via Cloud Functions; formalizar política de privacidade (LGPD).
