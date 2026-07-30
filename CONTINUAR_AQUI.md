# CONTINUAR_AQUI — Handoff do Comunidade Nova Aliança App

> Documento para retomar o desenvolvimento numa nova janela do Claude Code, sem
> perder contexto. Leia inteiro antes de alterar. **Não recrie o Firebase nem
> remova avanços.**

## 1. Onde está tudo
- **Projeto (working dir):** `C:\Users\User\Desktop\Jailton\Claude Cod\CNA APP\Comunindade-Nova-alianca-APP-main`
- **Flutter:** instalado em `C:\flutter\bin` (use `C:\flutter\bin\flutter.bat`). Flutter 3.44.8, Dart 3.12.
- **Firebase CLI:** instalado via npm (`%APPDATA%\npm\firebase.cmd`), já logado.
- **Git:** repositório ativo (~31 commits). **Commite cada incremento.**
- **APK de teste:** `flutter build apk --debug` → copie para `C:\Users\User\Desktop\NovaAlianca-teste.apk`.

## 2. Firebase (JÁ CONFIGURADO — não recriar)
- Projeto: **`nova-alianca-app`** (plano **Blaze**), região `southamerica-east1`.
- `lib/firebase_options.dart` e `android/app/google-services.json` existem (não versionados; não substituir).
- Regras em `firestore.rules` — **publicadas**. Deploy: 
  `firebase deploy --only firestore:rules --project=nova-alianca-app`
- Coleções em uso: `usuarios`, `pedidos_oracao`, `avisos`, `eventos`, `notificacoes`,
  `tokens_dispositivo`, `ministerios`, `devocionais`, `interesses_ministerio`,
  `auditoria`, `configuracoes`.
- **Administradores (líderes):** `jailtonmjc@gmail.com` e `gabrielbiel.ferreira0411@gmail.com`.
  Promover = no Firestore `usuarios/{uid}`: `perfil="lider"`, `status="aprovado"`
  (ou `seed/promover_lideres.js` com `serviceAccountKey.json`).
- **Seed de dados de exemplo:** `cd seed && node seed.js` (precisa de `seed/serviceAccountKey.json`;
  Console Firebase → Contas de serviço → Gerar chave). `node seed.js --limpar` remove.

## 3. Arquitetura (resumo)
- **Entrypoint:** `lib/main.dart` → `MaterialApp` (rota `/` = `RootGate`) + `navigatorKey`.
- **RootGate** (`lib/app/root_gate.dart`): decide tela por sessão/perfil (Welcome / Aguardando
  aprovação / Conta inativa / Home membro / Home líder). Inicia FCM pós-login.
- **Rotas:** `lib/visual/visual_router.dart` — `VisualRoutes` (constantes) + mapa `visualRoutes`.
  Telas de conteúdo navegam por `Navigator.pushNamed`.
- **Estado:** Riverpod. Padrão por feature: `lib/features/<feature>/data` (model+repository),
  `.../providers`, `.../screens`.
- **Config/flags:** `lib/core/config/app_config.dart` (dart-define): `MULTI_IGREJA`,
  `PAGAMENTOS_ONLINE`, `ESCOLA_LOUVOR`, `GESTAO_PANEL_URL`, `BIBLE_*`.
- **Telas visuais aprovadas:** `lib/visual/screens` — **preservar o visual**; só ajustar função.

## 4. Decisões OFICIAIS (não violar)
- App exclusivo da CNA na V1. **Sem células** (removidas). Segmentar por ministério/grupo.
- Tema claro; vinho `#7A0022`; fundo `#FAFAFA`; Montserrat (títulos) + Inter (texto).
  **Sem dourado, sem dark mode.** Não redesenhar telas aprovadas.
- Gestão = porta para painel externo (`url_launcher`, URL via `GESTAO_PANEL_URL`).
- Bíblia/Cantor/Devocionais/Escola de Louvor = seção "Palavra e Louvor" (Bíblia NÃO na nav inferior).
- **Critério final:** nenhum elemento visível sem ação — ao tocar, deve abrir função real,
  mostrar estado adequado (loading/vazio/erro) ou **não aparecer** (feature flag).
- Pagamentos: nunca segredos no app; confirmação só por webhook; PIX manual honesto até backend.
- Bíblia: João Ferreira de Almeida (domínio público) via bible-api.com (sem chave). Não inventar versículos.
- Cantor Cristão: só conteúdo AUTORIZADO em `assets/hinos/cantor_cristao.json` (formato em `.exemplo.json`). Não inventar letras.

## 5. Fluxo de trabalho por item (OBRIGATÓRIO)
1. Implementar a alteração (preservando visual).
2. `& "C:\flutter\bin\flutter.bat" analyze`  → **0 erros** (corrigir warnings).
3. `& "C:\flutter\bin\flutter.bat" test`      → 45+ testes passando.
4. Se mexeu em regras: `firebase deploy --only firestore:rules --project=nova-alianca-app`.
5. `& "C:\flutter\bin\flutter.bat" build apk --debug` → copiar para `Desktop\NovaAlianca-teste.apk`.
6. `git add -A && git commit` (mensagem clara do item).
7. Avisar o usuário para testar.

## 6. Progresso na lista de 17 itens
**Concluídos e testados:** 1 (identidade real), 2 (cadastros pendentes + auditoria),
5 (Palavra do Dia unificada), 6 (moderação de oração — `aprovado`), 7 (Home:
"Vida na Comunidade" + "Palavra e Louvor"), 8 (Meu Ministério), 9 (Devocionais),
10 (Escola de Louvor por feature flag), 11 (Próximo Culto do Firestore),
13 (badge real no sino), 16 (termos desmarcados), **17 parcial** (share/mapa reais
em detalhes; mensagens "futuramente" removidas da navegação/calendário).
- Item 3 (Bíblia): funcional. Item 4 (Cantor): pronto, aguarda JSON autorizado.

**FALTAM:**
- **Item 12** — Avisos/Programação: revisar índices/regras/consultas, remover dados/datas
  fixas remanescentes, garantir tempo real, detalhes, loading/vazio/erro (grande parte já feita
  no wiring; validar e afinar).
- **Item 14** — Menu "Mais" (ícone ☰ na Home, hoje SEM ação): abrir menu com Sobre a
  Comunidade, Bíblia, Cantor Cristão, Devocionais, Escola de Louvor (se flag), Configurações,
  Ajuda; para liderança acrescentar Cadastros pendentes, Moderação de oração e Gestão.
  Itens inexistentes não aparecem. (O ☰ está em `lib/visual/screens/home_screen.dart` `_TopBar`,
  `_TopIconButton(asset: HomeAssets.menu)` — atualmente `onTap` nulo = controle morto a resolver.)
- **Item 15** — Contribuições/Campanhas: "Apoiar campanha" abre detalhes → contribuição com
  `campanhaId`; PIX manual com QR válido + copia-e-cola (chave `IgrejaInfo.pixChave`); não simular
  confirmação; cartão/boleto ocultos/indisponíveis sem backend (Functions em `functions/` já
  escaffoldadas, flag `PAGAMENTOS_ONLINE`). Remover os "será conectado futuramente" restantes
  (estão em `contribuir_screen.dart`, `pagamento_*_screen.dart`, `configuracoes_screen.dart`,
  `historico_contribuicoes_screen.dart`, `status_contribuicao_screen.dart`, `visualizar_outra_igreja_screen.dart`).

## 7. Pendências externas
- Conteúdo autorizado do Cantor Cristão (`assets/hinos/cantor_cristao.json`).
- Deploy das Cloud Functions do Mercado Pago (`functions/`) + credenciais MP + flag `PAGAMENTOS_ONLINE`.
- Storage para foto de perfil (Blaze já ativo; falta habilitar bucket + regras `storage.rules`).
- Rodar `seed/seed.js` para popular Avisos/Programação/Ministérios/Devocionais (opcional, para testes).

## 8. Conclusão atual: ~92% da V1.
