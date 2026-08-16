/**
 * Migração das coleções globais para a estrutura multi-igreja.
 *
 * NÃO É O SEED. Este script não cria usuários, senhas nem conteúdo de
 * demonstração — apenas move o que já existe para dentro de `igrejas/olinda`.
 *
 * Segurança embutida:
 *  - exige `--project=<id>` e confirma que é o esperado;
 *  - `--dry-run` é o PADRÃO; gravar exige `--apply` explícito;
 *  - idempotente: reexecutar não duplica nada;
 *  - preserva IDs e timestamps originais;
 *  - NUNCA apaga: as coleções antigas permanecem intactas;
 *  - relatório de contagem no fim.
 *
 * Uso:
 *   node scripts/migrar_producao.js --project=nova-alianca-app --dry-run
 *   node scripts/migrar_producao.js --project=nova-alianca-app --apply
 *
 * Credencial: GOOGLE_APPLICATION_CREDENTIALS apontando para a service
 * account do projeto, ou `gcloud auth application-default login`.
 */
const admin = require("firebase-admin");

// ── Argumentos ────────────────────────────────────────────────────────
function arg(nome) {
  const item = process.argv.find((a) => a.startsWith(`--${nome}=`));
  return item ? item.split("=").slice(1).join("=") : undefined;
}
const temFlag = (nome) => process.argv.includes(`--${nome}`);

const PROJETO_ESPERADO = "nova-alianca-app";
const OLINDA = "olinda";
const PETROLINA = "petrolina";

const projeto = arg("project");
const aplicar = temFlag("apply");
const dryRun = !aplicar;

if (!projeto) {
  console.error(
    "\n[ABORTADO] Informe o projeto explicitamente:\n" +
      `  node scripts/migrar_producao.js --project=${PROJETO_ESPERADO} --dry-run\n`
  );
  process.exit(1);
}

if (projeto !== PROJETO_ESPERADO) {
  console.error(
    `\n[ABORTADO] Projeto '${projeto}' != '${PROJETO_ESPERADO}'.\n` +
      "Este script só opera no projeto oficial da rede.\n"
  );
  process.exit(1);
}

if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.error(
    "\n[ABORTADO] FIRESTORE_EMULATOR_HOST está definida.\n" +
      "Este script é para o Firebase REAL. Para testar no emulador, rode-o\n" +
      "em outro terminal sem essa variável, ou use o seed do emulador.\n"
  );
  process.exit(1);
}

admin.initializeApp({ projectId: projeto });
const db = admin.firestore();

/** Coleções globais → subcoleção da unidade. */
const COLECOES = [
  "avisos",
  "eventos",
  "campanhas",
  "ministerios",
  "devocionais",
  "pedidos_oracao",
  "interesses_ministerio",
  "auditoria",
];

const relatorio = [];

function registrar(item, lidos, migrados, ignorados, extra = "") {
  relatorio.push({ item, lidos, migrados, ignorados, extra });
  console.log(
    `  ${item.padEnd(24)} lidos=${String(lidos).padStart(5)} ` +
      `migrados=${String(migrados).padStart(5)} ` +
      `ja_existiam=${String(ignorados).padStart(5)} ${extra}`
  );
}

/**
 * Copia preservando ID e todos os campos originais (inclusive timestamps).
 * Se o destino já existe, não sobrescreve — é o que torna a reexecução segura.
 */
async function migrarColecao(nome) {
  const origem = await db.collection(nome).get();
  let migrados = 0;
  let ignorados = 0;

  for (const doc of origem.docs) {
    const destino = db.doc(`igrejas/${OLINDA}/${nome}/${doc.id}`);
    const jaExiste = (await destino.get()).exists;

    if (jaExiste) {
      ignorados++;
      continue;
    }
    if (!dryRun) {
      await destino.set({
        ...doc.data(),
        migrado_de: `${nome}/${doc.id}`,
        migrado_em: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    migrados++;
  }

  registrar(nome, origem.size, migrados, ignorados);
}

/** Cria as unidades. Petrolina entra INATIVA e sem dados inventados. */
async function criarUnidades() {
  const unidades = [
    {
      id: OLINDA,
      dados: {
        nome: "Nova Aliança Olinda",
        slug: OLINDA,
        ativa: true,
        configurada: true,
        mercado_pago_status: "nao_configurado",
      },
    },
    {
      id: PETROLINA,
      dados: {
        nome: "Nova Aliança Petrolina",
        slug: PETROLINA,
        // Sem dados oficiais confirmados: entra inativa e não configurada.
        ativa: false,
        configurada: false,
        dados_institucionais: {},
        mercado_pago_status: "nao_configurado",
      },
    },
  ];

  let criadas = 0;
  let existentes = 0;

  for (const u of unidades) {
    const ref = db.doc(`igrejas/${u.id}`);
    if ((await ref.get()).exists) {
      existentes++;
      continue;
    }
    if (!dryRun) {
      await ref.set({
        ...u.dados,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    criadas++;
  }

  registrar("igrejas", unidades.length, criadas, existentes);
}

/**
 * Cada `usuarios/{uid}` vira um vínculo em Olinda, preservando perfil e
 * status atuais. Liderança NÃO é convertida em tesoureiro — o acesso
 * financeiro vem do próprio perfil.
 */
async function migrarVinculos() {
  const usuarios = await db.collection("usuarios").get();
  let criados = 0;
  let existentes = 0;
  let principalDefinida = 0;

  const normalizar = (v) =>
    String(v ?? "")
      .toLowerCase()
      .trim()
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "");

  const PERFIS = ["pastor", "diacono", "evangelista", "lider", "membro"];
  const STATUS = ["pendente", "aprovado", "inativo"];

  for (const doc of usuarios.docs) {
    const d = doc.data() ?? {};

    const perfilBruto = normalizar(d.perfil);
    const perfil = PERFIS.includes(perfilBruto) ? perfilBruto : "membro";

    const statusBruto = normalizar(d.status);
    const status = STATUS.includes(statusBruto) ? statusBruto : "pendente";

    const vinculoRef = db.doc(`igrejas/${OLINDA}/membros/${doc.id}`);
    if ((await vinculoRef.get()).exists) {
      existentes++;
    } else {
      if (!dryRun) {
        await vinculoRef.set({
          perfil,
          status,
          // Pastor recebe a função administrativa correspondente; nenhuma
          // outra função é inventada na migração.
          funcoes_admin: perfil === "pastor" ? ["pastor"] : [],
          ministerio_ids: d.ministerio_id ? [d.ministerio_id] : [],
          nome: d.nome ?? null,
          email: d.email ?? null,
          aprovado_por: d.aprovado_por ?? null,
          aprovado_em: d.aprovado_em ?? null,
          migrado_de: `usuarios/${doc.id}`,
          migrado_em: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      criados++;
    }

    if (!d.igreja_principal_id) {
      if (!dryRun) {
        await doc.ref.set({ igreja_principal_id: OLINDA }, { merge: true });
      }
      principalDefinida++;
    }
  }

  registrar("membros (vinculos)", usuarios.size, criados, existentes);
  registrar(
    "igreja_principal_id",
    usuarios.size,
    principalDefinida,
    usuarios.size - principalDefinida
  );
}

/**
 * Normaliza as transações para o contrato canônico:
 * `valor_centavos` inteiro, `metodo`, `status` padronizado.
 */
async function migrarTransacoes() {
  const origem = await db.collection("transacoes").get();
  let migradas = 0;
  let existentes = 0;
  let suspeitas = 0;

  const mapaStatus = {
    aprovado: "aprovado",
    approved: "aprovado",
    pendente: "pendente",
    pending: "pendente",
    recusado: "rejeitado",
    rejeitado: "rejeitado",
    rejected: "rejeitado",
    cancelado: "cancelado",
    cancelled: "cancelado",
    estornado: "estornado",
    refunded: "estornado",
  };

  const mapaMetodo = { pix: "pix", checkout: "checkout_pro", checkout_pro: "checkout_pro" };

  for (const doc of origem.docs) {
    const d = doc.data() ?? {};
    const destino = db.doc(`igrejas/${OLINDA}/transacoes/${doc.id}`);

    if ((await destino.get()).exists) {
      existentes++;
      continue;
    }

    // O contrato antigo gravava `valor` em REAIS (float) e o modelo Dart lia
    // centavos. Converte pelo campo de origem, sem adivinhar.
    let valorCentavos = null;
    if (typeof d.valor_centavos === "number") {
      valorCentavos = Math.round(d.valor_centavos);
    } else if (typeof d.valor === "number") {
      valorCentavos = Math.round(d.valor * 100);
    } else {
      // Sem valor reconhecível: migra com 0 e sinaliza para conferência
      // manual, em vez de inventar um número.
      valorCentavos = 0;
      suspeitas++;
    }

    const registro = {
      usuario_id: d.usuario_id ?? d.perfil_id ?? null,
      igreja_id: OLINDA,
      valor_centavos: valorCentavos,
      tipo: d.tipo ?? "oferta",
      metodo: mapaMetodo[normalizarTexto(d.metodo ?? d.meio_pagamento)] ?? "pix",
      status: mapaStatus[normalizarTexto(d.status)] ?? "pendente",
      campanha_id: d.campanha_id ?? null,
      mp_payment_id: d.mp_payment_id ?? null,
      mp_status_detail: d.mp_status_detail ?? null,
      criado_em: d.criado_em ?? null,
      atualizado_em: d.atualizado_em ?? null,
      aprovado_em: d.aprovado_em ?? null,
      migrado_de: `transacoes/${doc.id}`,
      migrado_em: admin.firestore.FieldValue.serverTimestamp(),
      // Marca os casos que exigem conferência humana.
      revisar_valor: valorCentavos === 0 ? true : null,
    };

    if (!dryRun) await destino.set(registro);
    migradas++;
  }

  registrar(
    "transacoes",
    origem.size,
    migradas,
    existentes,
    suspeitas > 0 ? `⚠ ${suspeitas} sem valor reconhecivel (revisar_valor=true)` : ""
  );
}

function normalizarTexto(v) {
  return String(v ?? "").toLowerCase().trim();
}

/** Notificações globais → subcoleção do destinatário. */
async function migrarNotificacoes() {
  const origem = await db.collection("notificacoes").get();
  let migradas = 0;
  let ignoradas = 0;

  for (const doc of origem.docs) {
    const d = doc.data() ?? {};
    const uid = d.destinatario_id;
    if (!uid) {
      ignoradas++;
      continue;
    }
    const destino = db.doc(`usuarios/${uid}/notificacoes/${doc.id}`);
    if ((await destino.get()).exists) {
      ignoradas++;
      continue;
    }
    if (!dryRun) {
      await destino.set({ ...d, migrado_de: `notificacoes/${doc.id}` });
    }
    migradas++;
  }

  registrar("notificacoes", origem.size, migradas, ignoradas);
}

/** Dados institucionais de `igreja/principal` → `igrejas/olinda`. */
async function migrarDadosInstitucionais() {
  const snap = await db.doc("igreja/principal").get();
  if (!snap.exists) {
    registrar("igreja/principal", 0, 0, 0, "(nao existe)");
    return;
  }
  if (!dryRun) {
    await db.doc(`igrejas/${OLINDA}`).set(
      {
        dados_institucionais: snap.data() ?? {},
        configurada: true,
        migrado_de: "igreja/principal",
      },
      { merge: true }
    );
  }
  registrar("igreja/principal", 1, 1, 0);
}

// ── Execução ──────────────────────────────────────────────────────────
(async () => {
  console.log("\n=== MIGRAÇÃO MULTI-IGREJA ===");
  console.log(`Projeto: ${projeto}`);
  console.log(`Modo:    ${dryRun ? "DRY-RUN (nada será gravado)" : "APLICAR (gravação real)"}`);
  console.log("Nenhuma coleção antiga é apagada.\n");

  if (!dryRun) {
    console.log("⚠  Gravação real em 5s. Ctrl+C para cancelar.\n");
    await new Promise((r) => setTimeout(r, 5000));
  }

  await criarUnidades();
  await migrarDadosInstitucionais();
  await migrarVinculos();
  for (const nome of COLECOES) {
    await migrarColecao(nome);
  }
  await migrarTransacoes();
  await migrarNotificacoes();

  const totalMigrado = relatorio.reduce((s, r) => s + r.migrados, 0);
  console.log(`\n=== RESUMO ===`);
  console.log(`Documentos ${dryRun ? "que SERIAM migrados" : "migrados"}: ${totalMigrado}`);
  if (dryRun) {
    console.log("\nNada foi gravado. Para aplicar:");
    console.log(`  node scripts/migrar_producao.js --project=${projeto} --apply\n`);
  } else {
    console.log("\nMigração concluída. As coleções antigas permanecem intactas.");
    console.log("Confira as contagens antes de qualquer limpeza.\n");
  }
  process.exit(0);
})().catch((e) => {
  console.error("\n[ERRO] Migração interrompida:", e);
  console.error("Nada além do que já foi gravado até aqui foi alterado.");
  process.exit(1);
});
