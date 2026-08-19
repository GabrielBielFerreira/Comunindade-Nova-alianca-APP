'use strict';

const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const test = require('node:test');

const script = path.join(__dirname, 'verificar_producao.js');

function executar(sobrescritas = {}) {
  const env = { ...process.env };
  for (const nome of [
    'FB_API_KEY',
    'FB_APP_ID',
    'FB_SENDER_ID',
    'FB_PROJECT_ID',
    'FB_AUTH_DOMAIN',
    'FB_STORAGE_BUCKET',
  ]) {
    delete env[nome];
  }

  Object.assign(env, {
    FB_API_KEY: 'chave-web-real',
    FB_APP_ID: '1:335786267314:web:teste',
    FB_SENDER_ID: '335786267314',
    FB_PROJECT_ID: 'nova-alianca-app',
    FB_AUTH_DOMAIN: 'nova-alianca-app.firebaseapp.com',
    ...sobrescritas,
  });

  return spawnSync(process.execPath, [script, '--painel'], {
    encoding: 'utf8',
    env,
  });
}

test('painel reprova quando FB_STORAGE_BUCKET esta ausente', () => {
  const resultado = executar();

  assert.equal(resultado.status, 1);
  assert.match(resultado.stdout, /FB_STORAGE_BUCKET/);
});

test('painel reprova bucket legado appspot em producao', () => {
  const resultado = executar({
    FB_STORAGE_BUCKET: 'nova-alianca-app.appspot.com',
  });

  assert.equal(resultado.status, 1);
  assert.match(resultado.stdout, /nova-alianca-app\.appspot\.com/);
  assert.match(resultado.stdout, /nova-alianca-app\.firebasestorage\.app/);
});

test('painel aprova somente o bucket firebasestorage esperado', () => {
  const resultado = executar({
    FB_STORAGE_BUCKET: 'nova-alianca-app.firebasestorage.app',
  });

  assert.equal(resultado.status, 0, resultado.stdout + resultado.stderr);
  assert.match(resultado.stdout, /APROVADO/);
});
