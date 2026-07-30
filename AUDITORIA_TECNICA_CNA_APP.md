# Auditoria Técnica — Comunidade Nova Aliança App

> Auditoria do estado **original** (baseline extraído do ZIP) e classificação de
> cada tela/feature. As correções aplicadas nesta entrega estão em
> `STATUS_FINAL_CNA_APP.md`. Evidências referenciam caminhos de arquivos.

## 1. Resumo executivo (estado original)

O projeto era um **protótipo com dois aplicativos paralelos e desconectados**:

- **App visual** (`lib/main_visual.dart` → `visual/visual_app.dart` →
  `visual_router.dart`): `MaterialApp` simples, **sem Firebase, sem Riverpod, sem
  auth**. 33 telas reais e aprovadas (~18k linhas), alimentadas por **mocks**
  (235 ocorrências de `mock`), navegando por `Navigator.pushNamed` (**97 chamadas**).
  Login com **credenciais fixas** (`membro@cna.app`/`lider@cna.app`/`123456`).
- **App de produção** (`lib/main.dart` ≡ `lib/main_producao.dart` →
  `core/router/app_router.dart`): GoRouter + Riverpod + redirect por status bem
  estruturado, ligado ao Firebase Auth — mas **as 18 rotas renderizavam
  `PlaceholderTela`** ("Em desenvolvimento").

**Estimativa de conclusão real (baseline):** UI ~85% pronta; **produto funcional
~15–20%**. A arquitetura de auth existia sem telas; as features estavam em mock;
não havia backend configurável nem build assinável.

## 2. Matriz de telas/funcionalidades (estado original)

Legenda: ✅ funcional · 🎨 visual sem integração · 🟡 parcial · 🧪 mock/simulado ·
❌ ausente · ⛔ quebrado/fake · 🔗 depende de recurso externo

| Área | Arquivo | Estado original |
|---|---|---|
| Entrypoint produção | `main.dart`/`main_producao.dart` | ⛔ só placeholders (duplicado) |
| Entrypoint visual | `main_visual.dart` | 🎨 telas reais, sem backend |
| Login | `visual/screens/entraconta_screen.dart` | ⛔ credenciais fixas, sem Auth |
| Cadastro | `cadastro_screen.dart` | 🧪 só valida localmente |
| Recuperar senha | `recuperar_senha_screen.dart` | ⛔ só navega p/ "email enviado" |
| E-mail enviado | `email_enviado_screen.dart` | 🎨 |
| Welcome/Acesso | `welcome_access_screen.dart` | 🎨 entrar/visitante |
| Seleção de igreja | `select_church_screen.dart` | 🎨 (multi-igreja) |
| Home membro | `home_screen.dart` / `home_member_screen.dart` | 🧪 mock |
| Home liderança | `home_leader_screen.dart` | 🧪 mock |
| Home visitante | `home_visitante_screen.dart` | 🧪 mock |
| Avisos | `avisos_screen.dart` | 🧪 mock |
| Detalhe de aviso | `aviso_detalhes_screen.dart` | 🧪 mock |
| Programação | `programacao_screen.dart` | 🧪 mock |
| Detalhe programação | `programacao_detalhes_screen.dart` | 🧪 mock |
| Oração (mural/pedidos) | `oracao_screen.dart`, `mural_oracao_screen.dart`, `oracao_*_pedido_*` | 🧪 mock |
| Notificações (sino) | `notificacoes_screen.dart` | 🧪 mock, não integrada |
| Contribuir | `contribuir_screen.dart` | 🧪 mock |
| Revisar contribuição | `revisar_contribuicao_screen.dart` | 🧪 mock |
| Pagamento PIX | `pagamento_pix_screen.dart` | 🧪 mock |
| Pagamento cartão/boleto | `pagamento_cartao_screen.dart`, `pagamento_boleto_screen.dart` | 🎨 stub 🔗 |
| Pagamento externo | `pagamento_externo_screen.dart` | 🎨 🔗 |
| Status contribuição | `status_contribuicao_screen.dart` | 🧪 mock |
| Histórico | `historico_contribuicoes_screen.dart` | 🧪 mock |
| Perfil | `perfil_screen.dart` | 🧪 mock; logout ⛔ fake |
| Dados pessoais | `dados_pessoais_screen.dart` | 🧪 estado local, não persiste |
| Configurações | `configuracoes_screen.dart` | 🎨 |
| Gestão | `gestao_entry_screen.dart` | ⛔ botão "será conectado futuramente" |
| Bíblia | — | ❌ não localizada tela funcional |
| Firebase (options/rules/json) | — | ❌ ausentes |
| FCM | `core/services/fcm_service.dart` | 🟡 esqueleto, nunca inicializado |
| Testes | `test/widget_test.dart` | ⛔ `expect(true, isTrue)` |
| Assinatura release | `android/app/build.gradle.kts` | ⛔ chave de debug |

## 3. Problemas por severidade (baseline)

### P0 — compilação/execução/segurança/entrega
1. Dois apps desconectados; produção só com `PlaceholderTela` (18×).
2. Login hardcoded (`entraconta_screen.dart:25-27,72-83`), autofill + logo-tap.
3. Firebase não configurável: sem `firebase_options.dart`, sem plugin
   `com.google.gms.google-services`, sem `google-services.json`.
4. Release assinado com chave de debug (`build.gradle.kts:37`).
5. `AndroidManifest.xml` sem `INTERNET`/`POST_NOTIFICATIONS`.
6. Sem Firestore/Storage Security Rules.
7. Mojibake UTF-8 em `pubspec.yaml` (`AlianÃ§a`).

### P1 — fluxo essencial do MVP
8. Célula não removida (`features/celula/`, `celulaId`, enums, strings, culto).
9. `AuthService` duplicado (`core/services/auth_service.dart` órfão vs
   `features/auth/data/auth_service.dart`); erros crus; `inativo` não tratado.
10. Navegação por `pushNamed` (97×) com rotas `-lider` duplicadas; sem shell.
11. Cadastro/recuperar/dados pessoais não persistem.
12. FCM nunca inicializado; token não desativado no logout.
13. Central de Notificações não integrada.

### P2 — qualidade/acessibilidade/manutenção
14. `TextScaler.noScaling` global (3 arquivos).
15. `main.dart` == `main_producao.dart` (duplicata).
16. Cores hardcoded em widgets (ex.: `AppBottomNavigation`).
17. `app_strings` refletia nav antiga de 5 itens.
18. Telas gigantes (`contribuir` 55KB, `historico` 40KB, `oracao` 32KB).

### P3 — futuro
19. "Minha Jornada" (futura). 20. Multi-igreja atrás de flag. 21. Bíblia como atalho.

## 4. Conflitos de produto registrados
- App aparenta ser exclusivo da CNA, mas há telas de selecionar/trocar igreja →
  mantida CNA como padrão; multi-igreja atrás de `AppConfig.multiIgrejaHabilitada`.
- Docs antigos colocavam Bíblia na nav principal e continham células (removidas).
- Painel de Gestão não existe no repo e depende de URL externa.
- Mercado Pago/Firebase/FCM dependem de configuração externa.

## 5. Riscos
- Sem toolchain Flutter na máquina de origem: correções não puderam ser compiladas
  aqui; verificação (`analyze`/`test`/`build`) deve ser feita no ambiente do usuário.
- Migração de navegação para shell (GoRouter/StatefulShellRoute) envolve reescrever
  97 chamadas `pushNamed` — feita de forma incremental para não introduzir regressões
  não verificáveis (ver `STATUS_FINAL_CNA_APP.md`).
- Dados de vínculo religioso podem ser sensíveis (LGPD) — regras e minimização
  aplicadas nas rules; política de privacidade/termos ainda a formalizar.
