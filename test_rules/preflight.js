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

/**
 * Encerra processos ÓRFÃOS dos emuladores, mesmo sem porta ocupada.
 *
 * Checar só a porta 8080 não bastava: o Firestore Emulator e o
 * `cloud-storage-rules-runtime` sobrevivem ao SIGINT do `emulators:exec` sem
 * necessariamente continuar escutando. Na execução seguinte o emulador novo
 * morria com "exited with code 4294967295" e TODOS os testes falhavam — um
 * problema de ambiente que parece falha de regra.
 *
 * A seleção é por ASSINATURA DA LINHA DE COMANDO (o caminho do .jar dentro de
 * `.cache/firebase/emulators`). Nunca por nome de processo: esta máquina roda
 * Gradle, Android Studio e VS Code em Java, e matar por nome derrubaria tudo.
 */
function encerrarOrfaosDoEmulador() {
  if (process.platform !== "win32") return;

  const ASSINATURAS = [
    "cloud-firestore-emulator",
    "cloud-storage-rules-runtime",
  ];

  let saida;
  try {
    // Só aspas simples: o wrapper `powershell()` escapa aspas duplas, e um
    // -Filter com aspas duplas aqui chega deformado ao PowerShell.
    saida = powershell(
      "Get-CimInstance Win32_Process | " +
        "Where-Object { $_.Name -eq 'java.exe' -and $_.CommandLine } | " +
        "ForEach-Object { $_.ProcessId.ToString() + '|' + $_.CommandLine }"
    );
  } catch {
    return; // sem WMI disponível, segue o fluxo normal
  }

  for (const linha of saida.split(/\r?\n/)) {
    const corte = linha.indexOf("|");
    if (corte < 0) continue;
    const pid = linha.slice(0, corte).trim();
    const cmd = linha.slice(corte + 1);
    if (!ASSINATURAS.some((a) => cmd.includes(a))) continue;

    console.log(`[preflight] encerrando emulador orfao (PID ${pid}).`);
    try {
      powershell(`Stop-Process -Id ${pid} -Force -ErrorAction SilentlyContinue`);
    } catch {
      /* processo ja saiu */
    }
  }
}

function main() {
  encerrarOrfaosDoEmulador();

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
