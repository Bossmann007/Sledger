-- Validação da base. V00 mostra a contagem por tabela (todas >= 20);
-- V01 a V11 procuram inconsistências e devem retornar ZERO linhas.
USE `sys2`;

-- V00 | Registros por tabela.
SELECT 'RedeBlockchain' AS tabela, COUNT(*) AS registros FROM RedeBlockchain
UNION ALL SELECT 'Ativo', COUNT(*) FROM Ativo
UNION ALL SELECT 'Cliente', COUNT(*) FROM Cliente
UNION ALL SELECT 'Conta', COUNT(*) FROM Conta
UNION ALL SELECT 'EnderecoCarteira', COUNT(*) FROM EnderecoCarteira
UNION ALL SELECT 'Transacao', COUNT(*) FROM Transacao
UNION ALL SELECT 'Lancamento', COUNT(*) FROM Lancamento
UNION ALL SELECT 'Movimentacao', COUNT(*) FROM Movimentacao
UNION ALL SELECT 'Deposito', COUNT(*) FROM Deposito
UNION ALL SELECT 'Saque', COUNT(*) FROM Saque
UNION ALL SELECT 'ReservaSaldo', COUNT(*) FROM ReservaSaldo
UNION ALL SELECT 'SnapshotReserva', COUNT(*) FROM SnapshotReserva
UNION ALL SELECT 'FolhaProva', COUNT(*) FROM FolhaProva;

-- V01 | Herança ISA: cada movimentação tem exatamente o subtipo indicado em tipo_mov.
SELECT m.id_movimentacao, m.tipo_mov
FROM Movimentacao m
LEFT JOIN Deposito d ON d.id_movimentacao = m.id_movimentacao
LEFT JOIN Saque s ON s.id_movimentacao = m.id_movimentacao
WHERE (m.tipo_mov = 'DEPOSITO' AND (d.id_movimentacao IS NULL OR s.id_movimentacao IS NOT NULL))
   OR (m.tipo_mov = 'SAQUE' AND (s.id_movimentacao IS NULL OR d.id_movimentacao IS NOT NULL));

-- V02 | Movimentação aponta para conta de outro cliente/ativo ou que não é CLIENTE.
SELECT m.id_movimentacao, m.id_cliente, m.id_ativo, m.id_conta
FROM Movimentacao m
JOIN Conta co ON co.id_conta = m.id_conta
WHERE co.id_cliente <> m.id_cliente OR co.id_ativo <> m.id_ativo OR co.tipo <> 'CLIENTE';

-- V03 | Só movimentação confirmada gera transação contábil (e toda confirmada gera).
SELECT id_movimentacao, status, id_transacao FROM Movimentacao
WHERE (status = 'CONFIRMADA') <> (id_transacao IS NOT NULL);

-- V04 | Depósito confirmado sem atingir o mínimo de confirmações.
SELECT m.id_movimentacao, d.confirmacoes_atuais, d.confirmacoes_minimas
FROM Movimentacao m
JOIN Deposito d ON d.id_movimentacao = m.id_movimentacao
WHERE m.status = 'CONFIRMADA' AND d.confirmacoes_atuais < d.confirmacoes_minimas;

-- V05 | Reserva ativa só para saque aprovado e pendente, na conta do próprio saque.
SELECT r.id_reserva, r.id_saque, m.status, s.status_aprovacao
FROM ReservaSaldo r
JOIN Saque s ON s.id_movimentacao = r.id_saque
JOIN Movimentacao m ON m.id_movimentacao = s.id_movimentacao
WHERE (r.liberada_em IS NULL AND (m.status <> 'PENDENTE' OR s.status_aprovacao <> 'APROVADO'))
   OR r.id_conta <> m.id_conta;

-- V06 | No máximo uma reserva ativa por saque.
SELECT id_saque, COUNT(*) AS reservas_ativas
FROM ReservaSaldo WHERE liberada_em IS NULL
GROUP BY id_saque HAVING COUNT(*) > 1;

-- V07 | Saldo de cliente negativo, ou disponível negativo depois das reservas.
SELECT id_conta, saldo_contabil, saldo_disponivel
FROM vw_saldo_conta
WHERE tipo_conta = 'CLIENTE' AND (saldo_contabil < 0 OR saldo_disponivel < 0);

-- V08 | Uma transação contábil não mistura ativos (unidades diferentes).
SELECT l.id_transacao, COUNT(DISTINCT co.id_ativo) AS qtd_ativos
FROM Lancamento l
JOIN Conta co ON co.id_conta = l.id_conta
GROUP BY l.id_transacao
HAVING COUNT(DISTINCT co.id_ativo) > 1;

-- V09 | Soma das folhas diferente do total devido do snapshot.
SELECT sr.id_snapshot, sr.total_devido_clientes, SUM(f.saldo_devido) AS soma_folhas
FROM SnapshotReserva sr
JOIN FolhaProva f ON f.id_snapshot = sr.id_snapshot
GROUP BY sr.id_snapshot, sr.total_devido_clientes
HAVING sr.total_devido_clientes <> SUM(f.saldo_devido);

-- V10 | Total devido do snapshot diferente do ledger no instante da captura.
SELECT sr.id_snapshot, sr.total_devido_clientes, x.total_ledger
FROM SnapshotReserva sr
JOIN (
  SELECT sr2.id_snapshot,
         SUM(CASE WHEN l.tipo = 'CREDITO' THEN l.valor ELSE -l.valor END) AS total_ledger
  FROM SnapshotReserva sr2
  JOIN Conta co ON co.id_ativo = sr2.id_ativo AND co.tipo = 'CLIENTE'
  JOIN Lancamento l ON l.id_conta = co.id_conta
  JOIN Transacao t ON t.id_transacao = l.id_transacao AND t.ocorrida_em <= sr2.capturado_em
  GROUP BY sr2.id_snapshot
) x ON x.id_snapshot = sr.id_snapshot
WHERE sr.total_devido_clientes <> x.total_ledger;

-- V11 | Folha de cliente que não tem conta no ativo do snapshot.
SELECT f.id_folha, f.id_cliente, sr.id_ativo
FROM FolhaProva f
JOIN SnapshotReserva sr ON sr.id_snapshot = f.id_snapshot
WHERE NOT EXISTS (
  SELECT 1 FROM Conta co
  WHERE co.id_cliente = f.id_cliente AND co.id_ativo = sr.id_ativo AND co.tipo = 'CLIENTE'
);
