# CONTINUAR_AQUI — Handoff do Comunidade Nova Aliança App

> Documento para retomar o desenvolvimento numa nova janela do Claude Code, sem
> perder contexto. Leia inteiro antes de alterar. **Não recrie o Firebase nem
> remova avanços.** Atualizado em **01/08/2026** — app na **versão 1.1.2+4**.

## 0. Como confirmar que está no mesmo código
- `git log --oneline -3` deve mostrar no topo `3a8c223 fix(auth): ... líder => lider — v1.1.2`.
- Devem existir: `lib/app/root_gate.dart` e `lib/firebase_options.dart`.
- Working dir do projeto: `C:\Users\User\Desktop\Jailton\Claude Cod\CNA APP\Comunindade-Nova-alianca-APP-main`
  (o Desktop tem só a pasta; o projeto Flutter está DENTRO dela).

## 1. Ambiente e ferramentas
- **Flutter:** `C:\flutter\bin\flutter.bat` (Flutter 3.44.x / Dart 3.12). No bash use `cmd //c "C:\flutter\bin\flutter.bat ..."`.
- **Firebase CLI:** `%APPDATA%\npm\firebase.cmd` (logado). Deploy de regras já usado nesta sessão.
- **keytool** (para SHA/keystore): `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.
- **Python + fonttools** disponíveis (usados para instanciar as fontes).
- **Git:** repositório local ativo (~40 commits). **Commite cada incremento.**
- **Shell:** PowerShell é o primário; a ferramenta Bash roda Git Bash. `gradlew.bat` via `cmd //c` NÃO acha o arquivo por causa do cwd — se precisar de erro do Gradle, rode `flutter build apk` redirecionando para um log e leia o arquivo.

## 2. VERSIONAMENTO DO APK (convenção obrigatória)
A cada atualização: **subir a versão** em `pubspec.yaml` (`MAJOR.MINOR.PATCH+BUILD`;
PATCH p/ correção, MINOR p/ lote de features, sempre incrementar o BUILD) →
`flutter build apk --debug` → copiar para o Desktop como
`C:\Users\User\Desktop\NovaAlianca-v<MAJOR.MINOR.PATCH>.apk` e **remover o anterior**
(`rm -f Desktop/NovaAlianca-v*.apk` antes de copiar) → commit do bump.
Estado atual: **v1.1.2 (build 4)**. Debug (mesma assinatura que ele instala por cima).

## 3. Firebase (JÁ CONFIGURADO — não recriar)
- Projeto **`nova-alianca-app`** (plano **Blaze**), região `southamerica-east1`.
- `lib/firebase_options.dart` e `android/app/google-services.json` existem (não versionados).
- **Regras** em `firestore.rules` — **publicadas** (deploy nesta sessão). Deploy:
  `cmd //c "%APPDATA%\npm\firebase.cmd deploy --only firestore:rules --project=nova-alianca-app"`
- Coleções: `usuarios`, `pedidos_oracao`, `avisos`, `eventos`, `campanhas`, `notificacoes`,
  `tokens_dispositivo`, `ministerios`, `devocionais`, `interesses_ministerio`, `auditoria`,
  `configuracoes`, `transacoes`.
- **Administradores:** `jailtonmjc@gmail.com` (uid `rf9ZiVKnO5bVmewAzwmqr0eIQ242`, já `perfil="líder"`,
  `status="aprovado"`) e `gabrielbiel.ferreira0411@gmail.com`.
  O código agora **tolera acento** (`líder`/`Líder`/`lider` são equivalentes — ver `usuario_model.dart`).

## 4. ⚠️ PENDÊNCIAS NO CONSOLE DO FIREBASE (ação do usuário — não é código)
1. **Auth Anônima** (Authentication → Sign-in method → Anônimo): habilitar para o
   **pedido de oração de visitante** funcionar (o código faz `signInAnonymously`).
2. **Google Sign-In**: registrar as impressões SHA do app (Configurações → Seus apps →
   Android → Adicionar impressão) e baixar o `google-services.json` novo. SHA-1 de debug
   deste PC: `B9:7D:70:76:0D:C2:9E:BF:4A:E1:F5:43:C2:74:96:7C:D2:AD:7E:E2`
   SHA-256: `35:E2:19:80:2A:BA:7E:30:E3:97:49:A7:C1:BA:30:46:15:D6:E1:52:BB:4D:D8:BB:53:4B:2E:CC:7F:64:F9:BF`
   Ativar o provedor **Google** em Authentication.
3. **Semear dados** para as telas aparecerem no teste: `cd seed && node seed.js` precisa de
   `seed/serviceAccountKey.json` (Console → Contas de serviço → Gerar chave). Sem **eventos com
   data futura**, a **Programação** mostra o estado vazio (correto). Idem Campanhas.
4. **Storage** (foto de perfil): habilitar bucket + regras `storage.rules`.

## 5. Assinatura de RELEASE (Play Store)
- Já funciona: `flutter build apk --release` gera APK **assinado**.
- Keystore em `android/app/nova-alianca-release.jks` e credenciais em `android/key.properties`
  (**ambos gitignored**). **BACKUP obrigatório** do `.jks` + senha (perder = não atualiza na Play Store).
  A senha está só localmente no `key.properties`. Modelo em `android/key.properties.example`.
- Para Play Store, gerar **`.aab`**: `flutter build appbundle --release` (não feito ainda).
- Gradle: heap reduzido em `android/gradle.properties` (4G/2G) p/ evitar OOM no AOT do release.
  AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14.

## 6. Arquitetura (resumo)
- **Entrypoint:** `lib/main.dart` → `MaterialApp` (rota `/` = `RootGate`) + `navigatorKey` +
  Crashlytics (erros de widget e assíncronos) ligado só em release.
- **RootGate** (`lib/app/root_gate.dart`): decide a tela por sessão/perfil (Welcome / Aguardando /
  Inativo / Home membro / Home líder). Inicia FCM pós-login.
- **Navegação:** `lib/visual/visual_router.dart`. **IMPORTANTE:** as barras inferiores e o logout
  navegam para `VisualRoutes.entraconta` (= RootGate) via `pushNamedAndRemoveUntil`, para o gate
  reavaliar a sessão. NÃO voltar a apontar "Início"/logout para `homeMember` direto (era o bug do
  logout mostrar "Olá, João").
- **Estado:** Riverpod. Padrão por feature em `lib/features/<feature>/{data,providers,screens}`.
- **Config/flags:** `lib/core/config/app_config.dart` (dart-define): `MULTI_IGREJA`,
  `PAGAMENTOS_ONLINE`, `ESCOLA_LOUVOR`, `GESTAO_PANEL_URL`, `BIBLE_*`.
- **Telas visuais aprovadas:** `lib/visual/screens` — **preservar o visual**; só ajustar função.
- **Fontes:** Montserrat/Inter EMPACOTADAS em `assets/fonts/` (pesos estáticos gerados das variáveis
  OFL via fonttools). O `google_fonts` usa as locais (nomes batem com o padrão) — offline/rápido.

## 7. Fluxo de trabalho por item (OBRIGATÓRIO)
1. Implementar (preservando visual). 2. `flutter analyze` → **0 erros**. 3. `flutter test` → 50 testes.
4. Se mexeu em regras → deploy. 5. `flutter build apk --debug`. 6. Versionar o APK no Desktop (§2).
7. `git add -A && git commit`. 8. Avisar o usuário.

## 8. O QUE JÁ FOI FEITO (sessões anteriores + esta)
Itens 1–17 da lista original **concluídos**. Destaques desta sessão:
- **Item 4 (Cantor Cristão):** 581 hinos reais em `assets/hinos/cantor_cristao.json`.
- **Item 12 (Avisos/Programação):** dados reais, seletor de dias real, sem datas fixas.
- **Item 14 (menu Mais ☰):** na Home + Avisos + agora **Oração/Contribuir/Perfil** também.
- **Item 15 (Contribuições/Campanhas):** campanhas do Firestore + **PIX manual honesto** (QR + copia-e-cola
  gerado em Dart, `lib/features/contribuir/data/pix_payload.dart`, com teste de CRC16). Cartão/boleto
  ocultos sem `PAGAMENTOS_ONLINE`. Histórico começa vazio (sem dados falsos).
- **Item 17:** removidos controles mortos e "futuramente".
- **Bugs:** logout que travava/voltava errado (agora vai p/ boas-vindas via gate); **lentidão do teclado**
  (telas de formulário usam `MediaQuery.sizeOf` no lugar de `LayoutBuilder`); **perfil com acento**.
- **Features novas:** Google Sign-In (`AuthService.entrarComGoogle` + provisiona `usuarios/{uid}` pendente),
  **busca por voz na Bíblia** (`speech_to_text`, permissão RECORD_AUDIO), **compartilhar Palavra do Dia**,
  **lembrar e-mail** no login (só e-mail, nunca senha), **notificações reais** (tópicos FCM +
  `NotificationPreferences`), **lembrete de evento real** (`flutter_local_notifications` + `timezone`,
  `ReminderService`), **Crashlytics/Analytics**, **animações** (`lib/visual/widgets/motion.dart`:
  `FadeSlideIn`, `AnimatedProgressBar`, `CalmPageTransitionsBuilder`), **cache de imagem**
  (`cached_network_image`), **pedido de oração aberto a visitantes** (login anônimo + regra).

## 9. PENDÊNCIAS DE DESENVOLVIMENTO (próximos passos sugeridos)
- **Backend Mercado Pago** (Cloud Functions em `functions/`): publicar + credenciais + flag
  `PAGAMENTOS_ONLINE`. Cliente Dart pronto (`PagamentosService`). Ao confirmar via **webhook**, gravar
  `transacoes` aprovadas → o **histórico** deixa de ser vazio; e um **trigger** deve somar
  `campanhas.valor_arrecadado`.
- **Testes de widget** dos fluxos críticos (login, RootGate por perfil, contribuição/PIX) — cobertura
  hoje ~50 testes (models/validators/pix); regra do usuário pede 80%.
- **`.aab`** para a Play Store + ícone/splash definitivos.
- **Escola de Louvor:** preencher `configuracoes/escola_louvor` no Firestore OU manter flag off (hoje
  mostra "conteúdo ainda não configurado" — honesto, não é bug).
- **Bottom navigation duplicada** em ~8 telas (dívida técnica — extrair uma só).
- **Toggles simulados restantes?** Notificações e lembrete já são reais; revisar se sobrou algum.

## 10. Decisões OFICIAIS (não violar)
- App exclusivo da CNA na V1. Sem células. Segmentar por ministério/grupo.
- Tema claro; vinho `#7A0022`; fundo `#FAFAFA`; Montserrat (títulos) + Inter (texto).
  **Sem dourado, sem dark mode.** Não redesenhar telas aprovadas.
- **Critério:** nenhum elemento visível sem ação — ao tocar, abre função real, mostra estado
  (loading/vazio/erro) ou **não aparece**. Honestidade acima de tudo (nada de dados/confirmações falsas).
- Bíblia: João Ferreira de Almeida (domínio público) via bible-api.com. Não inventar versículos.
- Cantor Cristão: conteúdo autorizado (fonte cantorcristaobatista.com.br, OFL/domínio público).
- Pagamentos: nunca segredos no app; confirmação só por webhook; PIX manual honesto até o backend.

## 11. Memória persistente do agente
Há memórias em `~/.claude/projects/.../memory/`: convenção de versionar APK e nota das fontes.
