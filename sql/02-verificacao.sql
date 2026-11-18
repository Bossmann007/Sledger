-- Consultas de evidência para executar depois de 01-ddl.sql e dos INSERTs de teste.
USE `Sledger`;

-- 1) Toda transação contábil deve fechar em zero.
SELECT t.id_transacao,
       SUM(CASE WHEN l.tipo = 'DEBITO' THEN -l.valor ELSE l.valor END) AS saldo_transacao,
       COUNT(*) AS quantidade_lancamentos
FROM Transacao t
JOIN Lancamento l ON l.id_transacao = t.id_transacao
GROUP BY t.id_transacao
HAVING quantidade_lancamentos < 2 OR saldo_transacao <> 0;

-- 2) Saldo derivado e saldo disponível por conta.
SELECT c.id_conta, c.tipo, c.id_cliente,
       COALESCE(SUM(CASE WHEN l.tipo = 'DEBITO' THEN -l.valor ELSE l.valor END), 0) AS saldo_ledger,
       COALESCE((SELECT SUM(r.valor) FROM ReservaSaldo r
                 WHERE r.id_conta = c.id_conta AND r.liberada_em IS NULL), 0) AS reservas_ativas
FROM Conta c
LEFT JOIN Lancamento l ON l.id_conta = c.id_conta
GROUP BY c.id_conta, c.tipo, c.id_cliente;

-- 3) Movimentações confirmadas devem possuir transação contábil.
SELECT m.id_movimentacao, m.tipo_mov, m.status
FROM Movimentacao m
WHERE m.status = 'CONFIRMADA' AND m.id_transacao IS NULL;

-- 4) Comparação entre total devido e total on-chain em snapshots publicados.
SELECT id_snapshot, capturado_em, total_devido_clientes, total_on_chain,
       total_on_chain - total_devido_clientes AS diferenca, merkle_root
FROM SnapshotReserva
WHERE status = 'PUBLICADO'
ORDER BY capturado_em;
