# Cafeteria

App de cadastros de consumos (produtos) de uma cafeteria, feito em Flutter com
persistência local SQLite e sincronização manual com uma API Node.js/Express e
PostgreSQL.

Avaliação prática de **Programação para Dispositivos Móveis II**.

- **Aluno:** KAIO LEANDRO RISSATO
- **Entidade:** Consumo (modelado pela classe `Transferencia`)
- **Ícone da entidade:** `Icons.local_cafe`

## Funcionalidades

- Cadastro de consumos com nome, valor e identificador.
- Persistência local em SQLite; os dados continuam disponíveis sem internet.
- Lista com `ListView.builder` + `Card` + `ListTile` e status de sincronização.
- Sincronização **manual** pelo botão `Sincronizar pendentes (N)`, com contador.
- Registro só é marcado como sincronizado após a confirmação da API.
- Em caso de falha, os registros permanecem pendentes e podem ser reenviados.
- Idempotência por `clientUuid`, sem duplicar registros no servidor.
- Valores exibidos no padrão brasileiro: `R$ 12,00`.

## Etapas

- **B1:** backend Express + PostgreSQL + migração + `/health`.
- **B2:** `POST/GET /api/transferencias` com validação e upsert idempotente.
- **B3:** cliente HTTP no Flutter e configuração de URL por ambiente.
- **B4:** sincronização manual com contador de pendências.
- **B5:** teste de integração local com SQLite + API real + PostgreSQL e
  geração das evidências.
- **B6:** preparação do deploy no Render (`render.yaml`, `DATABASE_URL` e SSL);
  publicação pendente de credenciais e envio ao GitHub.

## Estrutura

```text
lib/
├── config/api_config.dart                  # URL da API por plataforma
├── database/app_database.dart              # SQLite (sqflite / FFI)
├── database/transferencia_dao.dart         # operações da tabela
├── models/transferencia.dart               # modelo + toMap/toJson
├── repository/transferencia_repository.dart# regras locais + sincronização
├── services/transferencia_api_service.dart # cliente HTTP
├── components/editor.dart                  # componente de formulário
├── components/status_sincronizacao.dart    # badge Pendente/Sincronizado
└── screens/transferencias/
    ├── lista.dart                          # lista + botão de sincronização
    └── formulario.dart                     # cadastro

integration_test/fluxo_sincronizacao_test.dart  # teste end-to-end
test_host/fluxo_sincronizacao_test.dart         # execução do teste no host
test_driver/integration_test.dart               # driver/evidências Android
test/                                           # testes unitários e de widget
backend/                                        # API Node.js/Express/PostgreSQL
render.yaml                                     # blueprint do Render (B6)
evidencias/                                     # prints gerados na B5
```

## Como executar

### 1. Backend

Pré-requisitos: Node.js 20+ e PostgreSQL em execução.

```powershell
cd backend
npm install
Copy-Item .env.example .env   # configure usuário, senha, banco e porta
npm run db:migrate
npm run dev
```

Confirme a API:

```powershell
Invoke-RestMethod http://localhost:3000/health
```

### 2. App Flutter

```powershell
flutter pub get
flutter run
```

- Emulador Android: a URL padrão é `http://10.0.2.2:3000`.
- Windows/navegador: a URL padrão é `http://localhost:3000`.
- Aparelho físico ou outra porta:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
```

- Produção no Render:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://<servico>.onrender.com
```

O deploy do backend está documentado em `backend/README.md`.

## Testes

```powershell
flutter analyze
flutter test
flutter build apk --debug

cd backend
npm test
```

Resultados esperados da B5:

- `flutter analyze`: sem problemas.
- `flutter test`: 21 testes unitários/de widget aprovados.
- `npm test`: 5 testes de integração do backend aprovados.
- `flutter build apk --debug`: APK gerado.

### Teste de integração local (B5)

Com o backend e o PostgreSQL em execução:

```powershell
flutter test test_host/fluxo_sincronizacao_test.dart
```

O teste usa um banco SQLite temporário via FFI, cadastra `Café com Leite`,
sincroniza pela API real, confirma o registro no PostgreSQL (via `GET`), testa
o reenvio idempotente e gera:

- `evidencias/formulario.png`
- `evidencias/lista.png`

O teste também pode ser executado em aparelho/emulador Android com
`flutter drive`; nesse caso os prints são gerados pelo driver.

## Evidências

Os prints estão em `evidencias/`. Veja `evidencias/LEIA-ME.md` para o roteiro
manual e para a geração automatizada.
