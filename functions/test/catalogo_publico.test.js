const assert = require("node:assert/strict");
const { describe, it } = require("node:test");

const { projetarCatalogoPublico } = require("../lib/churches/catalogoPublico");
const {
  LIMITES_CAMPOS_LISTA,
  LIMITES_CAMPOS_TEXTO,
  extrairInstitucionais,
  mesclarInstitucionais,
  temDadosInstitucionais,
} = require("../lib/churches/igrejas");

describe("projeção do catálogo público de igrejas", () => {
  it("expõe exatamente os onze campos permitidos e omite dados privados", () => {
    const segredoCanario = "SEGREDO-CANARIO-NAO-PODE-VAZAR";
    const projecao = projetarCatalogoPublico({
      nome: "  Nova Aliança Olinda  ",
      ativa: true,
      configurada: true,
      slug: segredoCanario,
      criado_por: segredoCanario,
      atualizado_por: segredoCanario,
      criado_em: segredoCanario,
      atualizado_em: segredoCanario,
      migrado_de: segredoCanario,
      migrado_em: segredoCanario,
      mercado_pago_status: segredoCanario,
      token_integracao: segredoCanario,
      dados_institucionais: {
        endereco: "  Rua Exemplo, 123  ",
        cidade_estado: "  Olinda - PE  ",
        endereco_secundario: "  Próximo à praça  ",
        slogan: "  Uma família para pertencer  ",
        cultos_recorrentes: ["  Domingo 18h  ", "", 123, "Domingo 18h"],
        instagram: "  @novaalianca  ",
        youtube_url: "  https://youtube.example/igreja  ",
        pastores_publicos: ["  Pastora Ana  ", null, "Pastora Ana"],
        pastor_responsavel: "Não substituir a lista pública",
        telefone: segredoCanario,
        pix_chave: segredoCanario,
        pix_tipo: segredoCanario,
        cep: segredoCanario,
        responsavel_administrativo_uid: segredoCanario,
      },
    });

    assert.deepEqual(Object.keys(projecao), [
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
    ]);
    assert.deepEqual(projecao, {
      nome: "Nova Aliança Olinda",
      ativa: true,
      configurada: true,
      endereco: "Rua Exemplo, 123",
      cidade_estado: "Olinda - PE",
      endereco_secundario: "Próximo à praça",
      slogan: "Uma família para pertencer",
      cultos_recorrentes: ["Domingo 18h"],
      instagram: "@novaalianca",
      youtube_url: "https://youtube.example/igreja",
      pastores_publicos: ["Pastora Ana"],
    });
    assert.equal(JSON.stringify(projecao).includes(segredoCanario), false);
  });

  it("normaliza campos públicos ausentes ou vazios para os tipos do contrato", () => {
    const projecao = projetarCatalogoPublico({
      nome: "Unidade Teste",
      ativa: false,
      configurada: false,
      dados_institucionais: {
        endereco: "   ",
      },
    });

    assert.deepEqual(projecao, {
      nome: "Unidade Teste",
      ativa: false,
      configurada: false,
      endereco: null,
      cidade_estado: null,
      endereco_secundario: null,
      slogan: null,
      cultos_recorrentes: [],
      instagram: null,
      youtube_url: null,
      pastores_publicos: [],
    });
  });

  it("usa pastor_responsavel somente como fallback de lista pública vazia", () => {
    assert.deepEqual(
      projetarCatalogoPublico({
        nome: "Unidade Legada",
        ativa: true,
        configurada: true,
        dados_institucionais: {
          pastores_publicos: ["", 42],
          pastor_responsavel: "  Pastor Legado  ",
        },
      }).pastores_publicos,
      ["Pastor Legado"]
    );
  });
});

describe("payload institucional de criar/atualizar igreja", () => {
  it("sanitiza e limita os novos campos públicos persistidos na raiz", () => {
    const extraidos = extrairInstitucionais({
      endereco_secundario: "  Próximo à praça  ",
      slogan: "  Família para pertencer  ",
      youtube_url: "  https://youtube.example/canal  ",
      instagram: "  @novaalianca  ",
      cultos_recorrentes: ["  Domingo 18h  ", "", "Domingo 18h"],
      pastores_publicos: ["  Pastora Ana  ", "Pastor João"],
    });

    assert.deepEqual(extraidos, {
      endereco_secundario: "Próximo à praça",
      slogan: "Família para pertencer",
      instagram: "@novaalianca",
      youtube_url: "https://youtube.example/canal",
      cultos_recorrentes: ["Domingo 18h"],
      pastores_publicos: ["Pastora Ana", "Pastor João"],
    });
    assert.equal(temDadosInstitucionais(extraidos), true);
    assert.equal(temDadosInstitucionais({ token_integracao: "segredo" }), false);
  });

  it("mescla atualização sem perder dados anteriores e permite limpar listas", () => {
    assert.deepEqual(
      mesclarInstitucionais(
        { endereco: "Rua anterior", slogan: "Anterior" },
        { slogan: "  Novo  ", cultos_recorrentes: null }
      ),
      {
        endereco: "Rua anterior",
        slogan: "Novo",
        cultos_recorrentes: [],
      }
    );
  });

  it("rejeita campos não permitidos, tipos errados e limites excedidos", () => {
    const segredo = "SEGREDO-NAO-PERSISTIR";
    for (const entrada of [
      { responsavel_administrativo_uid: segredo },
      { token_integracao: segredo },
      { slogan: { texto: "inválido" } },
      { cultos_recorrentes: "não é lista" },
      { pastores_publicos: ["Pastora", 42] },
      {
        slogan: "x".repeat(LIMITES_CAMPOS_TEXTO.slogan + 1),
      },
      {
        cultos_recorrentes: Array.from(
          { length: LIMITES_CAMPOS_LISTA.cultos_recorrentes.itens + 1 },
          (_, indice) => `Culto ${indice}`
        ),
      },
      {
        pastores_publicos: [
          "x".repeat(
            LIMITES_CAMPOS_LISTA.pastores_publicos.caracteresPorItem + 1
          ),
        ],
      },
    ]) {
      assert.throws(() => extrairInstitucionais(entrada), (erro) => {
        assert.equal(erro.code, "invalid-argument");
        assert.equal(String(erro.message).includes(segredo), false);
        return true;
      });
    }
  });
});
