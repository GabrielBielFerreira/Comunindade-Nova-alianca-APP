# Plano de Fechamento — Comunidade Nova Aliança App

Backlog priorizado (P0–P3), ordem de execução, dependências e critérios de aceite.
Status: ✅ feito · 🟡 parcial · ⬜ pendente · 🔗 bloqueado por recurso externo.

## P0 — bloqueadores (compilação/execução/segurança/entrega)

| # | Item | Status | Critério de aceite |
|---|---|---|---|
| P0-1 | Unificar apps: telas visuais em produção, sem `PlaceholderTela` | ✅ | Um único entrypoint; nenhum placeholder no fluxo do MVP |
| P0-2 | Remover login hardcoded; ligar ao Firebase Auth | ✅ | Sem creds demo/autofill/logo-tap; login real |
| P0-3 | Firebase configurável (options/plugin/json) | 🟡 🔗 | Estrutura pronta; requer `flutterfire configure` + `google-services.json` |
| P0-4 | Assinatura de release fora da chave de debug | 🟡 🔗 | Mecanismo via `key.properties`; requer keystore de produção |
| P0-5 | Permissões Android (INTERNET, POST_NOTIFICATIONS) | ✅ | Presentes no manifest |
| P0-6 | Firestore/Storage Security Rules | ✅ | `firestore.rules`/`storage.rules` restritivas; falta `deploy` |
| P0-7 | Corrigir encoding UTF-8 | ✅ | `pubspec.yaml` sem mojibake |

## P1 — fluxo essencial do MVP

| # | Item | Status | Critério de aceite |
|---|---|---|---|
| P1-8 | Remover célula (feature/campo/enum/strings/culto) | ✅ | Zero referências a célula no código |
| P1-9 | Unificar `AuthService`; erros amigáveis; tratar `inativo` | ✅ | Órfão removido; mensagens PT; tela de conta inativa |
| P1-10 | Navegação: shell por aba (estado/back) | 🟡 | Gate por perfil pronto; migração para StatefulShellRoute pendente |
| P1-11 | Cadastro/recuperar/logout reais | ✅ | Persistência via Auth+Firestore; logout com desativação de token |
| P1-11b | Dados pessoais persistentes | ⬜ 🔗 | Salvar em `usuarios/{uid}` (requer Firebase ativo) |
| P1-12 | Inicializar FCM; desativar token no logout | ✅ | `FcmService.init()` pós-login; background handler; token off no logout |
| P1-13 | Central de Notificações separada de Avisos | 🟡 | Tela existe e é separada; wiring de dados pendente |

## P2 — qualidade/acessibilidade/manutenção

| # | Item | Status | Critério de aceite |
|---|---|---|---|
| P2-14 | Substituir `TextScaler.noScaling` por clamp acessível | ✅ | Fonte do sistema respeitada (0.85–1.3) |
| P2-15 | Remover entrypoint duplicado | ✅ | `main_producao.dart` removido |
| P2-16 | Centralizar cores hardcoded em `AppColors` | ⬜ | Widgets usam tokens |
| P2-17 | Alinhar `app_strings` à nav atual | 🟡 | `minhasCelula` removido; revisão completa pendente |
| P2-18 | Dividir telas gigantes | ⬜ | Arquivos < 800 linhas |
| P2-19 | Testes reais + cobertura | 🟡 | Suítes de Dart puro criadas; ampliar cobertura |

## P3 — futuro / não bloqueante

| # | Item | Status |
|---|---|---|
| P3-20 | "Minha Jornada" oculta/marcada como futura | ⬜ |
| P3-21 | Multi-igreja atrás de feature flag (CNA padrão) | ✅ (`AppConfig.multiIgrejaHabilitada`) |
| P3-22 | Bíblia como atalho na Home | 🟡 (não é item de nav; tela funcional a implementar) |
| P3-23 | Pagamentos: cartão/boleto via Cloud Functions | ⬜ 🔗 |
| P3-24 | Política de privacidade/termos (LGPD) | ⬜ |

## Ordem de execução recomendada (próximos passos)
1. Configurar Firebase (`flutterfire configure`) e publicar rules → destrava P0-3, P1-11b, P1-13.
2. Rodar `flutter analyze`/`test` no ambiente com SDK e corrigir eventuais avisos.
3. Gerar keystore + `key.properties` → destrava P0-4 e o release.
4. Migrar navegação para `StatefulShellRoute.indexedStack` (P1-10) com verificação.
5. Wiring de dados por feature (Avisos → Programação → Oração → Perfil).
6. Integração Mercado Pago via Cloud Functions (P3-23).

## Dependências externas (quem fornece)
- **Firebase**: responsável técnico cria projeto e roda `flutterfire configure`.
- **Keystore**: responsável pela publicação gera e guarda o `.jks`.
- **URL do painel de Gestão**: administração informa (`--dart-define=GESTAO_PANEL_URL`).
- **Mercado Pago**: credenciais server-side + Cloud Functions.
