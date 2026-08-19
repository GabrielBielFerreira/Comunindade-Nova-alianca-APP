"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  endpointDocumentos,
  exigirNegado,
  tipoListaDeTextosSanitizados,
  validarDocumentoRest,
} = require("../verificar_catalogo_publico");

function camposCatalogoRest() {
  return {
    nome: { stringValue: "Nova Aliança Olinda" },
    ativa: { booleanValue: true },
    configurada: { booleanValue: true },
    endereco: { nullValue: null },
    cidade_estado: { stringValue: "Olinda - PE" },
    endereco_secundario: { nullValue: null },
    slogan: { stringValue: "Família para pertencer" },
    cultos_recorrentes: {
      arrayValue: { values: [{ stringValue: "Domingo 18h" }] },
    },
    instagram: { stringValue: "@novaalianca" },
    youtube_url: { nullValue: null },
    pastores_publicos: { arrayValue: {} },
  };
}

test("canário de privacidade aceita somente HTTP 403", async () => {
  await assert.doesNotReject(
    exigirNegado("documento privado", Promise.resolve({ status: 403 }))
  );

  await assert.rejects(
    exigirNegado("documento público", Promise.resolve({ status: 200 })),
    /deveria ser negado.*HTTP 200/
  );
  await assert.rejects(
    exigirNegado("documento ausente mas legível", Promise.resolve({ status: 404 })),
    /deveria ser negado.*HTTP 404/
  );
});

test("endpoint REST fica preso ao projeto e database informados", () => {
  assert.equal(
    endpointDocumentos("nova-alianca-app", "/igrejas/olinda"),
    "https://firestore.googleapis.com/v1/projects/nova-alianca-app/" +
      "databases/(default)/documents/igrejas/olinda"
  );
});

test("canário REST exige exatamente onze campos e listas sanitizadas", () => {
  const campos = camposCatalogoRest();
  assert.equal(validarDocumentoRest({ fields: campos }).valido, true);

  assert.equal(
    validarDocumentoRest({
      fields: { ...campos, pix_chave: { stringValue: "segredo" } },
    }).valido,
    false
  );

  const semSlogan = { ...campos };
  delete semSlogan.slogan;
  assert.equal(validarDocumentoRest({ fields: semSlogan }).valido, false);

  assert.equal(
    validarDocumentoRest({
      fields: {
        ...campos,
        pastores_publicos: {
          arrayValue: { values: [{ stringValue: " Pastor com espaços " }] },
        },
      },
    }).valido,
    false
  );
  assert.equal(
    validarDocumentoRest({
      fields: { ...campos, slogan: { stringValue: " com espaços " } },
    }).valido,
    false
  );
  assert.equal(
    validarDocumentoRest({
      fields: { ...campos, nome: { stringValue: " Nome com espaços " } },
    }).valido,
    false
  );
  assert.equal(
    validarDocumentoRest({
      fields: { ...campos, endereco: { nullValue: "NULL_VALUE" } },
    }).valido,
    false
  );
});

test("lista REST aceita array vazio e rejeita tipos, vazios e duplicatas", () => {
  assert.equal(tipoListaDeTextosSanitizados({ arrayValue: {} }), true);
  assert.equal(
    tipoListaDeTextosSanitizados({
      arrayValue: { values: [{ stringValue: "Culto" }] },
    }),
    true
  );
  for (const invalida of [
    { stringValue: "não é array" },
    { arrayValue: null },
    { arrayValue: { values: [{ integerValue: "1" }] } },
    { arrayValue: { values: [{ stringValue: "" }] } },
    {
      arrayValue: {
        values: [{ stringValue: "Culto" }, { stringValue: "Culto" }],
      },
    },
  ]) {
    assert.equal(tipoListaDeTextosSanitizados(invalida), false);
  }
});
