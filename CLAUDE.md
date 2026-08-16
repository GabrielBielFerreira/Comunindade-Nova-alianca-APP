# CLAUDE.md — Nova Aliança App

Este arquivo contém as instruções obrigatórias para qualquer sessão do Claude Code neste repositório.

## 1. Leia antes de alterar qualquer coisa

Ordem de leitura e precedência:

1. `CLAUDE.md` — regras de trabalho e decisões que não podem ser reinterpretadas.
2. `CONTEXTO_GERAL_APP_NOVA_ALIANCA.md` — fotografia verificada do sistema atual e visão do produto.
3. `ARQUITETURA_MULTI_IGREJA_E_PAINEL.md` — arquitetura alvo e plano técnico vigente.
4. O plano complementar fornecido pelo responsável do projeto, quando existir.
5. Código, testes, regras Firebase e configuração realmente presentes no repositório.
6. `README.md` e demais documentos históricos.

Quando houver contradição, o código e os testes atuais prevalecem sobre documentos históricos, mas as decisões de produto deste arquivo prevalecem sobre planos antigos.

Arquivos como `STATUS_FINAL_CNA_APP.md`, `PLANO_FECHAMENTO_CNA_APP.md`, `CONTINUAR_AQUI.md` e `AUDITORIA_TECNICA_CNA_APP.md` são referências históricas. Não presuma que uma funcionalidade está pronta apenas porque um desses arquivos diz que está.

## 2. Objetivo atual do projeto

Transformar o aplicativo Nova Aliança em uma plataforma funcional para várias igrejas da mesma comunidade, começando por:

- Nova Aliança Olinda, sede e primeira unidade operacional.
- Nova Aliança Petrolina.
- Outras unidades adicionadas posteriormente sem exigir uma nova versão do aplicativo.

As prioridades atuais, nesta ordem, são:

1. Criar a arquitetura multi-igreja e o isolamento seguro dos dados.
2. Criar um painel administrativo web separado do aplicativo.
3. Tornar real a seleção e visualização de Olinda/Petrolina no aplicativo.
4. Implementar administração de membros, conteúdo, orações e notificações pelo painel.
5. Implementar finanças e Mercado Pago por igreja.
6. Corrigir os demais fluxos funcionais.
7. Melhorar ou portar o design somente depois que os fluxos correspondentes estiverem reais e testados.

## 3. Repositórios e responsabilidade

### Base oficial

Este repositório é a única base funcional oficial:

`C:\Users\Jean\Downloads\CNA APP atualizado\Comunindade-Nova-alianca-APP`

Ele contém o aplicativo Flutter, Firebase Rules, Cloud Functions e os testes existentes.

### Referência visual

O protótipo mais novo está em:

`C:\Users\Jean\Downloads\Nova_Alinca_APP_flutter\nova_alianca_app`

Use-o somente como referência visual. Ele contém dados simulados, login de demonstração e fluxos que não representam a fonte funcional. Há alterações locais do usuário nesse projeto: não reverta, sobrescreva ou formate seus arquivos sem autorização explícita.

A pasta `C:\Users\Jean\Downloads\Nova Alinça APP flutter` não é a raiz do projeto Flutter completo.

## 4. Decisões de arquitetura já tomadas

Estas decisões estão fechadas e não devem ser trocadas silenciosamente:

- Um único projeto Firebase atenderá toda a rede Nova Aliança.
- O isolamento será lógico e estrutural por `igrejaId`.
- A estrutura de dados terá `/igrejas/{igrejaId}/...` como raiz dos dados operacionais.
- O painel será um aplicativo Flutter Web separado, com URL e login próprios.
- Painel e aplicativo móvel usarão o mesmo Firebase Authentication.
- A interface administrativa será removida do aplicativo móvel depois que o painel atingir paridade funcional.
- Um membro tem uma igreja principal, mas pode visualizar conteúdo público de outra sem transferir seu vínculo.
- Trocar a igreja visualizada não altera aprovação, ministérios ou igreja principal.
- Cada igreja terá sua própria conta recebedora do Mercado Pago.
- Olinda poderá usar a conta pessoal do responsável somente durante o piloto aprovado.
- Petrolina não poderá receber automaticamente pela conta de Olinda.
- Pastor, diácono, evangelista e líder veem as finanças da própria igreja.
- Tesoureiro também vê as finanças da própria igreja, mesmo quando não possui perfil ministerial de liderança.
- O superadministrador autorizado pode ter visão consolidada.
- Editor e moderador de oração não recebem acesso financeiro apenas por essas funções.
- Somente o pastor da unidade ou o superadministrador pode retirar alguém da liderança.
- Retirar um líder significa rebaixar ou inativar o vínculo com auditoria; nunca apagar seu histórico.
- O aplicativo ainda não foi lançado; faça uma migração direta, sem ponte para o APK antigo.

## 5. Estrutura de dados alvo

Use esta estrutura como contrato inicial:

```text
usuarios/{uid}
usuarios/{uid}/notificacoes/{notificacaoId}
usuarios/{uid}/tokens_dispositivo/{tokenId}

igrejas/{igrejaId}
igrejas/{igrejaId}/membros/{uid}
igrejas/{igrejaId}/avisos/{avisoId}
igrejas/{igrejaId}/eventos/{eventoId}
igrejas/{igrejaId}/campanhas/{campanhaId}
igrejas/{igrejaId}/ministerios/{ministerioId}
igrejas/{igrejaId}/devocionais/{devocionalId}
igrejas/{igrejaId}/pedidos_oracao/{pedidoId}
igrejas/{igrejaId}/transacoes/{transacaoId}
igrejas/{igrejaId}/auditoria/{registroId}
```

### Usuário global

`usuarios/{uid}` guarda identidade e dados pessoais comuns:

- `nome`
- `email`
- `telefone`
- `foto_url`
- `igreja_principal_id`
- `criado_em`

Não coloque permissões financeiras globais nesse documento.

### Vínculo com a igreja

`igrejas/{igrejaId}/membros/{uid}` guarda:

- `status`: `pendente`, `aprovado` ou `inativo`.
- `perfil`: `pastor`, `diacono`, `evangelista`, `lider` ou `membro`.
- `funcoes_admin`: lista controlada pelo servidor.
- `ministerio_ids`.
- campos de aprovação e auditoria.

Funções administrativas iniciais:

- `pastor`
- `tesoureiro`
- `editor`
- `moderador_oracao`

Use custom claim somente para `super_admin`. As funções por igreja devem ser consultadas no vínculo daquela unidade.

Considere `pastor`, `diacono`, `evangelista` e `lider` como o grupo `lideranca_ministerial`. Esse grupo possui acesso operacional ao painel e às finanças da própria igreja. `tesoureiro` é uma função administrativa adicional que concede acesso financeiro sem exigir que a pessoa seja liderança ministerial.

### Igreja principal e igreja visualizada

- `igreja_principal_id` fica no perfil global do usuário.
- `igreja_visualizada_id` é uma preferência local do aplicativo.
- Ao iniciar uma sessão, use a igreja principal como padrão.
- Se a unidade visualizada for diferente, mostre conteúdo público e trate o usuário como visitante nessa unidade, salvo se também houver vínculo aprovado.
- Contribuições podem ser destinadas a qualquer igreja ativa, mas a igreja recebedora deve ser confirmada de forma explícita.

## 6. Permissões obrigatórias

| Papel/função | Conteúdo | Membros | Orações | Finanças | Igrejas |
|---|---|---|---|---|---|
| Membro | leitura autorizada | próprio perfil | próprias/públicas | próprias contribuições | leitura pública |
| Editor | CRUD de conteúdo | não | não | não | não |
| Moderador de oração | leitura | não | moderação da unidade | não | não |
| Tesoureiro | leitura | não | não | unidade vinculada | não |
| Líder/diácono/evangelista | CRUD da unidade | aprovação de membros comuns | moderação | unidade vinculada | leitura da configuração |
| Pastor | CRUD da unidade | aprovação e gestão da liderança | moderação | unidade vinculada | configuração da unidade |
| Superadministrador | todas | todas | todas | consolidado | CRUD completo |

Regras adicionais:

- Negar por padrão.
- Nunca confiar em `igrejaId`, papel ou status enviado pelo cliente.
- Toda consulta deve nascer do caminho da igreja correta.
- Toda Cloud Function que usa Admin SDK deve repetir a autorização no servidor.
- Clientes não podem promover a própria conta.
- Clientes não podem escrever status financeiro definitivo.
- Líder, diácono, evangelista e tesoureiro não podem remover ou promover integrantes da liderança.
- Somente pastor da unidade ou `super_admin` pode rebaixar ou inativar um integrante da liderança.
- Um pastor não pode remover a si mesmo nem outro pastor; substituição/inativação de pastor exige `super_admin`.
- Mudança de papel, aprovação, publicação e operação financeira devem produzir auditoria.
- Dados financeiros devem ficar separados de documentos públicos, pois o Firestore autoriza documentos inteiros, não campos individuais.

### Retirada de um integrante da liderança

Não exclua documentos físicos. Implemente duas ações distintas:

- `removerDaLideranca`: altera o perfil para `membro`, limpa funções administrativas de liderança e preserva o vínculo aprovado.
- `desvincularDaIgreja`: altera o vínculo para `inativo`, revoga funções administrativas e impede acesso à unidade.

As duas ações exigem pastor da mesma igreja ou `super_admin`, motivo obrigatório, timestamp, autor e registro em `auditoria`. Histórico de conteúdo, aprovações e transações nunca deve ser apagado ou reatribuído.

## 7. Painel administrativo web

Crie `admin_web/` como segundo projeto Flutter. Não mova o aplicativo atual para outro diretório durante a primeira implementação; isso produziria alteração massiva sem benefício funcional imediato.

Crie também `packages/nova_alianca_core/` para compartilhar somente:

- IDs e value objects.
- modelos de domínio que não dependam de UI.
- enums de status e papéis.
- validadores.
- contratos de repositórios e resultados.

O painel precisa ter:

- Login e recuperação de senha.
- Bloqueio de usuários sem função administrativa.
- Dashboard por igreja.
- Gestão de igrejas para `super_admin`.
- Aprovação e inativação de membros.
- Atribuição de papéis por igreja.
- CRUD de avisos, eventos, campanhas, ministérios e devocionais.
- Moderação de pedidos de oração comuns, anônimos e urgentes.
- Upload de mídia por igreja.
- Notificações.
- Auditoria.
- Painel financeiro restrito à liderança ministerial, tesoureiros e `super_admin`.
- Exportação CSV das transações.
- Gestão da liderança disponível somente a pastor da unidade e `super_admin`.

O seletor de igreja do painel só aparece para quem possui acesso a mais de uma unidade. Ele não pode conceder permissão; apenas alterna entre unidades já autorizadas.

## 8. Backend e Cloud Functions

Mantenha Node.js 20, mas migre as Functions para TypeScript em módulos pequenos:

```text
functions/src/
  auth/
  authorization/
  churches/
  members/
  content/
  prayers/
  notifications/
  payments/
  audit/
```

Helpers obrigatórios:

```text
requireSignedIn()
requireSuperAdmin()
requireChurchRole(igrejaId, roles)
requireChurchCapability(igrejaId, capability)
requireChurchLeadership(igrejaId)
requireChurchPastor(igrejaId)
writeAuditLog()
```

Use callable/HTTP Functions para mutações sensíveis. Leituras autorizadas podem usar Firestore diretamente, desde que regras e consultas tenham o mesmo escopo.

## 9. Mercado Pago

O código atual usa um único `MP_ACCESS_TOKEN`; ele não serve para a arquitetura final.

Implementação obrigatória:

- Uma aplicação integradora Nova Aliança.
- OAuth Authorization Code para conectar a conta de cada igreja.
- `offline_access` e renovação do token.
- Token de acesso e refresh token fora do Firestore e do código.
- Um segredo por igreja no Google Secret Manager.
- Metadados não sensíveis no documento da igreja.
- Pagamento criado com a credencial da igreja selecionada.
- Idempotência em toda criação.
- Webhook com validação real de `x-signature` e `x-request-id`.
- Consulta do pagamento na API antes de atualizar a transação.
- Conferência de recebedor, valor, `external_reference` e modo de produção.
- Atualização idempotente.
- Cliente nunca aprova pagamento.

Ordem de lançamento:

1. Contas de teste/sandbox.
2. Piloto real de Olinda com a conta autorizada pelo responsável.
3. Petrolina somente depois que o responsável local conectar a conta própria.

Não implemente split de valores entre igrejas. Cada pagamento pertence integralmente à igreja selecionada e não existe comissão da plataforma nesta fase.

## 10. Estado atual que não deve ser confundido com pronto

- `firebase_options.dart` e `android/app/google-services.json` não estão presentes no checkout atual.
- Sem esses arquivos, o app funcional não compila.
- A seleção de igreja usa dados fixos.
- `IgrejaInfo` fixa Olinda em diversas telas.
- O painel interno realiza CRUD, mas não está isolado por igreja.
- As regras reconhecem liderança global.
- O Mercado Pago possui estrutura inicial, mas não está conectado às telas e não suporta várias contas.
- A validação de assinatura do webhook não foi implementada.
- Oração urgente apenas simula envio.
- Usuário anônimo pode cair no fluxo de membro do `RootGate`.
- Regras atuais impedem alguns conteúdos públicos para visitantes.
- Foto de perfil ainda não é persistida de forma definitiva.
- Existem rotas que ainda usam mocks.

Consulte `CONTEXTO_GERAL_APP_NOVA_ALIANCA.md` antes de corrigir qualquer um desses pontos.

## 11. Ordem de implementação

Não tente entregar tudo em uma única alteração.

### Fase 0 — Ambiente

- Restaurar a configuração Firebase sem versionar segredos.
- Configurar e validar Emulator Suite.
- Rodar testes existentes e registrar baseline.
- Criar branch de trabalho.

### Fase 1 — Multi-igreja

- Criar modelos compartilhados.
- Criar estrutura, rules e índices.
- Criar Olinda e Petrolina.
- Criar migração idempotente com `--dry-run`.
- Migrar dados atuais para Olinda.

### Fase 2 — Painel essencial

- Login, autorização e dashboard.
- Gestão de igrejas, membros e papéis.
- Testes de isolamento Olinda/Petrolina.

### Fase 3 — Conteúdo e oração

- CRUD real pelo painel.
- Uploads.
- Moderação.
- Auditoria e notificações.

### Fase 4 — Aplicativo multi-igreja

- Seleção real.
- Providers por igreja.
- Cadastro vinculado.
- Visualização de outra unidade.
- Remoção da gestão interna.

### Fase 5 — Finanças

- OAuth Mercado Pago.
- PIX dinâmico.
- Webhook seguro.
- Dashboard financeiro e CSV.
- Sandbox e piloto Olinda.

### Fase 6 — Fechamento

- App Check.
- Testes end-to-end.
- APK debug/release.
- Painel staging/produção.
- Documentação e runbooks.

## 12. Design

Design pode ser alterado, mas não é a prioridade atual.

Regras:

- Não reescreva telas apenas por aparência durante as fases de arquitetura.
- Preserve o estilo reconhecível do aplicativo quando possível.
- Use o protótipo como referência seletiva, nunca como base funcional.
- Não remova loading, erro, vazio, permissão ou acessibilidade para reproduzir um mock.
- Uma tela visualmente pronta não é funcional se usa dados estáticos ou apenas exibe `SnackBar`.
- Depois da base funcional, os componentes podem ser consolidados em design system compartilhado.

## 13. Qualidade e segurança

Antes de concluir cada fase:

```powershell
flutter pub get
flutter analyze
flutter test
```

Para o painel, rode também os testes do projeto `admin_web`.

Para Functions e Firebase:

- testes unitários das Functions;
- testes no Emulator Suite;
- testes automatizados de Firestore Rules e Storage Rules;
- testes de webhook inválido, duplicado e fora de ordem;
- testes de isolamento entre Olinda e Petrolina.

Não faça:

- commit de credenciais, tokens ou arquivos privados do Firebase;
- `git reset --hard` ou descarte de alterações do usuário;
- alteração destrutiva de dados sem backup e `--dry-run`;
- upgrade amplo de dependências junto com a migração multi-igreja;
- aprovação financeira no cliente;
- leitura financeira de outra igreja ou por usuário sem liderança/tesouraria autorizada;
- exclusão física de vínculo, auditoria ou histórico de um ex-líder;
- dados fictícios apresentados como dados oficiais de Petrolina.

## 14. Forma de trabalhar

- Inspecione antes de editar.
- Faça uma fase por vez.
- Mantenha alterações pequenas e verificáveis.
- Atualize documentação quando o comportamento real mudar.
- Registre decisões arquiteturais relevantes em ADRs curtos.
- Preserve IDs e timestamps durante migrações.
- Toda migração deve ser repetível e produzir relatório de contagem.
- Pare e informe o responsável quando faltar uma credencial, dado oficial da igreja ou decisão financeira externa.

## 15. Definição de pronto

Uma fase só está pronta quando:

- código, testes e documentação concordam;
- não existem mocks ou confirmações falsas no fluxo entregue;
- permissões foram testadas do lado do servidor;
- Olinda não consegue acessar dados privados de Petrolina e vice-versa;
- erros e estados vazios têm tratamento real;
- não há segredo no repositório;
- o fluxo foi validado no emulador e, quando aplicável, em Android real;
- o responsável consegue repetir os passos com o runbook fornecido.

## 16. Adendo de execução — correções confirmadas (2026-08-16)

Este adendo tem precedência sobre trechos anteriores que o contradigam. Foi
registrado no início da implementação das Fases 0 e 1.

### 16.1 Vulnerabilidades confirmadas no estado atual (corrigir na Fase 1)

Auditoria do código real confirmou riscos de segurança que precedem o painel:

- **D.1 — Auto-promoção e promoção arbitrária.** A regra `match /usuarios/{uid}`
  concede `allow update: if isLider()` sem restringir os campos escritos. Um
  perfil de liderança pode alterar o próprio `perfil` para `pastor`, promover
  ou rebaixar qualquer conta e ler todos os usuários e todas as transações.
  Correção obrigatória: cliente nunca escreve `perfil`, `status`,
  `funcoes_admin` ou `igreja_principal_id`; essas mutações só ocorrem via
  Cloud Function com Admin SDK.
- **D.2 — Auditoria forjável.** `/auditoria` aceita `create: if isLider()`, com
  `autor_id` vindo do cliente. Auditoria passa a ser gravável apenas pelo
  Admin SDK (`create/update/delete = false` para qualquer cliente).
- **D.3 — Contrato financeiro divergente.** Functions gravam `usuario_id`,
  `metodo`, valor em reais e status `recusado`/`cancelado`; `TransacaoModel`
  lê `perfil_id`, `meio_pagamento`, valor em centavos e status
  `rejeitado`/`estornado`. Padronizar pelo contrato canônico de 16.4.
- **D.4 — Exclusão física de histórico.** `OracaoRepository.recusarPedido` e
  `MinisteriosRepository.deletar` usam `delete()`. A política é inativar/rebaixar
  com auditoria, nunca apagar. Substituir por marcação de status.
- **D.6 — Reação de oração explorável.** A regra `hasOnly(['oram_count',
  'oram_por'])` não valida incremento de 1 nem o próprio uid. Restringir a
  incremento unitário do próprio usuário.

### 16.2 Correção factual sobre `multiIgrejaHabilitada`

`AppConfig.multiIgrejaHabilitada` **é lida** em
`lib/visual/screens/configuracoes_screen.dart` (por volta da linha 202), onde
condiciona a exibição da opção de troca de igreja. Ela não é uma flag morta;
está desligada por padrão (`bool.fromEnvironment('MULTI_IGREJA', defaultValue:
false)`).

### 16.3 Migração direta (sem regras globais inseguras em paralelo)

O aplicativo ainda não foi lançado. Não manter as regras globais antigas ativas
até a Fase 4. A transição é direta:

1. Implementar os novos caminhos `/igrejas/{igrejaId}/...`.
2. Migrar os repositórios do aplicativo para o escopo por igreja já na Fase 1.
3. Validar isolamento e permissões no Emulator Suite.
4. No estado final das regras, **negar** os caminhos globais antigos.
5. Não apagar dados antigos sem autorização explícita do responsável.

### 16.4 Contrato financeiro canônico

Padronizar app, domínio, Functions, Rules e testes com estes campos em
`/igrejas/{igrejaId}/transacoes/{id}`:

```text
usuario_id        string
igreja_id         string
valor_centavos    inteiro
tipo              dizimo | oferta | campanha
metodo            pix | checkout_pro
status            criando | pendente | aprovado | rejeitado | cancelado | estornado
campanha_id       string (opcional)
mp_payment_id     string (opcional)
mp_status_detail  string (opcional)
criado_em         timestamp
atualizado_em     timestamp
aprovado_em       timestamp (opcional)
```

Proibido no Firestore: `perfil_id`, `meio_pagamento` e `valor` em reais.

### 16.5 Mercado Pago desativado nesta fase

O código atual do Mercado Pago (PIX/checkout/webhook sem validação de
assinatura) **não** deve ser exportado como função ativa. Preservá-lo em área
de legado claramente desativada para retomada na Fase 5. Não migrar um webhook
inseguro como função ativa.

### 16.6 Finanças somente leitura na Fase 2

O painel da Fase 2 incluirá `/financas` **somente leitura** (filtros, totais e
exportação CSV), obrigatoriamente após a correção do contrato financeiro de
16.4. O painel nunca aprova, edita valor ou transforma pendente em aprovado.

### 16.7 `super_admin` e dados pessoais

- `super_admin` é concedido por custom claim, provisionado por script de
  bootstrap que recebe o UID por argumento/variável de ambiente. Não fixar UID
  no código; usar apenas UIDs fictícios no emulador.
- Remover e-mails pessoais versionados de `seed/promover_lideres.js`,
  substituindo-os por argumentos/variáveis de ambiente. Não reescrever o
  histórico do Git nesta fase.
