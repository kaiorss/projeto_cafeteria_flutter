# Backend da Cafeteria

API local em Node.js + Express + PostgreSQL para sincronização dos registros
criados pelo app Flutter.

## Escopo atual (Etapas B1 a B6)

- Estrutura base do Express.
- Configuração por variáveis de ambiente, com suporte a `DATABASE_URL`.
- Pool de conexão com PostgreSQL (SSL opcional via `PGSSL=true`).
- `schema.sql` com a tabela `transferencias`.
- Script de migração `npm run db:migrate`.
- Endpoints `GET /health`, `POST /api/transferencias` e
  `GET /api/transferencias`.
- Validação de payload e upsert idempotente por `client_uuid`.
- Testes de integração com `npm test`.
- Integração ponta a ponta validada pelo app Flutter na etapa B5.
- Blueprint de deploy no Render em `../render.yaml`.

## Nomenclatura

A tabela e os endpoints usam `transferencias`, pois esse é o nome real da
entidade no projeto Flutter (`Transferencia`, `TransferenciaDao`,
`TransferenciaRepository`, `screens/transferencias`). O rótulo de interface
"consumo" é mantido apenas na apresentação ao usuário.

## Estrutura

```text
backend/
├─ package.json
├─ .env.example
├─ .gitignore
├─ README.md
├─ tests/
│  └─ transferencias.test.js
└─ src/
   ├─ server.js
   ├─ app.js
   ├─ config/env.js
   ├─ db/pool.js
   ├─ db/schema.sql
   ├─ db/migrate.js
   ├─ controllers/transferencias.controller.js
   ├─ validators/transferencia.validator.js
   ├─ routes/health.routes.js
   ├─ routes/transferencias.routes.js
   └─ middlewares/error.middleware.js
```

## Pré-requisitos

- Node.js 20 ou superior.
- PostgreSQL instalado localmente, com o banco `cafeteria_db`.

## Instalação do PostgreSQL no Windows

1. Baixe o instalador oficial em <https://www.postgresql.org/download/windows/>.
2. Execute o instalador e mantenha os componentes PostgreSQL Server, pgAdmin 4
   e Command Line Tools.
3. Na etapa de senha, defina a senha do usuário `postgres` e guarde-a.
4. Mantenha a porta `5432` e o diretório de dados padrão.
5. Finalize a instalação.

Depois de instalar, crie o banco (o `psql` fica em
`C:\Program Files\PostgreSQL\<versao>\bin`):

```powershell
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -p 5432 -c "CREATE DATABASE cafeteria_db;"
```

## Configuração

Copie o arquivo de exemplo e preencha a senha do PostgreSQL:

```powershell
Copy-Item .env.example .env
```

```dotenv
PORT=3000
PGHOST=localhost
PGPORT=5432
PGUSER=postgres
PGPASSWORD=sua_senha_aqui
PGDATABASE=cafeteria_db
```

O arquivo `.env` é ignorado pelo Git.

Para produção, `DATABASE_URL` tem prioridade sobre `PGHOST`, `PGPORT`,
`PGUSER`, `PGPASSWORD` e `PGDATABASE`. Se o provedor exigir TLS, defina também
`PGSSL=true`.

## Instalar dependências e migrar

```powershell
npm install
npm run db:migrate
```

Saída esperada da migração:

```text
Aplicando schema em postgres@localhost:5432/cafeteria_db...
Schema aplicado com sucesso.
```

## Executar

```powershell
npm run dev
```

ou:

```powershell
npm start
```

## Health check

```powershell
Invoke-RestMethod http://localhost:3000/health
```

Com o PostgreSQL configurado e disponível:

```json
{ "status": "ok", "banco": "conectado" }
```

Sem configuração ou com o banco indisponível, a API responde `503`:

```json
{ "status": "degradado", "banco": "indisponivel" }
```

## Endpoints de transferências

### `POST /api/transferencias`

Cadastra um registro. O `clientUuid` é único: reenviar o mesmo UUID atualiza o
registro existente e retorna o mesmo `id` (sem duplicar). Responde `201` na
primeira criação e `200` em reenvios.

```powershell
$corpo = @{
  clientUuid    = "f47ac10b-58cc-4372-a567-0e02b2c3d479"
  nome          = "Café com Leite"
  valor         = 12.00
  identificador = 7
  iconeCodigo   = 58719
  criadoEm      = "2026-11-15T12:00:00.000Z"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri http://localhost:3000/api/transferencias `
  -ContentType "application/json" -Body $corpo
```

Resposta:

```json
{
  "id": 1,
  "clientUuid": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "nome": "Café com Leite",
  "valor": 12.0,
  "identificador": 7,
  "iconeCodigo": 58719,
  "criadoEm": "2026-11-15T12:00:00.000Z",
  "sincronizado": true
}
```

Payload inválido retorna `400`:

```json
{
  "erro": "Dados inválidos.",
  "detalhes": ["valor deve ser um número maior ou igual a zero."]
}
```

### `GET /api/transferencias`

Lista todos os registros ordenados por `criadoEm`, no mesmo formato JSON.

```powershell
Invoke-RestMethod http://localhost:3000/api/transferencias
```

## Testes

Com o PostgreSQL configurado e o schema aplicado:

```powershell
npm test
```

Os testes cobrem criação, listagem, idempotência, ID estável, validações e JSON
malformado. Os registros de teste são removidos ao final.

## Deploy no Render (B6)

O arquivo `render.yaml` na raiz do repositório declara o web service
`cafeteria-api` e o banco `cafeteria-db`, ambos no plano gratuito. O backend
deve estar commitado e enviado ao GitHub antes do deploy. O `.env` não deve ser
commitado.

### Deploy atual da B6

- API: `https://cafeteria-api-h3bm.onrender.com`
- Health check: `https://cafeteria-api-h3bm.onrender.com/health`
- Banco: Render Postgres Free, região `oregon`, criado em 15/11/2026 e com
  expiração em 15/12/2026.
- O deploy inicial foi criado pela Render CLI com as mesmas configurações do
  `render.yaml`; o blueprint foi validado e permanece para recriação.
- Validação em produção: health check OK, `POST` idempotente com mesmo `id` e
  registro de teste removido ao final.
- APK release gerado com `API_BASE_URL` apontando para a API pública.

### Blueprint pelo dashboard

1. No Render Dashboard, escolha **New > Blueprint**.
2. Conecte o repositório `projeto_cafeteria_flutter`.
3. Confirme o `render.yaml` e aplique as mudanças.
4. Aguarde o build (`npm ci --omit=dev`) e o start
   (`npm run db:migrate && npm start`).
5. Abra `https://<servico>.onrender.com/health` e confirme
   `{"status":"ok","banco":"conectado"}`.

### Web Service manual

1. Crie um **Postgres Free** na mesma região do serviço.
2. Crie um **Web Service** com root directory `backend`, runtime Node, build
   `npm ci --omit=dev` e start `npm run db:migrate && npm start`.
3. Defina `NODE_ENV=production` e `DATABASE_URL` com a **Internal Database
   URL** do banco criado.
4. Configure o health check em `/health`.

A migração é idempotente e roda a cada start. Para uma conexão externa que exija
TLS, acrescente `PGSSL=true`.

### Apontar o Flutter para produção

O app já usa `https://cafeteria-api-h3bm.onrender.com` como padrão, portanto
o `--dart-define` não é obrigatório:

```powershell
flutter build apk --release
```

Ao sobrescrever a URL, não inclua `/api` no valor; o cliente já acrescenta
esse prefixo.

### Limitações do plano gratuito

- O web service hiberna após 15 minutos sem tráfego; a primeira requisição pode
  levar cerca de um minuto.
- O Postgres gratuito expira 30 dias após a criação (há 14 dias de carência para
  upgrade).
- O serviço gratuito não recebe tráfego pela rede privada, mas pode acessar o
  banco na mesma região pela URL interna.

## Próximas etapas

- B6: executar o deploy e validar a sincronização com a URL pública.
