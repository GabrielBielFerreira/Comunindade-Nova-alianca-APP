# Seed de dados de exemplo (Avisos / Eventos)

Popula o Firestore com alguns Avisos e Eventos para você **ver as telas com
dados reais** enquanto o painel de Gestão (que cria o conteúdo oficial) não existe.

## Passos
1. No **Firebase Console** → **Configurações do projeto** → **Contas de serviço**
   → **Gerar nova chave privada**. Salve o arquivo como:
   `seed/serviceAccountKey.json` (NÃO versione — já está no `.gitignore`).
2. Instale e rode:
   ```bash
   cd seed
   npm install
   node seed.js
   ```
3. Abra o app → **Avisos** e **Programação** mostrarão os itens de exemplo.

## Remover os exemplos
```bash
node seed.js --limpar
```

> Os itens criados recebem o campo `_seed: "seed-exemplo"` apenas para permitir a
> remoção; o app ignora esse campo. Em produção, o conteúdo real será criado pela
> liderança via o painel de Gestão externo.
