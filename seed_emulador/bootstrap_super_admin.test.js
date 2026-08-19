'use strict';

const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const test = require('node:test');

const script = path.join(__dirname, 'bootstrap_super_admin.js');

function executar(sobrescritas = {}) {
  const env = { ...process.env };
  for (const nome of [
    'FIREBASE_AUTH_EMULATOR_HOST',
    'GCLOUD_PROJECT',
    'GOOGLE_CLOUD_PROJECT',
    'FIREBASE_PROJECT_ID',
    'GOOGLE_APPLICATION_CREDENTIALS',
  ]) {
    delete env[nome];
  }

  Object.assign(env, {
    PERMITIR_PRODUCAO: '1',
    ...sobrescritas,
  });

  return spawnSync(process.execPath, [script, '--uid', 'uid-nao-utilizado'], {
    encoding: 'utf8',
    env,
  });
}

test('producao aborta para qualquer projectId diferente do oficial', () => {
  const resultado = executar({ GCLOUD_PROJECT: 'outro-projeto' });

  assert.equal(resultado.status, 1);
  assert.match(resultado.stderr, /deve ser exatamente "nova-alianca-app"/);
});

test('producao aborta quando variaveis de projeto divergem', () => {
  const resultado = executar({
    GCLOUD_PROJECT: 'nova-alianca-app',
    GOOGLE_CLOUD_PROJECT: 'projeto-inesperado',
  });

  assert.equal(resultado.status, 1);
  assert.match(resultado.stderr, /Variaveis divergentes/);
});

test('producao aborta antes do Auth quando ADC e invalida', () => {
  const resultado = executar({
    GCLOUD_PROJECT: 'nova-alianca-app',
    GOOGLE_APPLICATION_CREDENTIALS: path.join(
      __dirname,
      'credencial-que-nao-existe.json'
    ),
  });

  assert.equal(resultado.status, 1);
  assert.match(resultado.stderr, /Application Default Credentials/);
  assert.doesNotMatch(resultado.stderr, /concedendo super_admin/);
});
