-- ============================================================
-- WFS Dashboard — SQL Schema v2
-- Schema: dash-sla
-- Rodar no Supabase: SQL Editor → colar tudo → Run
-- ============================================================

-- 1. Criar o schema
CREATE SCHEMA IF NOT EXISTS "dash-sla";

-- ============================================================
-- TABELA: sla_pcg
-- Valores mensais de SLA por setor
-- ============================================================
CREATE TABLE IF NOT EXISTS "dash-sla".sla_pcg (
  id          BIGSERIAL PRIMARY KEY,
  ano         INTEGER NOT NULL,
  mes         INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  setor       TEXT    NOT NULL CHECK (setor IN ('internacao','paletizada','nacional','exportacao','importacao')),
  valor       NUMERIC(12,2) NOT NULL,
  criado_em   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (ano, mes, setor)
);

-- ============================================================
-- TABELA: raiox
-- Inspeções mensais do Raio-X
-- ============================================================
CREATE TABLE IF NOT EXISTS "dash-sla".raiox (
  id                  BIGSERIAL PRIMARY KEY,
  ano                 INTEGER NOT NULL,
  mes                 INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  auditados           INTEGER NOT NULL DEFAULT 0,
  inspecionados       INTEGER NOT NULL DEFAULT 0,
  nao_inspecionados   INTEGER NOT NULL DEFAULT 0,
  criado_em           TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (ano, mes)
);

-- ============================================================
-- TABELA: auditoria_6s
-- Resultado percentual mensal da Auditoria 6S
-- ============================================================
CREATE TABLE IF NOT EXISTS "dash-sla".auditoria_6s (
  id          BIGSERIAL PRIMARY KEY,
  ano         INTEGER NOT NULL,
  mes         INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  resultado   NUMERIC(5,2) NOT NULL CHECK (resultado BETWEEN 0 AND 100),
  criado_em   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (ano, mes)
);

-- ============================================================
-- TABELA: importacao_voos
-- Registro individual de cada voo de importação por CIA
-- Permite múltiplos voos por mês/CIA
-- ============================================================
CREATE TABLE IF NOT EXISTS "dash-sla".importacao_voos (
  id          BIGSERIAL PRIMARY KEY,
  ano         INTEGER NOT NULL,
  mes         INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  cia         TEXT    NOT NULL CHECK (cia IN ('ATLAS','LATAM','TAMPA')),
  num_voo     TEXT,
  peso        NUMERIC(14,2) NOT NULL DEFAULT 0,
  vol         NUMERIC(12,2) NOT NULL DEFAULT 0,
  uld         INTEGER NOT NULL DEFAULT 0,
  tc4         INTEGER NOT NULL DEFAULT 0,
  criado_em   TIMESTAMPTZ DEFAULT NOW()
  -- sem UNIQUE: múltiplos voos por mês/CIA são permitidos
);

-- Índice para queries de dashboard (filtro por ano/mes/cia)
CREATE INDEX IF NOT EXISTS idx_imp_voos_ano_mes ON "dash-sla".importacao_voos (ano, mes, cia);

-- ============================================================
-- RLS — liberar acesso via anon key (uso interno)
-- ============================================================
ALTER TABLE "dash-sla".sla_pcg          ENABLE ROW LEVEL SECURITY;
ALTER TABLE "dash-sla".raiox            ENABLE ROW LEVEL SECURITY;
ALTER TABLE "dash-sla".auditoria_6s     ENABLE ROW LEVEL SECURITY;
ALTER TABLE "dash-sla".importacao_voos  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_all_sla"      ON "dash-sla".sla_pcg         FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_raiox"    ON "dash-sla".raiox            FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_auditoria" ON "dash-sla".auditoria_6s    FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_imp_voos" ON "dash-sla".importacao_voos  FOR ALL TO anon USING (true) WITH CHECK (true);

-- ============================================================
-- GRANT — role anon acessa o schema e todas as tabelas
-- ============================================================
GRANT USAGE ON SCHEMA "dash-sla" TO anon;
GRANT ALL ON ALL TABLES    IN SCHEMA "dash-sla" TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA "dash-sla" TO anon;

-- ============================================================
-- VIEW ÚTIL: consolidado de importação por ano/mes/cia
-- Agrega os voos individuais para o dashboard
-- ============================================================
CREATE OR REPLACE VIEW "dash-sla".importacao_consolidado AS
SELECT
  ano,
  mes,
  cia,
  SUM(peso)  AS peso_total,
  SUM(vol)   AS vol_total,
  SUM(uld)   AS uld_total,
  SUM(tc4)   AS tc4_total,
  COUNT(*)   AS qtd_voos
FROM "dash-sla".importacao_voos
GROUP BY ano, mes, cia
ORDER BY ano, mes, cia;

GRANT SELECT ON "dash-sla".importacao_consolidado TO anon;

-- ============================================================
-- FIM — após rodar, acesse o dashboard, vá em Entrada de Dados
-- → Importação, adicione os voos e salve. O indicador
-- "Supabase OK" deve aparecer verde no topo da página.
-- ============================================================
