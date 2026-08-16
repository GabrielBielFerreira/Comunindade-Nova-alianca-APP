/**
 * Preflight dos testes de Rules.
 *
 * No Windows, `firebase emulators:exec` encerra o hub mas o processo Java do
 * Firestore Emulator sobrevive ao SIGINT, deixando a porta 8080 ocupada e
 * fazendo a execução seguinte falhar com "port taken".
 *
 * Este script libera a porta encerrando APENAS um processo cuja linha de
 * comando comprove ser o Firestore Emulator (jar `cloud-firestore-emulator`).
 * Qualquer outro processo na porta é reportado e preservado — nunca matamos
 * Java/Firebase de terceiros.
 */
const { execSync } = require("child_process");

const PORTA = Number(process.env.FIRESTORE_EMULATOR_PORT || 8080);
const ASSINATURA = "cloud-firestore-emulator";

function powershell(comando) {
  return execSync(`powershell -NoProfile -Command "${comando.replace(/"/g, '\\"')}"`, {
    encoding: "utf8",
  }).trim();
}

function pidsNaPorta(porta) {
  if (process.platform !== "win32") return [];
  try {
    const saida = powershell(
      `(Get-NetTCPConnection -LocalPort ${porta} -State Listen -ErrorAction SilentlyContinue).OwningProcess`
    );
    return [...new Set(saida.split(/\r?\n/).map((s) => s.trim()).filter(Boolean))];
  } catch {
    return [];
  }
}

function linhaDeComando(pid) {
  try {
    return powershell(
      `(Get-CimInstance Win32_Process -Filter 'ProcessId=${pid}' -ErrorAction SilentlyContinue).CommandLine`
    );
  } catch {
    return "";
  }
}

function main() {
  const pids = pidsNaPorta(PORTA);
  if (pids.length === 0) {
    console.log(`[preflight] porta ${PORTA} livre.`);
    return;
  }

  for (const pid of pids) {
    const cmd = linhaDeComando(pid);
    if (!cmd.includes(ASSINATURA)) {
      console.error(
        `[preflight] porta ${PORTA} ocupada pelo PID ${pid}, que NAO e o Firestore Emulator.\n` +
          `[preflight] comando: ${cmd}\n` +
          `[preflight] processo preservado. Libere a porta manualmente e rode de novo.`
      );
      process.exit(1);
    }

    console.log(`[preflight] encerrando Firestore Emulator orfao (PID ${pid}).`);
    try {
      powershell(`Stop-Process -Id ${pid} -Force -ErrorAction SilentlyContinue`);
    } catch {
      /* processo ja saiu */
    }
  }

  // Confirma a liberação antes de devolver o controle ao emulators:exec.
  const fim = Date.now() + 10000;
  while (Date.now() < fim) {
    if (pidsNaPorta(PORTA).length === 0) {
      console.log(`[preflight] porta ${PORTA} liberada.`);
      return;
    }
    execSync("powershell -NoProfile -Command \"Start-Sleep -Milliseconds 300\"");
  }

  console.error(`[preflight] porta ${PORTA} continua ocupada apos o encerramento.`);
  process.exit(1);
}

main();
