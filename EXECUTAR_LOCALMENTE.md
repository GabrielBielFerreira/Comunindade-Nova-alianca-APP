# Executar o painel localmente (Emulator Suite)

Tudo roda contra o projeto de demonstração `demo-nova-alianca`. **Nada toca
produção.** Não é necessário ter credenciais reais do Firebase.

## Pré-requisitos

- Flutter 3.41+ e Node 20 no PATH.
- Java (o emulador do Firestore roda em JVM).
- Nenhuma instalação global: o `firebase-tools` fica em `test_rules/node_modules`.

## Comando único

```powershell
.\scripts\dev.ps1
```

Esse script, em ordem:

1. libera portas de emulador ocupadas por processos órfãos — encerra **apenas**
   processos comprovadamente do Firebase; se houver outro processo na porta,
   ele para e avisa em vez de matar;
2. instala dependências que faltarem (`test_rules`, `functions`, `seed_emulador`);
3. compila as Cloud Functions (`npm run build`);
4. sobe Auth, Firestore, Functions e Storage;
5. espera os emuladores **responderem HTTP** (porta em LISTEN não basta: o
   Firestore aceita a conexão antes de servir gRPC e o seed morre com
   `DEADLINE_EXCEEDED`);
6. aplica o seed de demonstração;
7. abre o painel no Chrome (`flutter run -d chrome --web-port 5555`).

Variações:

```powershell
.\scripts\dev.ps1 -SemSeed     # mantém os dados já criados
.\scripts\dev.ps1 -SemPainel   # só emuladores + seed
```

Emulator UI: <http://127.0.0.1:4000>

## Passo a passo manual

```powershell
# 1. Compilar as Functions
cd functions; npm install; npm run build; cd ..

# 2. Emuladores
.\test_rules\node_modules\.bin\firebase.cmd emulators:start `
  --only auth,firestore,functions --project demo-nova-alianca

# 3. Seed (em outro terminal)
cd seed_emulador; npm install
$env:FIRESTORE_EMULATOR_HOST     = "127.0.0.1:8080"
$env:FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"
$env:GCLOUD_PROJECT              = "demo-nova-alianca"
node seed_emulador.js

# 4. Painel
cd ..\admin_web; flutter run -d chrome --web-port 5555
```

Alternativa sem `flutter run` (usa o build já compilado):

```powershell
cd admin_web; flutter build web; cd ..
node scripts/servir_painel.js 5555   # http://127.0.0.1:5555
```

## Contas de teste

Todas com a senha **`Teste123!`**, domínio `@teste.local`, existentes
**apenas no emulador**. O `seed_emulador/guarda.js` aborta a execução se as
variáveis de emulador não estiverem definidas ou se o projeto não começar com
`demo-`.

| Conta | Papel | O que demonstra |
|---|---|---|
| `superadmin@teste.local` | super_admin (custom claim) | Vê Olinda **e** Petrolina; seletor de igreja aparece |
| `pastor.olinda@teste.local` | Pastor de Olinda | Menu Liderança; finanças de Olinda; **não** vê Petrolina |
| `diacono.olinda@teste.local` | Diácono de Olinda | Finanças; **sem** menu Liderança |
| `evangelista.olinda@teste.local` | Evangelista de Olinda | Finanças; **sem** menu Liderança |
| `lider.olinda@teste.local` | Líder de Olinda | Finanças; **não** remove outro líder |
| `lider2.olinda@teste.local` | Líder de Olinda | Alvo do rebaixamento |
| `tesoureiro.olinda@teste.local` | Membro + tesoureiro | Finanças **sem** ser liderança ministerial |
| `editor.olinda@teste.local` | Membro + editor | Painel **sem** finanças |
| `moderador.olinda@teste.local` | Membro + moderador | Painel **sem** finanças |
| `pastor.petrolina@teste.local` | Pastor de Petrolina | Só Petrolina; isolamento |
| `membro@teste.local` | Membro pendente | Tela de **acesso negado** |

Olinda e Petrolina recebem valores financeiros **diferentes** de propósito: se
o painel misturasse unidades, o total mudaria de forma visível.

## super_admin

Nenhum UID fica fixo no código. Para conceder a claim:

```powershell
cd seed_emulador
node bootstrap_super_admin.js --email pessoa@exemplo.com
node bootstrap_super_admin.js --uid <UID>
node bootstrap_super_admin.js --uid <UID> --remover
```

Contra projeto real exige `PERMITIR_PRODUCAO=1` + `GOOGLE_APPLICATION_CREDENTIALS`
explícitos. A claim só vale no próximo token (logout/login).

## Testes

```powershell
# Domínio compartilhado (62 testes)
cd packages\nova_alianca_core; dart test

# Rules no emulador (74 testes) — o pretest libera a 8080 se necessário
cd test_rules; npm test

# Build das Functions
cd functions; npm run build

# Painel (18 testes)
cd admin_web; flutter analyze; flutter test

# Aplicativo móvel (79 testes)
flutter test

# Aceite ponta a ponta (28 verificações) — exige emuladores + seed
cd seed_emulador; node verificar_aceite.js
```

## Problemas conhecidos

**`Could not start Firestore Emulator, port taken`** — no Windows o
`emulators:exec` encerra o hub mas o processo Java do Firestore sobrevive ao
SIGINT. O `test_rules/preflight.js` (rodado no `pretest`) encerra apenas esse
processo; se a porta estiver com outro programa, ele preserva e avisa.

**`DEADLINE_EXCEEDED ... Waiting for LB pick` no seed** — o emulador ainda não
está servindo gRPC. Espere-o responder em HTTP antes de semear; o `dev.ps1` já
faz isso.
