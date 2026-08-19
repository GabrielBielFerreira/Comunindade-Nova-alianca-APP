# Checkpoint Firebase/catálogo — 2026-08-19

## Escopo e Git

- Projeto: `nova-alianca-app`
- Worktree: `worktree-integracao-release-p0`
- Branch: `agent/firebase-catalogo-release-p0`
- HEAD base: `6f0ffb06bd19`
- Versão Android preparada para o próximo artefato: `1.3.1+2011`.
- Nenhum push, `--apply`, deploy, build final ou upload foi feito neste
  checkpoint. As frentes Firebase e UI já estão integradas localmente.

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
para `usuarios/{uid}/tokens_dispositivo/{token}`. O token validado é o mesmo ID
canônico que o app grava e desativa no logout; IDs automáticos legados não são
reutilizados e duplicatas do mesmo usuário/token são consolidadas sem reativar
uma cópia já inativa. Um token associado a UIDs diferentes agora é preservado
em cada destino canônico privado com `ativo=false`, sem escolher dono, reativar
o aparelho ou expor token/UID nos relatórios; destinos existentes divergentes
continuam bloqueando o preflight.
Também comprovou
`configuracoes=0`; qualquer documento nessa coleção passa a bloquear o plano,
pois ainda não existe contrato de destino seguro.

O catálogo resultante contém exatamente `nome`, `ativa`, `configurada`,
`endereco`, `cidade_estado`, `endereco_secundario`, `slogan`,
`cultos_recorrentes`, `instagram`, `youtube_url` e `pastores_publicos`. PIX,
telefone, UIDs e metadados operacionais não entram nessa projeção. Para não
publicar uma chave potencialmente pessoal, o fluxo **Contribuir** do visitante
agora mostra um bloqueio honesto; membros aprovados continuam usando o
documento operacional privado.

A revisão integrada também fechou dois caminhos de autorização no cliente:
um vínculo só concede capacidade quando seu UID coincide com o usuário atual,
e a tela de contribuição exige vínculo aprovado mesmo quando uma rota antiga a
abre sem marcar explicitamente o visitante.

## Validação local

- Scripts de migração/canários: 45/45.
- Functions (build + testes unitários): 92/92.
- Functions no Firestore Emulator: 33/33, incluindo rollback de raiz,
  catálogo e auditoria quando o commit transacional falha.
- Firestore/Storage Rules Emulator: 160/160.
- Flutter app completo: 327/327.
- Painel web completo: 248/248.
- Pacote central de domínio/autorização: 64/64.
- Análise estática do app, painel e pacote central: sem problemas. No app, foi
  usado somente um stub local sem credenciais para o `firebase_options.dart`
  ignorado pelo Git; o stub foi removido imediatamente e não entrou no Git.
- `node --check` dos seeds, aceite, fixtures e teste de catálogo: sem erros.
- `npm audit --omit=dev`: 8 moderadas e 0 altas/críticas nas dependências de
  produção das Functions/scripts; nenhuma atualização automática foi aplicada.
- `git diff --check`: sem erros; apenas avisos informativos de LF/CRLF.

Cada projeto Dart foi analisado no seu próprio diretório e com o próprio
`package_config`, evitando falsos erros de resolução entre projetos aninhados.

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
