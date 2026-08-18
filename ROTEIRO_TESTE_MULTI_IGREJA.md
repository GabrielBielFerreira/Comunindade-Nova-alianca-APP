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

---

## 4. O que os testes automatizados já cobrem

Não precisa reconferir manualmente:

| Suíte | O que garante |
|---|---|
| `test/fluxo_onboarding_test.dart` | primeira abertura, persistência, reinício, troca de escopo, visitante sem permissão |
| `test/multi_igreja_test.dart` | vínculo de Olinda que não vale em Petrolina, PIX ausente, mapa da unidade certa |
| `test_rules/cadastro.test.js` | o cadastro é aceito pelas Rules reais e o formato antigo é negado |
| `test/responsivo_app_test.dart` | ausência de overflow em 320→1440 px, textScale 1.0 e 1.3 |

```powershell
flutter analyze
flutter test
cd admin_web; flutter test; cd ..
cd packages\nova_alianca_core; dart test; cd ..\..
cd test_rules; npm test; cd ..
```
