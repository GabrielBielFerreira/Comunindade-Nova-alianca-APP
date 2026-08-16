# Publicação em produção — `nova-alianca-app`

Este runbook cobre a etapa que **não pôde ser executada automaticamente**: ela
exige autenticação interativa no Firebase, que só você pode fazer.

Tudo que antecede o deploy já está pronto e testado no emulador. Execute os
passos na ordem; cada um é verificável antes do próximo.

> **Regra que não muda:** nenhum dado de demonstração vai para produção. O
> `seed_emulador/` tem uma trava que aborta fora do Emulator Suite, e o script
> de migração recusa rodar se `FIRESTORE_EMULATOR_HOST` estiver definida.

---

## Passo 0 — Autenticar (só você pode fazer)

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && ./test_rules/node_modules/.bin/firebase login
```

Confirme que o projeto correto aparece:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && ./test_rules/node_modules/.bin/firebase projects:list
```

**Se `nova-alianca-app` não estiver na lista, pare aqui.** Todo comando abaixo
usa `--project nova-alianca-app` explicitamente; se a CLI mostrar outro id,
interrompa antes de qualquer alteração.

---

## Passo 1 — Gerar a configuração do Firebase

```bash
dart pub global activate flutterfire_cli
```

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && flutterfire configure --project=nova-alianca-app --platforms=android,web
```

Isso gera/atualiza:

- `lib/firebase_options.dart` — **substitui o placeholder atual**;
- `android/app/google-services.json` — destrava o build Android real;
- registra o **app Web**, necessário para o painel.

Os três são ignorados pelo Git de propósito. Anote os valores do app Web
(`apiKey`, `appId`, `messagingSenderId`) — o painel os recebe por
`--dart-define` no passo 6.

Verifique:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && flutter analyze && flutter test
```

---

## Passo 2 — Índices

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && ./test_rules/node_modules/.bin/firebase deploy --only firestore:indexes --project nova-alianca-app
```

---

## Passo 3 — Cloud Functions administrativas

O Mercado Pago legado **não** é publicado: está em `functions/src/legacy/`,
fora do `tsconfig` e não exportado.

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP/functions" && npm ci && npm run build
```

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && ./test_rules/node_modules/.bin/firebase deploy --only functions --project nova-alianca-app
```

Funções publicadas: `meusAcessos`, `aprovarMembro`, `recusarMembro`,
`promoverParaLideranca`, `removerDaLideranca`, `desvincularDaIgreja`,
`atribuirFuncaoAdmin`, `removerFuncaoAdmin`, `criarIgreja`, `atualizarIgreja`.

> Requer plano **Blaze**. Se o deploy falhar por faturamento, ative o Blaze e
> repita — não há contorno.

---

## Passo 4 — Migração dos dados reais

**Primeiro em dry-run.** Nada é gravado e nada é apagado.

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && node scripts/migrar_producao.js --project=nova-alianca-app --dry-run
```

Confira o relatório de contagem. Preste atenção especial ao aviso
`revisar_valor=true` em transações: são registros sem valor reconhecível, que
a migração **não adivinha** — precisam de conferência manual.

Só então:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && node scripts/migrar_producao.js --project=nova-alianca-app --apply
```

O script é idempotente: reexecutar não duplica. As coleções antigas
**permanecem intactas** — não as apague até validar tudo.

Depois, conceda o superadministrador (UID vem do Console → Authentication):

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP/seed_emulador" && PERMITIR_PRODUCAO=1 GCLOUD_PROJECT=nova-alianca-app node bootstrap_super_admin.js --uid COLE_O_UID_AQUI
```

---

## Passo 5 — Regras

Publique **depois** da migração: as regras negam os caminhos globais antigos,
então os dados precisam já estar no lugar novo.

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && ./test_rules/node_modules/.bin/firebase deploy --only firestore:rules,storage --project nova-alianca-app
```

---

## Passo 6 — Painel no Hosting

Crie o target uma única vez (use um site próprio; **não sobrescreva** um
Hosting existente):

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && ./test_rules/node_modules/.bin/firebase hosting:sites:create painel-nova-alianca --project nova-alianca-app
```

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && ./test_rules/node_modules/.bin/firebase target:apply hosting painel painel-nova-alianca --project nova-alianca-app
```

Build de produção — substitua pelos valores do app Web do passo 1:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP/admin_web" && flutter build web --release --dart-define=APP_ENV=production --dart-define=FB_API_KEY=SEU_API_KEY --dart-define=FB_APP_ID=SEU_APP_ID --dart-define=FB_SENDER_ID=SEU_SENDER_ID --dart-define=FB_PROJECT_ID=nova-alianca-app
```

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && ./test_rules/node_modules/.bin/firebase deploy --only hosting:painel --project nova-alianca-app
```

Depois, no Console → Authentication → Settings → **Domínios autorizados**,
inclua o domínio do painel; sem isso o login falha.

Confirme que o build **não** aponta para o emulador:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && grep -c "demo-nova-alianca" admin_web/build/web/main.dart.js
```

O resultado precisa ser `0`.

---

## Passo 7 — APK

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && flutter build apk --release --dart-define=APP_ENV=production --dart-define=GESTAO_PANEL_URL=https://SEU_DOMINIO_DO_PAINEL --dart-define=MULTI_IGREJA=true
```

O AAB exige a keystore de produção (`android/key.properties`):

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && flutter build appbundle --release --dart-define=APP_ENV=production --dart-define=MULTI_IGREJA=true
```

SHA-256 do artefato:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && certutil -hashfile build/app/outputs/flutter-apk/app-release.apk SHA256
```

---

## Passo 8 — Validação pós-deploy

Com contas **reais** já existentes (não crie contas de demonstração):

- login e recuperação de senha;
- o pastor de Olinda vê apenas Olinda;
- Petrolina aparece vazia e "não configurada" — é o estado correto até os
  dados oficiais chegarem;
- dashboard, membros, liderança, avisos, programação, campanhas, ministérios,
  devocionais e oração;
- finanças visíveis para pastor/diácono/evangelista/líder/tesoureiro e
  bloqueadas para editor/moderador;
- publicar um aviso no painel e vê-lo no aplicativo da mesma igreja;
- acessar `/financas` pela URL com uma conta sem permissão → bloqueado;
- logout.

---

## Mercado Pago

**Permanece desativado.** Não solicite credenciais nesta etapa. Finanças são
somente leitura e `PAGAMENTOS_ONLINE` continua `false`. A integração segura
(OAuth por igreja, Secret Manager, webhook com validação de assinatura) é a
Fase 5.

---

## App Check

Prepare, mas **não force** antes da primeira validação: ativar o enforcement
antes de registrar o app derruba o acesso legítimo. Registre no Console,
observe as métricas em modo monitoramento e só então aplique.
