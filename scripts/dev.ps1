<#
.SYNOPSIS
  Sobe o ambiente local completo do painel Nova Aliança.

.DESCRIPTION
  1. Libera portas de emulador ocupadas por processos órfãos (só emuladores).
  2. Compila as Cloud Functions (TypeScript).
  3. Inicia o Emulator Suite (Auth, Firestore, Functions, Storage, UI).
  4. Aplica o seed de demonstração.
  5. Inicia o admin_web no Chrome.

  Tudo contra o projeto `demo-nova-alianca`. Nada toca produção.

.PARAMETER SemSeed
  Não aplica o seed (mantém os dados já criados nesta sessão de emulador).

.PARAMETER SemPainel
  Sobe apenas os emuladores e o seed, sem abrir o Chrome.

.EXAMPLE
  .\scripts\dev.ps1
  .\scripts\dev.ps1 -SemPainel
#>
param(
  [switch]$SemSeed,
  [switch]$SemPainel
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$PROJETO = "demo-nova-alianca"
$PORTAS = @(9099, 8080, 5001, 9199, 4000, 4400, 4500, 9150)

function Escrever($texto, $cor = "Cyan") {
  Write-Host "`n[dev] $texto" -ForegroundColor $cor
}

# ── 1. Libera portas ocupadas por emuladores órfãos ────────────────────
Escrever "Verificando portas do Emulator Suite..."
foreach ($porta in $PORTAS) {
  $conexoes = Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue
  foreach ($pid8 in ($conexoes.OwningProcess | Sort-Object -Unique)) {
    $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$pid8" -ErrorAction SilentlyContinue).CommandLine
    # Só encerra o que comprovadamente é emulador do Firebase.
    if ($cmd -match "cloud-firestore-emulator|firebase-tools|cloud-storage-rules|firebase\.tools") {
      Write-Host "  porta $porta ocupada por emulador orfao (PID $pid8) - encerrando" -ForegroundColor Yellow
      Stop-Process -Id $pid8 -Force -ErrorAction SilentlyContinue
    } else {
      Write-Host "  porta $porta ocupada por processo NAO-emulador (PID $pid8) - preservado" -ForegroundColor Red
      Write-Host "  $cmd"
      throw "Libere a porta $porta manualmente antes de continuar."
    }
  }
}

# ── 2. Dependências e build ────────────────────────────────────────────
if (-not (Test-Path "$raiz\test_rules\node_modules")) {
  Escrever "Instalando dependencias de test_rules (firebase-tools local)..."
  Push-Location "$raiz\test_rules"; npm install | Out-Null; Pop-Location
}
if (-not (Test-Path "$raiz\functions\node_modules")) {
  Escrever "Instalando dependencias das Functions..."
  Push-Location "$raiz\functions"; npm install | Out-Null; Pop-Location
}
if (-not (Test-Path "$raiz\seed_emulador\node_modules")) {
  Escrever "Instalando dependencias do seed..."
  Push-Location "$raiz\seed_emulador"; npm install | Out-Null; Pop-Location
}

Escrever "Compilando as Cloud Functions..."
Push-Location "$raiz\functions"; npm run build; Pop-Location

# firebase-tools local — nada é instalado globalmente.
$firebase = "$raiz\test_rules\node_modules\.bin\firebase.cmd"
if (-not (Test-Path $firebase)) { throw "firebase-tools local nao encontrado em $firebase" }

# ── 3. Emuladores ──────────────────────────────────────────────────────
Escrever "Iniciando o Emulator Suite (projeto $PROJETO)..."
$emulador = Start-Process -FilePath $firebase `
  -ArgumentList @("emulators:start", "--only", "auth,firestore,functions,storage", "--project", $PROJETO) `
  -WorkingDirectory $raiz -PassThru -NoNewWindow

Escrever "Aguardando os emuladores responderem..."
# A porta ficar em LISTEN nao significa que o emulador esta pronto: o processo
# do Firestore aceita a conexao antes de servir gRPC, e o seed morre com
# DEADLINE_EXCEEDED. Por isso exigimos resposta HTTP de verdade. Na primeira
# execução, o Firebase CLI também pode baixar o runtime local do Storage (cerca
# de 53 MB), então a margem precisa comportar conexões mais lentas.
$tempoEsperaSegundos = 600
$limite = (Get-Date).AddSeconds($tempoEsperaSegundos)
$fsOk = $false; $authOk = $false; $fnOk = $false
while ((Get-Date) -lt $limite) {
  if (-not $fsOk) {
    try { $null = Invoke-WebRequest "http://127.0.0.1:8080/" -UseBasicParsing -TimeoutSec 3; $fsOk = $true }
    catch { if ($_.Exception.Response) { $fsOk = $true } }
  }
  if (-not $authOk) {
    try { $null = Invoke-WebRequest "http://127.0.0.1:9099/" -UseBasicParsing -TimeoutSec 3; $authOk = $true } catch {}
  }
  if (-not $fnOk) {
    # Em alguns ambientes isolados do Windows, Get-NetTCPConnection nao enxerga
    # listeners iniciados pelo processo filho, mesmo com o endpoint acessivel.
    # Uma resposta HTTP (inclusive 404 na raiz) comprova que o emulador iniciou.
    try { $null = Invoke-WebRequest "http://127.0.0.1:5001/" -UseBasicParsing -TimeoutSec 3; $fnOk = $true }
    catch { if ($_.Exception.Response) { $fnOk = $true } }
  }
  if ($fsOk -and $authOk -and $fnOk) { break }
  if ($emulador.HasExited) { throw "Os emuladores encerraram inesperadamente." }
  Start-Sleep -Milliseconds 900
}
if (-not ($fsOk -and $authOk -and $fnOk)) {
  throw "Emuladores nao ficaram prontos em ${tempoEsperaSegundos}s (firestore=$fsOk auth=$authOk functions=$fnOk)."
}
Write-Host "  Auth, Firestore e Functions respondendo." -ForegroundColor Green

# ── 4. Seed ────────────────────────────────────────────────────────────
if (-not $SemSeed) {
  Escrever "Aplicando o seed de demonstracao..."
  $env:FIRESTORE_EMULATOR_HOST     = "127.0.0.1:8080"
  $env:FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"
  $env:GCLOUD_PROJECT              = $PROJETO
  Push-Location "$raiz\seed_emulador"; node seed_emulador.js; Pop-Location
}

Escrever "Emulator UI: http://127.0.0.1:4000" "Green"

# ── 5. Painel ──────────────────────────────────────────────────────────
if (-not $SemPainel) {
  Escrever "Iniciando o painel no Chrome (admin_web)..."
  Write-Host "  Contas de teste: senha Teste123!" -ForegroundColor Green
  Write-Host "    superadmin@teste.local        (super_admin)"
  Write-Host "    pastor.olinda@teste.local     (pastor de Olinda)"
  Write-Host "    lider.olinda@teste.local      (lider de Olinda)"
  Write-Host "    tesoureiro.olinda@teste.local (tesoureiro)"
  Write-Host "    editor.olinda@teste.local     (editor, sem financas)"
  Write-Host "    pastor.petrolina@teste.local  (pastor de Petrolina)"
  Write-Host "    membro@teste.local            (pendente, sem painel)"
  Push-Location "$raiz\admin_web"
  flutter run -d chrome --web-port 5555
  Pop-Location
} else {
  Escrever "Emuladores no ar. Ctrl+C para encerrar." "Green"
  Wait-Process -Id $emulador.Id
}
