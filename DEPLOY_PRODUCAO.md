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

### Trava fail-closed (obrigatória antes de qualquer build de produção)

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && node scripts/verificar_producao.js --app
```

O comando **reprova** (saída 1) quando `lib/firebase_options.dart` ainda é o
placeholder, quando `android/app/google-services.json` falta ou aponta para
outro projeto, ou quando o pacote Android não confere. Enquanto ele reprovar,
nenhum artefato gerado é de produção — mesmo que o comando de build diga
`--release`.

Depois de construir, valide o artefato:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && node scripts/verificar_producao.js --artefato build/app/outputs/flutter-apk/app-release.apk
```

> Num APK as strings ficam comprimidas dentro do zip, então a *ausência* de
> `demo-nova-alianca` não prova nada. O que decide é a checagem positiva: o
> artefato precisa referenciar `nova-alianca-app`. Para o painel
> (`main.dart.js`, texto puro) as duas direções são confiáveis.

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
`atribuirFuncaoAdmin`, `removerFuncaoAdmin`, `transferirVinculoIgreja`,
`criarIgreja`, `atualizarIgreja`.

> Requer plano **Blaze**. Se o deploy falhar por faturamento, ative o Blaze e
> repita — não há contorno.

---

## Passo 4 — Migração dos dados reais

**Primeiro em dry-run.** Nada é gravado e nada é apagado.

Instale a dependência travada do script (ela é separada das Functions para o
comando funcionar também em um checkout limpo):

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && npm --prefix scripts ci
```

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && node scripts/migrar_producao.js --project=nova-alianca-app --dry-run
```

O preflight imprime apenas contagens e **nomes de campos**, nunca valores,
e-mails, tokens ou UIDs. Ele aborta antes da primeira escrita quando Olinda,
Petrolina ou um documento de catálogo existente divergem do contrato. Confira
o relatório e preste atenção especial ao aviso
`revisar_valor=true` em transações: são registros sem valor reconhecível, que
a migração **não adivinha** — precisam de conferência manual.

Cada documento global de `tokens_dispositivo` é planejado para
`usuarios/{uid}/tokens_dispositivo/{id}` a partir de `perfil_id`, preservando o
contrato privado e acrescentando apenas a proveniência da migração. UID inválido
ou destino divergente bloqueia tudo sem imprimir UID ou token. A coleção global
`configuracoes` ainda não tem contrato de destino e, portanto, deve estar
**vazia**; qualquer documento encontrado aborta o preflight. As duas coleções
participam das guardas transacionais, inclusive contra inserções phantom.

Antes de autorizar `--apply`, confirme também que as Rules **já publicadas**
continuam negando anonimamente o documento operacional e sua listagem:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && node scripts/verificar_catalogo_publico.js --project=nova-alianca-app --preflight-privacidade
```

Os dois resultados devem ser HTTP 403. Qualquer 200 ou 404 bloqueia a
migração, pois indicaria que `/igrejas` pode estar público. Em 2026-08-19 esse
preflight real retornou 403 tanto para `igrejas/olinda` quanto para a query sem
filtro; nenhuma escrita foi feita.

O catálogo do primeiro acesso é fisicamente separado:

```text
catalogo_igrejas/{igrejaId}
  nome: string
  ativa: bool
  configurada: bool
  endereco: string | null
  cidade_estado: string | null
  endereco_secundario: string | null
  slogan: string | null
  cultos_recorrentes: string[]
  instagram: string | null
  youtube_url: string | null
  pastores_publicos: string[]
```

Esses são os onze campos públicos permitidos. As listas contêm somente strings
sanitizadas; para unidades legadas, `pastor_responsavel` pode preencher
`pastores_publicos` apenas quando a lista pública estiver vazia, sem publicar o
nome do campo legado. `/igrejas/{igrejaId}` continua operacional e privado.
`responsavel_administrativo_uid`, telefone, PIX, CEP, slug, Mercado Pago,
autores, timestamps e metadados `migrado_*` nunca são copiados para o catálogo.

Só então:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && node scripts/migrar_producao.js --project=nova-alianca-app --apply
```

No `--apply`, o script relê todas as consultas de origem e todos os destinos
dentro de uma única **transação Firestore**. Antes de chamar `create` ou
`update`, ele compara membership, conteúdo e `updateTime` com o preflight; uma
inserção phantom ou qualquer drift concorrente aborta a transação inteira. O
limite é 450 operações e não há `delete`. Depois do commit, uma segunda
transação de verificação, sem escritas, refaz o planejamento e exige **zero
operações**.

O script é idempotente: reexecutar não duplica. Se a pós-verificação acusar
novo trabalho, o commit anterior pode já ter sido concluído; não aplique às
cegas — rode o dry-run novamente e confira o drift. As coleções antigas
**permanecem intactas** — não as apague até validar tudo.

Depois, conceda o superadministrador (UID vem do Console → Authentication):

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP/seed_emulador" && PERMITIR_PRODUCAO=1 GCLOUD_PROJECT=nova-alianca-app node bootstrap_super_admin.js --uid COLE_O_UID_AQUI
```

---

## Passo 5 — Regras

Publique **depois** da migração: as regras negam os caminhos globais antigos,
então os dados precisam já estar no lugar novo. Elas também fecham a leitura
pública do documento operacional `/igrejas/{id}` e liberam somente a consulta
`catalogo_igrejas.where(ativa == true)`; publicar antes de existir ao menos uma
entrada ativa trocaria o erro 403 por uma lista vazia.

Antes do deploy, anote no Console o identificador da versão de Rules vigente.
Ela só é um rollback aceitável porque o preflight acima comprovou que nega
`/igrejas`; não use como rollback o commit Git intermediário que continha
`allow read: if true` nesse documento operacional.

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
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP/admin_web" && flutter build web --release --dart-define=APP_ENV=production --dart-define=FB_API_KEY=SEU_API_KEY --dart-define=FB_APP_ID=SEU_APP_ID --dart-define=FB_SENDER_ID=SEU_SENDER_ID --dart-define=FB_PROJECT_ID=nova-alianca-app --dart-define=FB_AUTH_DOMAIN=nova-alianca-app.firebaseapp.com --dart-define=FB_STORAGE_BUCKET=SEU_STORAGE_BUCKET
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

O build também precisa conter, com resposta pública sem login, as páginas:

- `/privacidade`;
- `/excluir-conta`;
- `/termos`.

Os textos versionados descrevem tecnicamente o comportamento atual, mas a
aprovação jurídica e a definição dos prazos de retenção continuam sendo uma
pendência de publicação nas lojas.

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

Comece pelo canário **sem autenticação**. Ele reprova se não houver HTTP 200,
ao menos uma unidade ativa ou se aparecer qualquer campo fora da allowlist.
Ele também exige HTTP 403 para `/igrejas/olinda`, para a query pública sem
filtro e para o catálogo inativo de Petrolina:

```bash
cd "C:/Users/Jean/Downloads/CNA APP atualizado/Comunindade-Nova-alianca-APP" && node scripts/verificar_catalogo_publico.js --project=nova-alianca-app
```

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

---

# Registro da execução real (2026-08-18)

Esta seção não é teoria: é o que aconteceu ao executar o runbook contra
`nova-alianca-app`, incluindo o que falhou e por quê.

## Concluído

| Passo | Resultado |
|---|---|
| Login da CLI | `jailtonmjc@gmail.com`, acesso confirmado a `nova-alianca-app` (335786267314) |
| App Web | **Criado** pelo flutterfire: `1:335786267314:web:3d2d2b8cc95ce0466cafab` |
| App Android | **Reutilizado**, não duplicado: `1:335786267314:android:ff524d79e2c9c4296cafab` |
| `lib/firebase_options.dart` | Gerado, real, aponta para `nova-alianca-app` |
| `android/app/google-services.json` | Gerado, real, pacote `br.com.novaalianca.nova_alianca_app` |
| `.firebaserc` | Projeto padrão + target de Hosting `painel` → site `nova-alianca-app` |
| Índices do Firestore | **Publicados** |
| Painel | **Publicado** em <https://nova-alianca-app.web.app> (HTTP 200) |

### Índices: por que nada foi apagado

O deploy pediu `--force` porque havia **1 índice no projeto que não estava no
repositório**: `eventos(ativo ASC, data_inicio ASC)`.

`--force` teria **apagado** esse índice. Em vez disso ele foi acrescentado a
`firestore.indexes.json`, e o deploy correu sem `--force`. O motivo: um índice
de escopo `COLLECTION` vale para **toda** coleção com aquele nome — inclusive
`igrejas/{id}/eventos`. Ele não era só legado.

## Bloqueado — precisa de ação no Google Cloud

### 1. Cloud Functions: `iam.serviceaccounts.actAs` negado

O deploy habilitou as APIs e chegou a criar as funções, mas as 11 falharam com:

```text
HTTP Error: 403, Could not create Cloud Run service ...
Permission 'iam.serviceaccounts.actAs' denied on service account
335786267314-compute@developer.gserviceaccount.com (or it may not exist).
```

Causa mais provável: **a API do Compute Engine nunca foi habilitada**, e a
conta de serviço padrão do Compute (que o Cloud Functions v2 usa como
identidade de execução, porque roda sobre Cloud Run) só é criada quando essa
API é ativada.

Como resolver, no Console:

1. Abra
   <https://console.cloud.google.com/apis/library/compute.googleapis.com?project=nova-alianca-app>
   e clique em **Ativar**.
2. Espere 1–2 minutos: a conta
   `335786267314-compute@developer.gserviceaccount.com` é criada nesse
   intervalo.
3. Confirme em
   <https://console.cloud.google.com/iam-admin/serviceaccounts?project=nova-alianca-app>
   que ela aparece na lista.
4. Se ela existir e o erro persistir, o problema é permissão do usuário que
   faz o deploy: em **IAM**, conceda a `jailtonmjc@gmail.com` o papel
   **Usuário da conta de serviço** (`roles/iam.serviceAccountUser`).

Depois disso o deploy é retomado normalmente:

```bash
node test_rules/node_modules/firebase-tools/lib/bin/firebase.js deploy --only functions --project nova-alianca-app
```

Nada ficou meio-criado: `functions:list` devolve vazio, e nenhum repositório
`gcf-artifacts` foi criado no Artifact Registry — ou seja, o aviso de
"imagens de build" que apareceu no fim do deploy não deixou custo nenhum.

> A política de limpeza de artefatos (`functions:artifacts:setpolicy --days 1
> --location southamerica-east1`) só pode ser aplicada **depois** do primeiro
> deploy bem-sucedido: antes disso o repositório não existe.

### 2. Migração: falta credencial de aplicação

`scripts/migrar_producao.js` usa o Admin SDK e exige
`GOOGLE_APPLICATION_CREDENTIALS` ou Application Default Credentials. O login
da Firebase CLI **não** serve para isso.

O caminho recomendado (não versiona chave nenhuma):

1. Instale o Google Cloud CLI:
   <https://cloud.google.com/sdk/docs/install>
2. Rode, em um terminal seu:

   ```bash
   gcloud auth application-default login
   ```

3. Confirme o projeto:

   ```bash
   gcloud config set project nova-alianca-app
   ```

A alternativa é baixar uma chave de service account e apontar
`GOOGLE_APPLICATION_CREDENTIALS` para ela — mas aí o arquivo fica no disco e
**não pode** entrar no Git. O `gcloud auth application-default login` evita
isso.

Enquanto a migração não roda, as **Rules novas não podem ser publicadas**: elas
negam os caminhos globais antigos, e publicá-las antes da migração deixaria o
aplicativo sem dados.

### Auditoria P0 do primeiro acesso (2026-08-19)

Uma consulta administrativa somente leitura confirmou que a coleção
`/igrejas` real ainda tem **0 documentos**. As coleções globais antigas têm
conteúdo, mas não existe raiz nem catálogo para o onboarding. Logo:

- publicar somente Rules não resolve o incidente;
- a migração precisa criar `igrejas/olinda` e o catálogo sanitizado;
- `--apply` e deploy continuam proibidos até o dry-run com ADC e o checkpoint;
- a consulta anônima só é canário válido depois da publicação das Rules.

## Ordem restante

1. Habilitar a API do Compute Engine (você).
2. Publicar as Functions.
3. Aplicar a política de limpeza de artefatos.
4. `gcloud auth application-default login` (você).
5. Migração em `--dry-run` e conferência do relatório.
6. Preflight anônimo de privacidade (dois HTTP 403) e registro da versão de
   Rules vigente.
7. Migração `--apply` após sua autorização.
8. Superadministrador (preciso do UID).
9. Firestore Rules e Storage Rules finais.
10. Canário anônimo positivo e negativo.
11. Republicar o painel se algo mudar e refazer o smoke test.

## Rollback

| O que | Como voltar |
|---|---|
| **Painel (Hosting)** | Console → Hosting → aba **Versões** → **Reverter** para a versão anterior. Ou `firebase hosting:rollback --project nova-alianca-app`. O site anterior era um 404, então reverter devolve o 404. |
| **Índices** | `firestore.indexes.json` no Git tem o estado publicado. Índice a mais não quebra consulta nenhuma; para remover, edite o arquivo e rode o deploy com `--force` (ciente de que apaga). |
| **Functions** | Ainda não publicadas. Depois de publicadas: `firebase functions:delete <nome> --region southamerica-east1 --project nova-alianca-app`. |
| **Migração** | A migração **não apaga nada**: as coleções globais antigas continuam intactas. Não exponha nem apague `igrejas/*` para “reverter”; interrompa clientes novos e avalie os dados no checkpoint. |
| **Rules** | Console → Firestore → Regras → histórico de versões. Reverta somente para a versão vigente anotada e previamente comprovada pelo canário como HTTP 403 em `/igrejas`; nunca para a Rule Git intermediária com leitura pública do root. |
| **Configuração local** | `lib/firebase_options.dart` e `android/app/google-services.json` **não são versionados**. Para voltar ao emulador basta usar `--dart-define=APP_ENV=emulator`; para regerar, rode o flutterfire de novo. |
