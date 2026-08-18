# Roteiro de conferência — fluxo multi-igreja

Confere no aparelho/emulador o que os testes automatizados **não** cobrem: o
toque na interface e a renderização de cada tela.

Nada aqui toca o Firebase real. Tudo roda contra `demo-nova-alianca`.

---

## 1. Subir o ambiente

```powershell
.\scripts\dev.ps1 -SemPainel
```

Sobe Auth, Firestore, Functions e Storage e aplica o seed (Olinda e Petrolina
ativas). Emulator UI: <http://127.0.0.1:4000>

Para subir também o painel web:

```powershell
.\scripts\dev.ps1
```

## 2. Rodar o aplicativo

**Emulador Android (AVD)** — o host `10.0.2.2` já é tratado automaticamente:

```powershell
flutter run --dart-define=APP_ENV=emulator --dart-define=MULTI_IGREJA=true
```

**Aparelho físico** — o celular precisa alcançar o seu computador na mesma
rede. Descubra o IP (`ipconfig`) e passe-o:

```powershell
flutter run --dart-define=APP_ENV=emulator --dart-define=MULTI_IGREJA=true --dart-define=EMULATOR_HOST=192.168.0.10
```

> Sem `EMULATOR_HOST`, um APK de emulador instalado em celular físico não
> encontra o Firestore e as listas ficam vazias.

Para apontar o botão do painel para algum lugar durante o teste:

```powershell
flutter run --dart-define=APP_ENV=emulator --dart-define=MULTI_IGREJA=true --dart-define=GESTAO_PANEL_URL=http://127.0.0.1:5555
```

---

## 3. O que conferir

### 3.1 Primeira abertura

- [ ] Instalação limpa (ou "Limpar dados") abre em **"Selecione uma igreja"**.
- [ ] A lista mostra **Olinda** e **Petrolina** vindas do Firestore.
- [ ] Escolher **Petrolina** → confirma → vai para **"Bem-vindo"**.
- [ ] O botão "voltar" no Bem-vindo **não** retorna à seleção (foi
      substituída, não empilhada).

### 3.2 Visitante em Petrolina

- [ ] "Continuar sem login" abre a Home.
- [ ] O cabeçalho mostra **Comunidade Nova Aliança Petrolina**.
- [ ] Avisos, programação e oração mostram conteúdo de Petrolina (o seed cria
      dados diferentes por unidade).
- [ ] "Conhecer a igreja" mostra endereço, horários e Instagram de Petrolina.
- [ ] **Contribuir → PIX**: Petrolina não tem chave cadastrada, então deve
      aparecer *"Contribuições ainda não configuradas para esta igreja"* —
      e **nunca** a chave de Olinda.

### 3.3 Persistência

- [ ] Fechar o app completamente e reabrir: continua em **Petrolina**, e não
      volta para a seleção.

### 3.4 Troca de unidade

- [ ] Configurações → "Igreja em foco" → escolher **Olinda**.
- [ ] Cabeçalho, avisos e programação passam a ser de Olinda.
- [ ] PIX de Olinda: a unidade tem chave no seed? Se não tiver, o bloqueio
      honesto também aparece aqui — não é bug.

### 3.5 Cadastro

- [ ] Bem-vindo → Entrar → Criar conta.
- [ ] O topo do formulário mostra a igreja escolhida.
- [ ] Preencher nome, e-mail e telefone; tocar em **"Trocar"**.
- [ ] Escolher outra igreja e confirmar → **volta ao mesmo formulário com os
      campos ainda preenchidos** (este era o bug: mandava para o Bem-vindo).
- [ ] Concluir o cadastro → cai em "Aguardando aprovação".
- [ ] No Emulator UI, conferir que existem os dois documentos:
      `usuarios/{uid}` e `igrejas/{igrejaEscolhida}/membros/{uid}` com
      `status: pendente`.

### 3.6 Login e permissões

Contas do seed, senha `Teste123!`:

- [ ] `pastor.olinda@teste.local` entra e a Home abre em **Olinda**, mesmo que
      você estivesse visitando Petrolina antes do login.
- [ ] Aparece o menu de liderança e o card **"Abrir painel de gestão"**.
- [ ] Trocar para Petrolina: o menu de liderança **some** e o card do painel
      **some** — visitar não transfere permissão.
- [ ] "Voltar para minha igreja" restaura Olinda e as permissões.
- [ ] `membro@teste.local` (pendente) → tela de aguardando aprovação.
- [ ] Um membro aprovado comum **não** vê o card do painel.

### 3.7 Transferência OFICIAL de vínculo (painel → aplicativo)

Diferente de tudo acima: aqui a pessoa **muda de igreja principal**, e não
apenas de igreja visualizada. A ação existe só para `super_admin`.

No painel (`admin_web`), logado com uma conta `super_admin`:

- [ ] Menu **Liderança** → cartão de um membro aprovado de Olinda.
- [ ] O botão **"Transferir para outra igreja"** aparece. Entrando com pastor
      da unidade (sem `super_admin`), o botão **não** aparece.
- [ ] O diálogo mostra a igreja atual, a lista de destinos (sem a própria
      unidade) e o aviso de que cargos e permissões não são transportados.
- [ ] Confirmar só habilita com destino, motivo e o aceite marcados.
- [ ] Concluir → mensagem de sucesso.

No Emulator UI, conferir:

- [ ] `igrejas/olinda/membros/{uid}` → `status: inativo`, `funcoes_admin: []`,
      `transferido_para: petrolina`. O documento **continua existindo**.
- [ ] `igrejas/petrolina/membros/{uid}` → `status: aprovado`,
      `perfil: membro`, `funcoes_admin: []`.
- [ ] `usuarios/{uid}.igreja_principal_id` → `petrolina`.
- [ ] `igrejas/olinda/auditoria` e `igrejas/petrolina/auditoria` têm um
      registro `transferir_vinculo_igreja` cada, com autor e motivo.

No aplicativo, com a conta transferida:

- [ ] Sair e entrar de novo: a Home abre em **Petrolina**.
- [ ] Se a pessoa era liderança em Olinda, **não** tem menu de liderança em
      Petrolina nem em Olinda.
- [ ] Visualizar Olinda mostra o conteúdo público, sem permissões.

---

## 4. O que os testes automatizados já cobrem

Não precisa reconferir manualmente:

| Suíte | O que garante |
|---|---|
| `test/fluxo_onboarding_test.dart` | primeira abertura, persistência, reinício, troca de escopo, visitante sem permissão |
| `test/multi_igreja_test.dart` | vínculo de Olinda que não vale em Petrolina, PIX ausente, mapa da unidade certa |
| `test_rules/cadastro.test.js` | o cadastro é aceito pelas Rules reais e o formato antigo é negado |
| `test/responsivo_app_test.dart` | ausência de overflow em 320→1440 px, textScale 1.0 e 1.3 |
| `functions/test/transferencia.test.js` | transferência oficial: autorização, atomicidade, idempotência, auditoria nas duas unidades |
| `admin_web/test/transferencia_test.dart` | o botão só existe para `super_admin`, e o que o diálogo envia ao servidor |

```powershell
flutter analyze
flutter test
cd admin_web; flutter test; cd ..
cd packages\nova_alianca_core; dart test; cd ..\..
cd test_rules; npm test; cd ..
cd functions; npm test; cd ..
```
