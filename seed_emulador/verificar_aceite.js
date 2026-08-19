/**
 * Verificação de aceite ponta a ponta contra o Emulator Suite.
 *
 * Autentica as contas de teste pela REST API do Auth Emulator e exercita as
 * Callable Functions de verdade, conferindo a matriz de permissões.
 *
 * Uso: node verificar_aceite.js  (com os emuladores no ar e o seed aplicado)
 */
const { exigirEmulador, PROJECT_ID } = require("./guarda");

exigirEmulador();

const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
const FUNCTIONS_HOST = process.env.FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";
const REGIAO = "southamerica-east1";
const SENHA = "Teste123!";

let passou = 0;
let falhou = 0;

function ok(nome, detalhe = "") {
  passou++;
  console.log(`  OK    ${nome}${detalhe ? ` — ${detalhe}` : ""}`);
}

function erro(nome, detalhe) {
  falhou++;
  console.log(`  FALHA ${nome} — ${detalhe}`);
}

async function entrar(email) {
  const resposta = await fetch(
    `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password: SENHA, returnSecureToken: true }),
    }
  );
  const dados = await resposta.json();
  if (!dados.idToken) throw new Error(`login falhou para ${email}: ${JSON.stringify(dados)}`);
  return dados.idToken;
}

async function chamar(nomeFuncao, token, payload) {
  const resposta = await fetch(
    `http://${FUNCTIONS_HOST}/${PROJECT_ID}/${REGIAO}/${nomeFuncao}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ data: payload ?? {} }),
    }
  );
  const corpo = await resposta.json();
  return { status: resposta.status, corpo };
}

async function esperaSucesso(nome, promessa, verificar) {
  try {
    const { status, corpo } = await promessa;
    if (status !== 200 || corpo.error) {
      erro(nome, `esperava sucesso, veio ${status} ${JSON.stringify(corpo.error ?? corpo)}`);
      return null;
    }
    const resultado = corpo.result;
    if (verificar) {
      const problema = verificar(resultado);
      if (problema) {
        erro(nome, problema);
        return null;
      }
    }
    ok(nome);
    return resultado;
  } catch (e) {
    erro(nome, e.message);
    return null;
  }
}

async function esperaNegado(nome, promessa) {
  try {
    const { corpo } = await promessa;
    const codigo = corpo?.error?.status || corpo?.error?.message;
    if (corpo.error) {
      ok(nome, String(codigo));
    } else {
      erro(nome, "esperava negacao, mas a operacao foi PERMITIDA");
    }
  } catch (e) {
    erro(nome, e.message);
  }
}

(async () => {
  console.log("\n=== ACEITE PONTA A PONTA (emulador) ===\n");

  console.log("[login]");
  const tokens = {};
  for (const email of [
    "superadmin@teste.local",
    "pastor.olinda@teste.local",
    "lider.olinda@teste.local",
    "tesoureiro.olinda@teste.local",
    "editor.olinda@teste.local",
    "pastor.petrolina@teste.local",
    "membro@teste.local",
  ]) {
    tokens[email] = await entrar(email);
    ok(`login ${email}`);
  }

  // ── meusAcessos ────────────────────────────────────────────────────
  console.log("\n[meusAcessos]");

  await esperaSucesso(
    "pastor de Olinda ve APENAS Olinda",
    chamar("meusAcessos", tokens["pastor.olinda@teste.local"]),
    (r) => {
      const ids = r.acessos.map((a) => a.igrejaId);
      if (ids.length !== 1 || ids[0] !== "olinda") {
        return `esperava ['olinda'], veio ${JSON.stringify(ids)}`;
      }
      if (!r.acessos[0].capacidades.gerenciarLideranca) return "pastor deveria gerir lideranca";
      if (!r.acessos[0].capacidades.lerFinancas) return "pastor deveria ler financas";
      return null;
    }
  );

  await esperaSucesso(
    "pastor de Petrolina ve APENAS Petrolina",
    chamar("meusAcessos", tokens["pastor.petrolina@teste.local"]),
    (r) => {
      const ids = r.acessos.map((a) => a.igrejaId);
      return ids.length === 1 && ids[0] === "petrolina"
        ? null
        : `esperava ['petrolina'], veio ${JSON.stringify(ids)}`;
    }
  );

  await esperaSucesso(
    "super_admin ve as DUAS unidades",
    chamar("meusAcessos", tokens["superadmin@teste.local"]),
    (r) => {
      const ids = r.acessos.map((a) => a.igrejaId).sort();
      if (JSON.stringify(ids) !== JSON.stringify(["olinda", "petrolina"])) {
        return `esperava as duas, veio ${JSON.stringify(ids)}`;
      }
      return r.isSuperAdmin ? null : "isSuperAdmin deveria ser true";
    }
  );

  await esperaSucesso(
    "lider le financas, mas NAO gere lideranca",
    chamar("meusAcessos", tokens["lider.olinda@teste.local"]),
    (r) => {
      const a = r.acessos[0];
      if (!a?.capacidades.lerFinancas) return "lider deveria ler financas";
      if (a.capacidades.gerenciarLideranca) return "lider NAO deveria gerir lideranca";
      return null;
    }
  );

  await esperaSucesso(
    "tesoureiro (perfil membro) le financas",
    chamar("meusAcessos", tokens["tesoureiro.olinda@teste.local"]),
    (r) => {
      const a = r.acessos[0];
      if (!a?.capacidades.lerFinancas) return "tesoureiro deveria ler financas";
      if (a.perfil !== "membro") return `perfil deveria ser membro, veio ${a.perfil}`;
      return null;
    }
  );

  await esperaSucesso(
    "editor NAO le financas",
    chamar("meusAcessos", tokens["editor.olinda@teste.local"]),
    (r) => {
      const a = r.acessos[0];
      if (a?.capacidades.lerFinancas) return "editor NAO deveria ler financas";
      if (!a?.capacidades.gerenciarConteudo) return "editor deveria gerir conteudo";
      return null;
    }
  );

  await esperaSucesso(
    "membro pendente NAO acessa o painel",
    chamar("meusAcessos", tokens["membro@teste.local"]),
    (r) => (r.acessos.length === 0 ? null : `esperava 0 acessos, veio ${r.acessos.length}`)
  );

  // ── Gestão da liderança ────────────────────────────────────────────
  console.log("\n[lideranca]");

  await esperaNegado(
    "lider NAO remove outro lider",
    chamar("removerDaLideranca", tokens["lider.olinda@teste.local"], {
      igrejaId: "olinda",
      uid: "qualquer",
      motivo: "tentativa indevida",
    })
  );

  await esperaNegado(
    "tesoureiro NAO promove ninguem",
    chamar("promoverParaLideranca", tokens["tesoureiro.olinda@teste.local"], {
      igrejaId: "olinda",
      uid: "qualquer",
      perfil: "lider",
    })
  );

  await esperaNegado(
    "pastor de Olinda NAO age em Petrolina",
    chamar("removerDaLideranca", tokens["pastor.olinda@teste.local"], {
      igrejaId: "petrolina",
      uid: "qualquer",
      motivo: "tentativa cruzada",
    })
  );

  await esperaNegado(
    "rebaixamento SEM motivo e rejeitado",
    chamar("removerDaLideranca", tokens["pastor.olinda@teste.local"], {
      igrejaId: "olinda",
      uid: "qualquer",
      motivo: "",
    })
  );

  // Descobre o uid do segundo líder para o fluxo real de rebaixamento.
  const admin = require("firebase-admin");
  if (admin.apps.length === 0) admin.initializeApp({ projectId: PROJECT_ID });
  const lider2 = await admin.auth().getUserByEmail("lider2.olinda@teste.local");
  const pastorOlinda = await admin.auth().getUserByEmail("pastor.olinda@teste.local");

  await esperaNegado(
    "pastor NAO altera o proprio vinculo",
    chamar("removerDaLideranca", tokens["pastor.olinda@teste.local"], {
      igrejaId: "olinda",
      uid: pastorOlinda.uid,
      motivo: "tentando remover a si mesmo",
    })
  );

  await esperaSucesso(
    "pastor REBAIXA um lider com motivo",
    chamar("removerDaLideranca", tokens["pastor.olinda@teste.local"], {
      igrejaId: "olinda",
      uid: lider2.uid,
      motivo: "Mudanca de ministerio (teste de aceite)",
    }),
    (r) => (r.perfil === "membro" ? null : `esperava perfil membro, veio ${r.perfil}`)
  );

  // Confirma preservação de histórico + auditoria.
  const db = admin.firestore();
  const vinculo = await db.doc(`igrejas/olinda/membros/${lider2.uid}`).get();
  if (!vinculo.exists) {
    erro("vinculo preservado apos rebaixamento", "documento foi APAGADO");
  } else if (vinculo.data().status !== "aprovado") {
    erro("vinculo preservado", `status virou ${vinculo.data().status}, esperava aprovado`);
  } else {
    ok("vinculo preservado e continua aprovado apos rebaixamento");
  }

  const auditoria = await db
    .collection("igrejas/olinda/auditoria")
    .where("acao", "==", "remover_da_lideranca")
    .get();
  if (auditoria.empty) {
    erro("auditoria do rebaixamento", "nenhum registro gravado");
  } else {
    const reg = auditoria.docs[0].data();
    if (!reg.motivo) erro("auditoria do rebaixamento", "motivo ausente");
    else if (reg.antes?.perfil !== "lider")
      erro("auditoria do rebaixamento", `antes.perfil=${reg.antes?.perfil}`);
    else ok("auditoria registrada com motivo e estado anterior", reg.motivo);
  }

  // Restaura o estado para o seed poder ser reaplicado sem surpresa.
  await esperaSucesso(
    "super_admin repromove o lider (restaura o estado)",
    chamar("promoverParaLideranca", tokens["superadmin@teste.local"], {
      igrejaId: "olinda",
      uid: lider2.uid,
      perfil: "lider",
    })
  );

  // ── Aprovação de membro ────────────────────────────────────────────
  console.log("\n[membros]");
  const membroPendente = await admin.auth().getUserByEmail("membro@teste.local");

  await esperaNegado(
    "editor NAO aprova membro",
    chamar("aprovarMembro", tokens["editor.olinda@teste.local"], {
      igrejaId: "olinda",
      uid: membroPendente.uid,
    })
  );

  await esperaSucesso(
    "lider APROVA cadastro pendente",
    chamar("aprovarMembro", tokens["lider.olinda@teste.local"], {
      igrejaId: "olinda",
      uid: membroPendente.uid,
    }),
    (r) => (r.status === "aprovado" ? null : `status ${r.status}`)
  );

  // ── Igrejas ────────────────────────────────────────────────────────
  console.log("\n[igrejas]");

  const igrejaAceiteRef = db.doc("igrejas/unidade_teste_aceite");
  const catalogoAceiteRef = db.doc("catalogo_igrejas/unidade_teste_aceite");

  // Remove resíduos de uma execução anterior interrompida. Apagar apenas o
  // documento raiz não remove a subcoleção de auditoria no Firestore.
  await Promise.all([
    db.recursiveDelete(igrejaAceiteRef),
    catalogoAceiteRef.delete(),
  ]);

  await esperaNegado(
    "pastor NAO cria unidade (so super_admin)",
    chamar("criarIgreja", tokens["pastor.olinda@teste.local"], {
      igrejaId: "unidade_pirata",
      nome: "Unidade Pirata",
    })
  );

  await esperaSucesso(
    "super_admin cria unidade (nasce inativa/nao configurada)",
    chamar("criarIgreja", tokens["superadmin@teste.local"], {
      igrejaId: "unidade_teste_aceite",
      nome: "Unidade de Teste do Aceite",
    })
  );

  const [nova, novoCatalogo] = await Promise.all([
    igrejaAceiteRef.get(),
    catalogoAceiteRef.get(),
  ]);
  if (nova.data()?.ativa === false && nova.data()?.configurada === false) {
    ok("unidade nova nasce inativa e nao configurada");
  } else {
    erro("unidade nova", `ativa=${nova.data()?.ativa} configurada=${nova.data()?.configurada}`);
  }
  const camposPublicos = [
    "nome",
    "ativa",
    "configurada",
    "endereco",
    "cidade_estado",
    "endereco_secundario",
    "slogan",
    "cultos_recorrentes",
    "instagram",
    "youtube_url",
    "pastores_publicos",
  ];
  if (!novoCatalogo.exists) {
    erro("catalogo da unidade nova", "documento catalogo_igrejas ausente");
  } else if (
    JSON.stringify(Object.keys(novoCatalogo.data()).sort()) !==
    JSON.stringify([...camposPublicos].sort())
  ) {
    erro(
      "catalogo da unidade nova",
      `campos inesperados: ${JSON.stringify(Object.keys(novoCatalogo.data()).sort())}`
    );
  } else if (
    novoCatalogo.data().ativa !== false ||
    novoCatalogo.data().configurada !== false
  ) {
    erro(
      "catalogo da unidade nova",
      `ativa=${novoCatalogo.data().ativa} configurada=${novoCatalogo.data().configurada}`
    );
  } else if (
    novoCatalogo.data().endereco !== null ||
    novoCatalogo.data().cidade_estado !== null ||
    novoCatalogo.data().endereco_secundario !== null ||
    novoCatalogo.data().slogan !== null ||
    novoCatalogo.data().instagram !== null ||
    novoCatalogo.data().youtube_url !== null ||
    !Array.isArray(novoCatalogo.data().cultos_recorrentes) ||
    novoCatalogo.data().cultos_recorrentes.length !== 0 ||
    !Array.isArray(novoCatalogo.data().pastores_publicos) ||
    novoCatalogo.data().pastores_publicos.length !== 0
  ) {
    erro("catalogo da unidade nova", "defaults públicos inesperados");
  } else {
    ok("catalogo publico nasce junto e com contrato exato");
  }

  await Promise.all([
    db.recursiveDelete(igrejaAceiteRef),
    catalogoAceiteRef.delete(),
  ]);

  const [igrejaAposLimpeza, catalogoAposLimpeza, auditoriaAposLimpeza] = await Promise.all([
    igrejaAceiteRef.get(),
    catalogoAceiteRef.get(),
    igrejaAceiteRef.collection("auditoria").limit(1).get(),
  ]);
  if (
    igrejaAposLimpeza.exists ||
    catalogoAposLimpeza.exists ||
    !auditoriaAposLimpeza.empty
  ) {
    erro(
      "limpeza da unidade de aceite",
      `raiz=${igrejaAposLimpeza.exists} catalogo=${catalogoAposLimpeza.exists} auditoria=${auditoriaAposLimpeza.size}`
    );
  } else {
    ok("limpeza remove raiz, catalogo e auditoria para permitir rerun");
  }

  console.log(`\n=== RESULTADO: ${passou} ok, ${falhou} falha(s) ===\n`);
  process.exit(falhou > 0 ? 1 : 0);
})().catch((e) => {
  console.error("\n[ERRO FATAL]", e);
  process.exit(1);
});
