#!/usr/bin/env node
/**
 * Trava fail-closed para builds de produção.
 *
 * Roda ANTES (e depois) de gerar um artefato chamado de produção e recusa a
 * operação quando a configuração ainda é a local. Sem esta trava, um
 * `flutter build apk --release` feito na máquina de desenvolvimento produz um
 * APK que parece de produção e aponta para o emulador — falha silenciosa e
 * cara de descobrir.
 *
 * A trava NEGA POR PADRÃO: qualquer dúvida (arquivo ausente, projeto
 * inesperado, marcador de emulador) resulta em saída diferente de zero.
 *
 * Uso:
 *   node scripts/verificar_producao.js --app
 *   node scripts/verificar_producao.js --painel
 *   node scripts/verificar_producao.js --artefato build/app/outputs/flutter-apk/app-release.apk
 *   node scripts/verificar_producao.js --app --artefato <caminho>
 *
 * Variáveis aceitas para o painel (mesmas do --dart-define):
 *   FB_API_KEY, FB_APP_ID, FB_SENDER_ID, FB_PROJECT_ID
 */

'use strict';

const fs = require('fs');
const path = require('path');

const RAIZ = path.resolve(__dirname, '..');
const PROJETO_ESPERADO = 'nova-alianca-app';
const PACOTE_ANDROID_ESPERADO = 'br.com.novaalianca.nova_alianca_app';

/** Marcadores que NUNCA podem existir num artefato de produção. */
const MARCADORES_PROIBIDOS = [
  'demo-nova-alianca',
  'fake-api-key',
  '10.0.2.2',
  'useFirestoreEmulator',
  'useAuthEmulator',
  'useFunctionsEmulator',
];

const erros = [];
const avisos = [];
const ok = [];

function falhar(mensagem) {
  erros.push(mensagem);
}

function passou(mensagem) {
  ok.push(mensagem);
}

function lerArquivo(relativo) {
  const completo = path.join(RAIZ, relativo);
  if (!fs.existsSync(completo)) return null;
  return fs.readFileSync(completo, 'utf8');
}

// ── Aplicativo móvel ────────────────────────────────────────────────────

function verificarApp() {
  // 1. firebase_options.dart precisa existir e NÃO ser o placeholder.
  const opcoes = lerArquivo('lib/firebase_options.dart');
  if (opcoes === null) {
    falhar(
      'lib/firebase_options.dart nao existe.\n' +
        '    Gere com: flutterfire configure --project=' +
        PROJETO_ESPERADO +
        ' --platforms=android,web'
    );
  } else if (
    opcoes.includes('PLACEHOLDER LOCAL') ||
    opcoes.includes('Configuração de produção do Firebase ausente')
  ) {
    falhar(
      'lib/firebase_options.dart ainda e o PLACEHOLDER local.\n' +
        '    Um build de producao com este arquivo nao consegue conectar ao Firebase real.\n' +
        '    Gere o arquivo verdadeiro: flutterfire configure --project=' +
        PROJETO_ESPERADO
    );
  } else if (!opcoes.includes(PROJETO_ESPERADO)) {
    falhar(
      'lib/firebase_options.dart nao menciona o projeto "' +
        PROJETO_ESPERADO +
        '".\n' +
        '    Confirme que o flutterfire apontou para o projeto certo.'
    );
  } else {
    passou('lib/firebase_options.dart e real e aponta para ' + PROJETO_ESPERADO);
  }

  // 2. google-services.json precisa existir, com projeto e pacote corretos.
  const gsBruto = lerArquivo('android/app/google-services.json');
  if (gsBruto === null) {
    falhar(
      'android/app/google-services.json nao existe.\n' +
        '    Sem ele o build Android nao se conecta ao Firebase real.\n' +
        '    Gere com: flutterfire configure --project=' + PROJETO_ESPERADO
    );
  } else {
    let gs;
    try {
      gs = JSON.parse(gsBruto);
    } catch (e) {
      falhar('android/app/google-services.json nao e um JSON valido: ' + e.message);
      gs = null;
    }

    if (gs) {
      const projeto =
        gs.project_info && gs.project_info.project_id
          ? gs.project_info.project_id
          : '(ausente)';
      if (projeto !== PROJETO_ESPERADO) {
        falhar(
          'google-services.json aponta para o projeto "' +
            projeto +
            '", e nao "' +
            PROJETO_ESPERADO +
            '".'
        );
      } else {
        passou('google-services.json aponta para ' + PROJETO_ESPERADO);
      }

      const pacotes = (gs.client || [])
        .map((c) =>
          c.client_info &&
          c.client_info.android_client_info &&
          c.client_info.android_client_info.package_name
            ? c.client_info.android_client_info.package_name
            : null
        )
        .filter(Boolean);

      if (!pacotes.includes(PACOTE_ANDROID_ESPERADO)) {
        falhar(
          'google-services.json nao registra o pacote "' +
            PACOTE_ANDROID_ESPERADO +
            '".\n' +
            '    Pacotes encontrados: ' +
            (pacotes.length ? pacotes.join(', ') : '(nenhum)')
        );
      } else {
        passou('Pacote Android registrado: ' + PACOTE_ANDROID_ESPERADO);
      }
    }
  }

  // 3. Assinatura de release. A chave de debug NAO pode assinar um piloto.
  const keyProps = lerArquivo('android/key.properties');
  if (keyProps === null) {
    avisos.push(
      'android/key.properties nao existe: o Gradle cairia na chave de DEBUG.\n' +
        '    Gere a keystore e o key.properties antes de distribuir o APK.\n' +
        '    (Nao bloqueia builds de teste, mas bloqueia --exigir-assinatura.)'
    );
  } else {
    passou('android/key.properties presente');
  }
}

// ── Painel web ──────────────────────────────────────────────────────────

function verificarPainel() {
  const exigidas = ['FB_API_KEY', 'FB_APP_ID', 'FB_PROJECT_ID'];

  const ausentes = exigidas.filter(
    (nome) => !process.env[nome] || process.env[nome].trim() === ''
  );

  if (ausentes.length) {
    falhar(
      'Configuracao do painel ausente: ' +
        ausentes.join(', ') +
        '.\n' +
        '    Exporte as variaveis (ou passe os mesmos valores por --dart-define)\n' +
        '    com a saida do flutterfire para o app Web de ' + PROJETO_ESPERADO + '.'
    );
  } else {
    passou('Variaveis do painel presentes: ' + exigidas.join(', '));
  }

  const projeto = (process.env.FB_PROJECT_ID || '').trim();
  if (projeto && projeto !== PROJETO_ESPERADO) {
    falhar(
      'FB_PROJECT_ID e "' + projeto + '", e nao "' + PROJETO_ESPERADO + '".'
    );
  }

  const apiKey = (process.env.FB_API_KEY || '').trim();
  if (apiKey && apiKey.includes('fake')) {
    falhar('FB_API_KEY parece ser a chave falsa do emulador.');
  }
}

// ── Artefato gerado ─────────────────────────────────────────────────────

function verificarArtefato(caminho) {
  const completo = path.isAbsolute(caminho) ? caminho : path.join(RAIZ, caminho);

  if (!fs.existsSync(completo)) {
    falhar('Artefato nao encontrado: ' + caminho);
    return;
  }

  // Busca binária no arquivo cru.
  //
  // Em `main.dart.js` (texto) a busca é confiável nos dois sentidos. Num APK
  // as strings ficam DEFLATADAS dentro do zip, então a ausência de um
  // marcador proibido não prova nada — mas a PRESENÇA do projeto esperado
  // prova que a configuração real entrou. Por isso a checagem positiva
  // abaixo é a que decide para APK, e ela é obrigatória.
  const conteudo = fs.readFileSync(completo);
  const encontrados = MARCADORES_PROIBIDOS.filter((marcador) =>
    conteudo.includes(marcador)
  );

  if (encontrados.length) {
    falhar(
      'O artefato "' +
        caminho +
        '" contem marcadores de emulador: ' +
        encontrados.join(', ') +
        '.\n' +
        '    Este build NAO pode ser distribuido como producao.'
    );
  } else {
    passou('Artefato sem marcadores de emulador: ' + caminho);
  }

  if (!conteudo.includes(PROJETO_ESPERADO)) {
    falhar(
      'O artefato "' +
        caminho +
        '" nao referencia o projeto "' +
        PROJETO_ESPERADO +
        '".\n' +
        '    Provavelmente foi construido sem a configuracao real.'
    );
  } else {
    passou('Artefato referencia ' + PROJETO_ESPERADO);
  }
}

// ── Execução ────────────────────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes('--ajuda') || args.includes('-h')) {
    console.log(
      'Uso:\n' +
        '  node scripts/verificar_producao.js --app\n' +
        '  node scripts/verificar_producao.js --painel\n' +
        '  node scripts/verificar_producao.js --artefato <caminho>\n' +
        '  node scripts/verificar_producao.js --app --exigir-assinatura\n'
    );
    process.exit(args.length === 0 ? 2 : 0);
  }

  console.log('\n=== Verificacao fail-closed de producao ===');
  console.log('Projeto Firebase exigido: ' + PROJETO_ESPERADO + '\n');

  if (args.includes('--app')) verificarApp();
  if (args.includes('--painel')) verificarPainel();

  const i = args.indexOf('--artefato');
  if (i !== -1) {
    if (!args[i + 1]) {
      falhar('--artefato exige um caminho.');
    } else {
      verificarArtefato(args[i + 1]);
    }
  }

  // Sem --exigir-assinatura, a falta de keystore e apenas aviso: builds de
  // teste interno sao legitimos. Com a flag, vira erro.
  if (args.includes('--exigir-assinatura')) {
    const pendente = avisos.filter((a) => a.includes('key.properties'));
    pendente.forEach((a) => falhar(a));
  }

  ok.forEach((m) => console.log('  [ok]     ' + m));
  avisos.forEach((m) => console.log('  [aviso]  ' + m));
  erros.forEach((m) => console.log('  [ERRO]   ' + m));

  console.log('');
  if (erros.length) {
    console.error(
      'REPROVADO: ' +
        erros.length +
        ' problema(s). Nenhum build de producao deve ser gerado ou publicado.\n'
    );
    process.exit(1);
  }

  console.log('APROVADO: configuracao compativel com producao.\n');
  process.exit(0);
}

main();
