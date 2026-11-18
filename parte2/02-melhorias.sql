-- Melhorias da Parte 2 sobre o modelo da Parte 1.
-- Execute uma única vez, logo após 01-ddl.sql e antes da carga (03-dados.sql).
-- Cada bloco corresponde a um item da seção "Ajustes e melhorias" do relatório.
USE `sys2`;

-- M1 | Snapshot por ativo.
-- Na Parte 1 o SnapshotReserva tinha um único total devido/on-chain, o que obrigaria
-- somar BTC com ETH (unidades diferentes). Agora cada snapshot pertence a um ativo,
-- e a unicidade passa a ser (ativo, instante de captura).
ALTER TABLE `SnapshotReserva`
  ADD COLUMN `id_ativo` INT NOT NULL AFTER `id_snapshot`,
  DROP INDEX `uk_snapshot_capturado`,
  ADD UNIQUE INDEX `uk_snapshot_ativo_capturado` (`id_ativo`, `capturado_em`),
  ADD CONSTRAINT `fk_snapshot_ativo`
    FOREIGN KEY (`id_ativo`) REFERENCES `Ativo` (`id_ativo`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `chk_snapshot_totais` CHECK (`total_devido_clientes` >= 0 AND `total_on_chain` >= 0);

-- M2 | Uma única conta CLIENTE por par (cliente, ativo).
-- Evita dividir o direito do cliente em duas contas do mesmo ativo. HOT/COLD têm
-- id_cliente NULL e o MySQL admite vários NULL em índice UNIQUE.
ALTER TABLE `Conta`
  ADD UNIQUE INDEX `uk_conta_cliente_ativo` (`id_cliente`, `id_ativo`);

-- M3 | Cotação de referência em USD por ativo.
-- Necessária para consolidar posições de ativos diferentes (saldo total em USD,
-- dashboard de custódia). Guardamos apenas a cotação vigente e quando foi atualizada;
-- histórico de preços fica fora do escopo (seria uma tabela CotacaoAtivo).
ALTER TABLE `Ativo`
  ADD COLUMN `preco_usd` DECIMAL(20,8) NOT NULL DEFAULT 0 AFTER `id_rede`,
  ADD COLUMN `preco_atualizado_em` DATETIME NULL AFTER `preco_usd`,
  ADD CONSTRAINT `chk_ativo_preco` CHECK (`preco_usd` >= 0 AND `casas_decimais` BETWEEN 0 AND 30);

-- M4 | Rastreabilidade do saque.
-- motivo_rejeicao registra por que um saque não foi concluído (saldo insuficiente,
-- aprovação negada, falha de rede ou timeout); antes isso só podia ser inferido.
-- tx_hash_rede guarda o hash da transação transmitida, simétrico ao Depósito, e
-- permite conciliar saídas com a blockchain mesmo antes da confirmação.
ALTER TABLE `Saque`
  ADD COLUMN `motivo_rejeicao` ENUM('SALDO_INSUFICIENTE', 'APROVACAO_NEGADA', 'FALHA_REDE', 'TIMEOUT') NULL AFTER `aprovado_em`,
  ADD COLUMN `tx_hash_rede` VARCHAR(128) NULL AFTER `motivo_rejeicao`,
  ADD UNIQUE INDEX `uk_saque_tx` (`tx_hash_rede`),
  ADD CONSTRAINT `chk_saque_aprovacao` CHECK ((`status_aprovacao` = 'APROVADO') = (`aprovado_em` IS NOT NULL)),
  ADD CONSTRAINT `chk_saque_motivo` CHECK (`status_aprovacao` <> 'REJEITADO' OR `motivo_rejeicao` IS NOT NULL);

-- M5 | Regras de coerência que antes ficavam só no texto.
ALTER TABLE `Deposito`
  ADD CONSTRAINT `chk_deposito_confirmacoes` CHECK (`confirmacoes_atuais` >= 0 AND `confirmacoes_minimas` >= 1);
ALTER TABLE `ReservaSaldo`
  ADD CONSTRAINT `chk_reserva_liberacao` CHECK ((`liberada_em` IS NULL) = (`motivo_liberacao` IS NULL));
ALTER TABLE `FolhaProva`
  ADD CONSTRAINT `chk_folha_saldo` CHECK (`saldo_devido` > 0);

-- M6 | Índices para as consultas do dia a dia (filas, extrato por período, reservas ativas).
ALTER TABLE `Movimentacao`
  ADD INDEX `idx_mov_tipo_status` (`tipo_mov`, `status`),
  ADD INDEX `idx_mov_cliente_data` (`id_cliente`, `solicitada_em`);
ALTER TABLE `ReservaSaldo`
  ADD INDEX `idx_reserva_conta_liberacao` (`id_conta`, `liberada_em`);
ALTER TABLE `Transacao`
  ADD INDEX `idx_transacao_ocorrida` (`ocorrida_em`);

-- M7 | View do saldo derivado.
-- O saldo continua NÃO armazenado (3FN, ADR 0001); a view apenas centraliza a regra
-- "saldo contábil = créditos − débitos" e "disponível = contábil − reservas ativas",
-- para que todas as consultas usem a mesma definição.
CREATE OR REPLACE VIEW `vw_saldo_conta` AS
SELECT co.id_conta, co.id_cliente, co.id_ativo, co.tipo AS tipo_conta,
       COALESCE(l.saldo, 0)                      AS saldo_contabil,
       COALESCE(r.reservado, 0)                  AS reserva_ativa,
       COALESCE(l.saldo, 0) - COALESCE(r.reservado, 0) AS saldo_disponivel,
       l.ultimo_lancamento
FROM Conta co
LEFT JOIN (
  SELECT lc.id_conta,
         SUM(CASE WHEN lc.tipo = 'CREDITO' THEN lc.valor ELSE -lc.valor END) AS saldo,
         MAX(t.ocorrida_em) AS ultimo_lancamento
  FROM Lancamento lc
  JOIN Transacao t ON t.id_transacao = lc.id_transacao
  GROUP BY lc.id_conta
) l ON l.id_conta = co.id_conta
LEFT JOIN (
  SELECT id_conta, SUM(valor) AS reservado
  FROM ReservaSaldo WHERE liberada_em IS NULL
  GROUP BY id_conta
) r ON r.id_conta = co.id_conta;
