# Cloud Functions — administração multi-igreja

Backend privilegiado da rede Nova Aliança. As Functions publicadas nesta fase
tratam autorização, vínculos, funções administrativas e cadastro de unidades.
Elas usam Cloud Functions v2 e exigem o plano Blaze.

## Endpoints ativos

- `meusAcessos`
- `aprovarMembro`, `recusarMembro`
- `promoverParaLideranca`, `removerDaLideranca`
- `desvincularDaIgreja`, `transferirVinculoIgreja`
- `atribuirFuncaoAdmin`, `removerFuncaoAdmin`
- `criarIgreja`, `atualizarIgreja`
- `notificarPedidoOracaoUrgente` (gatilho do Firestore)

A lista efetiva é a exportada por [`src/index.ts`](src/index.ts). Antes de todo
deploy, o verificador reprova Functions antigas de pagamento e Functions sem os
limites de custo definidos em `src/opcoes.ts`.

O gatilho de oração urgente envia apenas uma mensagem genérica à liderança
aprovada da mesma igreja; nunca inclui o texto pastoral no push. Sessões
anônimas permanecem na fila reservada, mas não disparam notificação. Para
conter abuso e custo, cada autor pode gerar no máximo um push por igreja a
cada dez minutos.

## Mercado Pago está desativado

O código da v1.3.0 permanece somente em `src/legacy/` para referência. Ele
**não é exportado, não valida a assinatura do webhook e não pode ser
publicado**. Não configure `MP_ACCESS_TOKEN`, não crie webhook e não tente
chamar endpoints de pagamento descritos em documentação antiga. Por enquanto,
o app oferece somente o PIX manual configurado separadamente em cada igreja.

Uma integração futura exigirá OAuth/credenciais por igreja, validação oficial
da assinatura e um projeto próprio de migração e testes.

## Verificação e deploy

Na raiz do repositório:

```bash
npm --prefix functions ci
npm --prefix functions test
node scripts/verificar_producao.js --functions
firebase deploy --only functions --project nova-alianca-app
```

O deploy só deve ocorrer depois que os testes e o verificador passarem, com a
conta autenticada no projeto exato `nova-alianca-app`. Consulte também
`DEPLOY_PRODUCAO.md` e `CONTROLE_CUSTOS_FIREBASE.md`.
