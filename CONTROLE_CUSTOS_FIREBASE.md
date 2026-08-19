# Controle de custos — `nova-alianca-app` (Blaze)

Projeto Firebase: **`nova-alianca-app`**
Plano: **Blaze** (pay-as-you-go)

## 1. O que este documento não promete

**Não existe garantia de custo zero no Blaze.**

Isso não é pessimismo — é como o produto funciona:

- um **orçamento** do Cloud Billing **apenas envia alertas**. Ele não
  interrompe o serviço nem bloqueia a cobrança quando o valor é atingido;
- o **spend cap** (limite de gastos que realmente interrompe) existe, mas está
  em disponibilidade limitada/preview e **pode não aparecer nesta conta**;
- desligar a conta de faturamento por automação é destrutivo: derruba o
  aplicativo, o painel e pode causar perda de dados. **Não faça isso.**

O controle que de fato limita o estrago está no **código** (seção 2), porque é
ele que o deploy aplica. Os controles do Console (seções 3 e 4) são a rede de
avisos por cima.

## 2. Limites no código — a defesa principal

Fonte única da verdade: [`functions/src/opcoes.ts`](functions/src/opcoes.ts).

```ts
setGlobalOptions({
  region: "southamerica-east1",
  minInstances: 0,
  maxInstances: 1,
  memory: "256MiB",
  cpu: "gcf_gen1",
  concurrency: 1,
  timeoutSeconds: 30,
  preserveExternalChanges: false,
});
```

| Opção | Valor | Por quê |
|---|---|---|
| `minInstances` | `0` | Instância aquecida é cobrada **mesmo parada**. Uma igreja em piloto não justifica pagar por espera. |
| `maxInstances` | `1` | Teto duro. Com uma unidade piloto, um pico só pode significar erro ou abuso — e aí a fila é preferível à conta. |
| `memory` / `cpu` | `256MiB` / `gcf_gen1` | Menor porte. Estas Functions leem alguns documentos e escrevem uma transação. |
| `concurrency` | `1` | Obrigatório com CPU fracionária, e coerente com operação transacional. |
| `timeoutSeconds` | `30` | Uma transação do Firestore que passe disso está travada, não lenta. |
| `preserveExternalChanges` | `false` | O repositório manda. Alteração feita à mão no Console é sobrescrita em vez de divergir em silêncio. |

`enforceAppCheck` **não** está ligado ainda: App Check entra primeiro em
monitoramento (ver `DEPLOY_PRODUCAO.md`), para não derrubar o aplicativo e o
painel reais antes de validá-los.

### Como conferir antes de publicar

```bash
node scripts/verificar_producao.js --functions
```

Reprova o deploy quando qualquer Function estiver sem `maxInstances`, com
`minInstances > 0`, com memória/timeout acima do teto, fora da região, ou
quando uma Function de pagamento legada estiver exportada. Os mesmos limites
são testados em `functions/test/limites_custo.test.js`.

## 3. Orçamento e alertas (Google Cloud Billing)

Caminho: **console.cloud.google.com** → menu ☰ → **Faturamento** →
**Orçamentos e alertas** → **CRIAR ORÇAMENTO**.

Configuração recomendada:

| Campo | Valor |
|---|---|
| Escopo | Projeto `nova-alianca-app` |
| Valor | **R$ 10,00 / mês** |
| Alertas (gasto real) | 10%, 50%, 80%, 90%, 100% |
| Alerta de previsão | 100% |
| Destinatários | administradores de faturamento e proprietários do projeto |

Marque também **"Alertas de anomalia de custo"** quando a opção aparecer.

> Lembrete: ao atingir 100% você recebe e-mail. **Nada é bloqueado.**

## 4. Spend cap — se estiver disponível

Caminho: mesma tela de criação de orçamento. Se a conta for elegível, aparece
a opção de **limite de gastos (spend cap)** para serviços compatíveis, entre
eles Cloud Run Functions.

Se aparecer:

| Campo | Valor |
|---|---|
| Serviço | Cloud Run Functions |
| Limite | **R$ 5,00** |

Se **não** aparecer, o recurso não está liberado para esta conta. Nesse caso a
proteção real continua sendo a da seção 2, e o orçamento da seção 3 serve de
alarme. Não invente contorno automático que desligue o faturamento.

## 5. Limpeza de artefatos de build

Cada deploy de Functions guarda uma imagem de container no Artifact Registry.
Sem política de retenção, elas acumulam e passam a custar armazenamento.

Depois do **primeiro** deploy de Functions:

```bash
node test_rules/node_modules/firebase-tools/lib/bin/firebase.js functions:artifacts:setpolicy --days 1 --project nova-alianca-app
```

Confira a política aplicada logo em seguida:

```bash
node test_rules/node_modules/firebase-tools/lib/bin/firebase.js functions:artifacts:getpolicy --project nova-alianca-app
```

Não use `--none`: isso desliga a limpeza.

## 6. Consumo do lado do cliente

O que evita leitura desnecessária do Firestore (o outro item que pesa na
conta), já implementado:

- lista de membros do painel limitada a 300 documentos, com aviso visível
  quando a lista é truncada;
- contagens do dashboard por `count()` agregado — nenhum documento trafega;
- providers que **não** consultam quando o usuário não tem a capacidade, em vez
  de disparar uma consulta que as Rules negariam;
- repositório de conteúdo recriado por unidade, descartando o cache da igreja
  anterior;
- `meusAcessos` percorre apenas as unidades cadastradas na rede.

## 7. Serviços deliberadamente fora do ar

| Serviço | Situação |
|---|---|
| Mercado Pago | **Não publicado.** Código legado preservado, desativado e não exportado. O webhook antigo não valida assinatura. |
| Firebase Storage | **Não publicado** nesta entrega — o código atual não faz upload relevante. As Rules ficam versionadas para uso futuro. |
| Functions agendadas | Não existem. Nenhum gatilho roda sozinho. |

## 8. Checklist antes de cada deploy

```bash
node scripts/verificar_producao.js --functions
npm --prefix functions test
```

- [ ] Verificador de Functions aprovado
- [ ] Nenhuma Function nova sem passar por `setGlobalOptions`
- [ ] Orçamento e alertas ativos no Console
- [ ] Política de limpeza de artefatos configurada
- [ ] Mercado Pago continua fora da lista de exportação
