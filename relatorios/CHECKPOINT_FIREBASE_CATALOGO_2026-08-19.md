# Checkpoint Firebase/catálogo — 2026-08-19

## Escopo e Git

- Projeto: `nova-alianca-app`
- Worktree: `worktree-firebase-catalogo-p0`
- Branch: `fix/firebase-catalogo-publico-p0`
- HEAD base: `6f0ffb06bd19`
- Nenhum merge, push, `--apply`, deploy, build final ou upload foi feito. As
  alterações serão consolidadas no único commit local deste checkpoint.

## Auditoria remota somente leitura

- `/igrejas`: 0 documentos.
- `/catalogo_igrejas`: 0 documentos.
- `/igreja`: 0 documentos.
- A leitura anônima de `igrejas/olinda` retornou HTTP 403.
- A query anônima de `/igrejas` sem filtro retornou HTTP 403.
- Rules vigente: release `cloud.firestore`, um arquivo, ruleset
  `1e15e961-7cef-4044-bc58-5674fbba065c`, SHA-256
  `46e758d90281defd772103f75cdc70f07346c510910780b652be5f69b363216f`.
- A Rules vigente não declara `/catalogo_igrejas` nem `/igrejas`; o bloqueio
  anônimo é coerente com a negação por padrão.
- A consulta administrativa do App Check foi recusada com
  `HTTP 403 SERVICE_DISABLED`. O modo de enforcement não foi alterado nem
  inferido. O app Flutter também não declara `firebase_app_check`.

## Dry-run real com ADC

Comando:

```text
node scripts/migrar_producao.js --project=nova-alianca-app --dry-run
```

Resultado: sucesso, zero conflitos, zero escritas e zero exclusões.

| Destino planejado | Operações |
|---|---:|
| raízes `igrejas` | 2 |
| catálogo público (11 campos exatos) | 2 |
| vínculos de membros | 4 |
| `igreja_principal_id` | 4 |
| avisos | 2 |
| eventos | 3 |
| campanhas | 1 |
| ministérios | 4 |
| devocionais | 2 |
| pedidos de oração | 5 |
| auditoria | 1 |
| notificações | 3 |
| tokens de dispositivo (destino privado do usuário) | 11 |
| configurações globais (exigida vazia) | 0 |
| transações e interesses | 0 |
| **Total** | **44** |

O relatório técnico exibiu somente contagens e nomes de campos; nenhum valor,
e-mail, token ou UID foi impresso.

O preflight comprovou `tokens_dispositivo=11` e planejou todos os documentos
para `usuarios/{uid}/tokens_dispositivo/{id}`. Também comprovou
`configuracoes=0`; qualquer documento nessa coleção passa a bloquear o plano,
pois ainda não existe contrato de destino seguro.

O catálogo resultante contém exatamente `nome`, `ativa`, `configurada`,
`endereco`, `cidade_estado`, `endereco_secundario`, `slogan`,
`cultos_recorrentes`, `instagram`, `youtube_url` e `pastores_publicos`. PIX,
telefone, UIDs e metadados operacionais não entram nessa projeção. Para não
publicar uma chave potencialmente pessoal, o fluxo **Contribuir** do visitante
agora mostra um bloqueio honesto; membros aprovados continuam usando o
documento operacional privado.

## Validação local

- Scripts de migração/canários: 40/40.
- Functions (build + testes unitários): 92/92.
- Functions no Firestore Emulator: 33/33, incluindo rollback de raiz,
  catálogo e auditoria quando o commit transacional falha.
- Firestore/Storage Rules Emulator: 160/160.
- Flutter direcionado (multi-igreja, onboarding, bootstrap fail-closed e
  contribuição do visitante): 51/51.
- `flutter analyze --no-pub lib`: sem problemas na passada final completa. Foi
  usado somente um stub local ignorado do arquivo gerado de configuração; o
  stub foi removido imediatamente e não entrou no Git.
- Análise direcionada da alteração Flutter final e seu teste: sem problemas.
- `node --check` dos seeds, aceite, fixtures e teste de catálogo: sem erros.
- `git diff --check`: sem erros; apenas avisos informativos de LF/CRLF.

O comando amplo `flutter analyze --no-pub` na raiz também percorre os projetos
aninhados `admin_web` e `packages/nova_alianca_core`, que não têm
`.dart_tool/package_config.json` neste worktree; por isso ele reporta erros de
resolução desses pacotes. O app principal e os arquivos alterados foram
analisados separadamente e estão limpos.

## Operações reais ainda bloqueadas

1. Rotacionar a sessão do Firebase CLI, pois um token apareceu no histórico
   técnico durante a auditoria inicial.
2. Decidir App Check no Console ou habilitar apenas a API de gerenciamento para
   auditoria; não impor enforcement antes de integrar o SDK e revisar métricas.
3. Publicar as Functions quando a frente de release autorizar.
4. Autorizar explicitamente a migração `--apply`.
5. Publicar Rules/Storage finais.
6. Rodar o canário anônimo positivo e negativo após o deploy.
7. Gerar/testar um novo APK e executar smoke em aparelho físico.

Nenhuma das operações acima foi executada neste checkpoint.
