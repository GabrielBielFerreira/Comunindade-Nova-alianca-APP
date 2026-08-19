/**
 * Espelho TypeScript do domínio de `packages/nova_alianca_core`.
 *
 * Mantido em sincronia manual e coberto pelos mesmos cenários nos testes de
 * Rules. Se a matriz mudar em capabilities.dart, muda aqui e nas Rules.
 */

export const PERFIS = ["pastor", "diacono", "evangelista", "lider", "membro"] as const;
export type PerfilComunitario = (typeof PERFIS)[number];

export const FUNCOES_ADMIN = ["pastor", "tesoureiro", "editor", "moderador_oracao"] as const;
export type FuncaoAdmin = (typeof FUNCOES_ADMIN)[number];

export const STATUS_VINCULO = ["pendente", "aprovado", "inativo"] as const;
export type StatusVinculo = (typeof STATUS_VINCULO)[number];

/** Liderança ministerial: grupo DERIVADO do perfil, nunca gravável. */
export const LIDERANCA_MINISTERIAL: readonly PerfilComunitario[] = [
  "pastor",
  "diacono",
  "evangelista",
  "lider",
];

export interface VinculoIgreja {
  uid: string;
  igrejaId: string;
  status: StatusVinculo;
  perfil: PerfilComunitario;
  funcoesAdmin: FuncaoAdmin[];
}

/** Remove acentos e normaliza caixa/espaços — igual a normalizarChave no Dart. */
export function normalizarChave(valor: string): string {
  return valor
    .toLowerCase()
    .trim()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[\s-]+/g, "_");
}

export function lerPerfil(bruto: unknown): PerfilComunitario {
  const chave = normalizarChave(String(bruto ?? ""));
  return (PERFIS as readonly string[]).includes(chave)
    ? (chave as PerfilComunitario)
    : "membro";
}

export function lerStatus(bruto: unknown): StatusVinculo {
  const chave = normalizarChave(String(bruto ?? ""));
  return (STATUS_VINCULO as readonly string[]).includes(chave)
    ? (chave as StatusVinculo)
    : "pendente";
}

export function lerFuncoes(bruto: unknown): FuncaoAdmin[] {
  if (!Array.isArray(bruto)) return [];
  const apelidos: Record<string, FuncaoAdmin> = {
    moderador_de_oracao: "moderador_oracao",
  };
  const resultado = new Set<FuncaoAdmin>();
  for (const item of bruto) {
    const chave = normalizarChave(String(item ?? ""));
    if ((FUNCOES_ADMIN as readonly string[]).includes(chave)) {
      resultado.add(chave as FuncaoAdmin);
    } else if (apelidos[chave]) {
      resultado.add(apelidos[chave]);
    }
  }
  return [...resultado].sort();
}

/** `igrejaId` seguro: impede path traversal e valores forjados pelo cliente. */
export function validarIgrejaId(bruto: unknown): string {
  const chave = normalizarChave(String(bruto ?? ""));
  if (!/^[a-z0-9_]{2,40}$/.test(chave)) {
    throw new Error(`igrejaId invalido: ${String(bruto)}`);
  }
  return chave;
}

// ── Capacidades (espelham capabilities.dart) ─────────────────────────

export function isAtivo(v: VinculoIgreja | null): v is VinculoIgreja {
  return v !== null && v.status === "aprovado";
}

export function isLiderancaMinisterial(v: VinculoIgreja | null): boolean {
  return isAtivo(v) && LIDERANCA_MINISTERIAL.includes(v.perfil);
}

export function isPastor(v: VinculoIgreja | null): boolean {
  return isAtivo(v) && v.perfil === "pastor";
}

export function temFuncao(v: VinculoIgreja | null, funcao: FuncaoAdmin): boolean {
  return isAtivo(v) && v.funcoesAdmin.includes(funcao);
}

export function canReadFinance(v: VinculoIgreja | null, superAdmin: boolean): boolean {
  return superAdmin || isLiderancaMinisterial(v) || temFuncao(v, "tesoureiro");
}

export function canManageContent(v: VinculoIgreja | null, superAdmin: boolean): boolean {
  return superAdmin || isLiderancaMinisterial(v) || temFuncao(v, "editor");
}

export function canModeratePrayer(v: VinculoIgreja | null, superAdmin: boolean): boolean {
  return superAdmin || isLiderancaMinisterial(v) || temFuncao(v, "moderador_oracao");
}

export function canApproveMember(v: VinculoIgreja | null, superAdmin: boolean): boolean {
  return superAdmin || isLiderancaMinisterial(v);
}

export function canManageLeadership(v: VinculoIgreja | null, superAdmin: boolean): boolean {
  return superAdmin || isPastor(v);
}

export function podeAcessarPainel(v: VinculoIgreja | null, superAdmin: boolean): boolean {
  return (
    superAdmin ||
    isLiderancaMinisterial(v) ||
    temFuncao(v, "tesoureiro") ||
    temFuncao(v, "editor") ||
    temFuncao(v, "moderador_oracao")
  );
}
