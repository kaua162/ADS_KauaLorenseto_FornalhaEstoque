-- Migração: campos de contato, endereço completo e observações em mercado_parceiro
-- Data: 2026-10-13
--
-- Seguro para rodar mais de uma vez (IF NOT EXISTS / WHERE ... IS NULL).
-- Não apaga nem recria a tabela; a coluna antiga "endereco" é mantida.
--
-- Como rodar no pgAdmin:
--   1. Conecte no servidor e selecione o banco "fornalha_estoque".
--   2. Menu Tools > Query Tool (ou botão direito no banco > Query Tool).
--   3. Abra este arquivo (ícone de pasta "Open File") ou cole o conteúdo.
--   4. Execute com F5 (ou o botão ▶ Execute).
--   5. Confira em Schemas > public > Tables > mercado_parceiro > Columns (botão direito > Refresh).

BEGIN;

ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS email        VARCHAR(120);
ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS nome_contato VARCHAR(120);
ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS logradouro   VARCHAR(150);
ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS numero       VARCHAR(20);
ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS bairro       VARCHAR(100);
ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS cidade       VARCHAR(100);
ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS uf           VARCHAR(2);
ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS cep          VARCHAR(8);
ALTER TABLE mercado_parceiro ADD COLUMN IF NOT EXISTS observacoes  TEXT;

-- Aproveita o endereço antigo (texto livre) como logradouro, sem apagar a coluna original.
UPDATE mercado_parceiro
   SET logradouro = LEFT(endereco, 150)
 WHERE logradouro IS NULL
   AND endereco IS NOT NULL
   AND TRIM(endereco) <> '';

-- A API passou a guardar o telefone só com dígitos (o app formata na tela).
-- Remove a pontuação dos telefones já cadastrados, ex.: "(54) 3311-0000" -> "5433110000".
UPDATE mercado_parceiro
   SET telefone = REGEXP_REPLACE(telefone, '\D', '', 'g')
 WHERE telefone ~ '\D';

COMMIT;
