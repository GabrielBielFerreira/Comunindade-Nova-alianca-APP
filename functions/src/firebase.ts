import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const auth = admin.auth();
export const FieldValue = admin.firestore.FieldValue;
export type Transaction = admin.firestore.Transaction;

/** Região única de todas as Functions da rede. */
export const REGIAO = "southamerica-east1";
