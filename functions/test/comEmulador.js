/**
 * Roda os testes das Functions dentro do Firestore Emulator.
 *
 * O binário do `firebase-tools` não é duplicado aqui: ele já existe em
 * `test_rules/node_modules` (testes de Rules). Este runner procura o pacote
 * nos dois lugares e reaproveita o `preflight.js`, que no Windows libera a
 * porta 8080 deixada por um emulador órfão.
 *
 * O CLI é chamado pelo seu entrypoint JS com o próprio Node, e não pelo
 * `.cmd` do `.bin`: o caminho deste repositório contém espaços, e o wrapper
 * de shell do Windows quebraria em "C:\Users\Jean\Downloads\CNA".
 */
const { existsSync } = require("node:fs");
const { spawnSync } = require("node:child_process");
const path = require("node:path");

const RAIZ_FUNCTIONS = path.resolve(__dirname, "..");
const RAIZ_REPO = path.resolve(RAIZ_FUNCTIONS, "..");
const PROJETO = "demo-nova-alianca";

const ENTRYPOINT = path.join("firebase-tools", "lib", "bin", "firebase.js");

const candidatos = [
  path.join(RAIZ_FUNCTIONS, "node_modules", ENTRYPOINT),
  path.join(RAIZ_REPO, "test_rules", "node_modules", ENTRYPOINT),
];

const firebase = candidatos.find((caminho) => existsSync(caminho));

if (!firebase) {
  console.error(
    "[testes] firebase-tools nao encontrado.\n" +
      "[testes] Instale as dependencias dos testes de Rules uma vez:\n" +
      "[testes]   npm --prefix ../test_rules install"
  );
  process.exit(1);
}

// Libera a porta 8080 quando um emulador anterior nao encerrou (Windows).
const preflight = path.join(RAIZ_REPO, "test_rules", "preflight.js");
if (existsSync(preflight)) {
  const saida = spawnSync(process.execPath, [preflight], { stdio: "inherit" });
  if (saida.status !== 0) process.exit(saida.status ?? 1);
}

const resultado = spawnSync(
  process.execPath,
  [
    firebase,
    "emulators:exec",
    "--only",
    "firestore",
    "--project",
    PROJETO,
    "node --test --test-concurrency=1 test/transferencia.test.js test/pedido_oracao_urgente.test.js",
  ],
  { cwd: RAIZ_FUNCTIONS, stdio: "inherit" }
);

process.exit(resultado.status ?? 1);
