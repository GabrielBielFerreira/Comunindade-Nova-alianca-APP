/**
 * Inicialização do Admin SDK.
 *
 * Usa a API MODULAR do firebase-admin v12 (`firebase-admin/app`,
 * `firebase-admin/firestore`, `firebase-admin/auth`).
 *
 * Não use o estilo de namespace (`import * as admin` + `admin.firestore.FieldValue`):
 * com `esModuleInterop`, o `__importStar` do TypeScript não preserva as
 * propriedades do namespace, e `FieldValue` chega como `undefined` em tempo de
 * execução — o erro aparece só quando a Function tenta gravar.
 */
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
export const auth = getAuth();
export { FieldValue, Timestamp };
export type { Transaction } from "firebase-admin/firestore";

/** Região única de todas as Functions da rede. */
export const REGIAO = "southamerica-east1";
