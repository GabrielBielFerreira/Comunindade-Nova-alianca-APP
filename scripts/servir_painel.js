/**
 * Servidor estático mínimo para `admin_web/build/web`.
 *
 * Usado para abrir o painel já compilado sem depender do `flutter run`.
 * Só serve arquivos locais; não é servidor de produção.
 *
 * Uso: node scripts/servir_painel.js [porta]
 */
const http = require("http");
const fs = require("fs");
const path = require("path");

const PORTA = Number(process.argv[2] || 5555);
const RAIZ = path.resolve(__dirname, "..", "admin_web", "build", "web");

const TIPOS = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".wasm": "application/wasm",
  ".ttf": "font/ttf",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".otf": "font/otf",
  ".symbols": "text/plain; charset=utf-8",
};

if (!fs.existsSync(RAIZ)) {
  console.error(`[servir] ${RAIZ} nao existe. Rode antes: cd admin_web && flutter build web`);
  process.exit(1);
}

http
  .createServer((req, res) => {
    const url = decodeURIComponent((req.url || "/").split("?")[0]);
    let arquivo = path.join(RAIZ, url);

    // Impede sair da raiz servida.
    if (!arquivo.startsWith(RAIZ)) {
      res.writeHead(403).end("proibido");
      return;
    }

    if (fs.existsSync(arquivo) && fs.statSync(arquivo).isDirectory()) {
      arquivo = path.join(arquivo, "index.html");
    }
    // SPA: rotas do GoRouter (/dashboard, /membros...) caem no index.html.
    if (!fs.existsSync(arquivo)) {
      arquivo = path.join(RAIZ, "index.html");
    }

    const tipo = TIPOS[path.extname(arquivo).toLowerCase()] || "application/octet-stream";
    res.writeHead(200, {
      "Content-Type": tipo,
      // Necessário para o CanvasKit/wasm do Flutter Web.
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "credentialless",
      "Cache-Control": "no-store",
    });
    fs.createReadStream(arquivo).pipe(res);
  })
  .listen(PORTA, "127.0.0.1", () => {
    console.log(`[servir] painel em http://127.0.0.1:${PORTA}`);
    console.log(`[servir] raiz: ${RAIZ}`);
  });
