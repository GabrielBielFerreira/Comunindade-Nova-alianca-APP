/** Campos públicos permitidos no catálogo de unidades. */
export interface CatalogoPublicoIgreja {
  nome: string;
  ativa: boolean;
  configurada: boolean;
  endereco: string | null;
  cidade_estado: string | null;
  endereco_secundario: string | null;
  slogan: string | null;
  cultos_recorrentes: string[];
  instagram: string | null;
  youtube_url: string | null;
  pastores_publicos: string[];
}

function comoRegistro(valor: unknown): Record<string, unknown> {
  if (typeof valor !== "object" || valor === null || Array.isArray(valor)) {
    return {};
  }
  return valor as Record<string, unknown>;
}

function textoPublicoOuNull(valor: unknown): string | null {
  if (typeof valor !== "string") return null;
  const texto = valor.trim();
  return texto.length > 0 ? texto : null;
}

function listaPublica(valor: unknown): string[] {
  if (!Array.isArray(valor)) return [];
  return [
    ...new Set(
      valor
        .filter((item): item is string => typeof item === "string")
        .map((item) => item.trim())
        .filter((item) => item.length > 0)
    ),
  ];
}

function campoInstitucional(
  raiz: Record<string, unknown>,
  institucionais: Record<string, unknown>,
  campo: string
): unknown {
  return Object.prototype.hasOwnProperty.call(institucionais, campo)
    ? institucionais[campo]
    : raiz[campo];
}

/**
 * Cria uma projeção fechada para leitura pública.
 *
 * A construção campo a campo é intencional: dados administrativos, financeiros
 * ou futuros campos adicionados ao documento raiz nunca são copiados por engano.
 */
export function projetarCatalogoPublico(igreja: unknown): CatalogoPublicoIgreja {
  const raiz = comoRegistro(igreja);
  const institucionais = comoRegistro(raiz.dados_institucionais);
  const valorInstitucional = (campo: string) =>
    campoInstitucional(raiz, institucionais, campo);
  const pastoresPublicos = listaPublica(
    valorInstitucional("pastores_publicos")
  );
  if (pastoresPublicos.length === 0) {
    const pastorLegado = textoPublicoOuNull(
      valorInstitucional("pastor_responsavel")
    );
    if (pastorLegado) pastoresPublicos.push(pastorLegado);
  }

  return {
    nome: typeof raiz.nome === "string" ? raiz.nome.trim() : "",
    ativa: raiz.ativa === true,
    configurada: raiz.configurada === true,
    endereco: textoPublicoOuNull(valorInstitucional("endereco")),
    cidade_estado: textoPublicoOuNull(valorInstitucional("cidade_estado")),
    endereco_secundario: textoPublicoOuNull(
      valorInstitucional("endereco_secundario")
    ),
    slogan: textoPublicoOuNull(valorInstitucional("slogan")),
    cultos_recorrentes: listaPublica(valorInstitucional("cultos_recorrentes")),
    instagram: textoPublicoOuNull(valorInstitucional("instagram")),
    youtube_url: textoPublicoOuNull(valorInstitucional("youtube_url")),
    pastores_publicos: pastoresPublicos,
  };
}
