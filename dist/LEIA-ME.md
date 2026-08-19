# Artefatos

## `NovaAlianca-debug-emulator-v1.3.0.apk`

| | |
|---|---|
| Tipo | **debug**, assinado com o certificado de depuração |
| Ambiente | `APP_ENV=emulator` → **Firebase Emulator Suite** |
| Versão | 1.3.0+10 |
| Tamanho | 166,09 MB |
| SHA-256 | `164e216707e5a46919dd58b1d7afe1c0222ca2483d10f4142ae9b197f79750f1` |

### ⚠️ Este APK NÃO serve para distribuição

Ele aponta para o **emulador local**, não para o Firebase real. Instalado num
aparelho comum, ele não encontra backend algum e não faz nada de útil.

Serve para **um** propósito: testar o aplicativo multi-igreja contra o
Emulator Suite, com os dados do seed.

O tamanho (166 MB) é normal em build de depuração — sem minificação, com
símbolos e com as três ABIs. O release de produção fica bem menor.

### Como testar

1. Suba os emuladores e aplique o seed:

   ```powershell
   .\scripts\dev.ps1 -SemPainel
   ```

2. Instale num **emulador Android (AVD)** na mesma máquina:

   ```powershell
   adb install -r dist\NovaAlianca-debug-emulator-v1.3.0.apk
   ```

   O app usa `10.0.2.2` automaticamente — o atalho do AVD para a máquina
   hospedeira.

3. Em **aparelho físico** na mesma rede, é preciso rebuildar apontando para o
   IP da sua máquina (o `10.0.2.2` só existe dentro do AVD):

   ```powershell
   flutter build apk --debug --dart-define=APP_ENV=emulator --dart-define=EMULATOR_HOST=192.168.x.x
   ```

4. Entre com uma das contas de teste (senha `Teste123!`) listadas em
   [EXECUTAR_LOCALMENTE.md](../EXECUTAR_LOCALMENTE.md).

## APK/AAB de produção

Ainda **não foi gerado**: depende de `flutterfire configure`, que exige
autenticação no Firebase. Os passos estão em
[DEPLOY_PRODUCAO.md](../DEPLOY_PRODUCAO.md) (passos 1 e 7).

O AAB exige, além disso, a keystore de produção em `android/key.properties`.
