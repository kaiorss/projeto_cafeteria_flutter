CREATE TABLE IF NOT EXISTS transferencias (
  id SERIAL PRIMARY KEY,
  client_uuid UUID NOT NULL UNIQUE,
  nome TEXT NOT NULL,
  valor NUMERIC(10,2) NOT NULL CHECK (valor >= 0),
  identificador INTEGER NOT NULL,
  icone_codigo INTEGER NOT NULL DEFAULT 0,
  criado_em TIMESTAMPTZ NOT NULL,
  criado_no_servidor TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_transferencias_criado_em
  ON transferencias (criado_em);
