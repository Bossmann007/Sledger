-- Testes das melhorias M1–M7 (02-melhorias.sql): cada bloco tenta gravar um dado que a
-- melhoria deve recusar e mostra o erro do próprio MySQL; quando faz sentido, mostra também
-- o caso válido que continua permitido. Tudo roda dentro de uma transação desfeita com
-- ROLLBACK, então a base não muda. Execute com `mysql --force` para continuar após cada erro.
USE `sys2`;

-- T01 | M1: snapshot por ativo
-- Recusa um segundo snapshot do mesmo ativo no mesmo instante e totais negativos;
-- aceita o mesmo ativo em outro instante.
START TRANSACTION;
INSERT INTO SnapshotReserva (id_ativo, capturado_em, total_devido_clientes, total_on_chain, merkle_root)
VALUES (1, '2026-10-11 23:59:59', 1, 1, 'teste-duplicado');
INSERT INTO SnapshotReserva (id_ativo, capturado_em, total_devido_clientes, total_on_chain, merkle_root)
VALUES (1, '2026-10-13 23:59:59', -1, 1, 'teste-negativo');
INSERT INTO SnapshotReserva (id_ativo, capturado_em, total_devido_clientes, total_on_chain, merkle_root)
VALUES (1, '2026-10-13 23:59:59', 1, 1, 'teste-valido');
ROLLBACK;

-- T02 | M2: uma conta CLIENTE por cliente e ativo
-- Recusa a segunda conta BTC do cliente 1; aceita outra carteira HOT de BTC (id_cliente NULL).
START TRANSACTION;
INSERT INTO Conta (id_cliente, id_ativo, tipo) VALUES (1, 1, 'CLIENTE');
INSERT INTO Conta (id_cliente, id_ativo, tipo) VALUES (NULL, 1, 'HOT');
ROLLBACK;

-- T03 | M3: cotação não negativa
START TRANSACTION;
UPDATE Ativo SET preco_usd = -1 WHERE id_ativo = 1;
ROLLBACK;

-- T04 | M4: aprovação e motivo do saque
-- Saque 141 está pendente. Recusa "aprovado" sem data de aprovação e "rejeitado" sem motivo;
-- aceita a rejeição com motivo.
START TRANSACTION;
UPDATE Saque SET status_aprovacao = 'APROVADO' WHERE id_movimentacao = 141;
UPDATE Saque SET status_aprovacao = 'REJEITADO' WHERE id_movimentacao = 141;
UPDATE Saque SET status_aprovacao = 'REJEITADO', motivo_rejeicao = 'APROVACAO_NEGADA' WHERE id_movimentacao = 141;
ROLLBACK;

-- T05 | M5: coerência de depósito, reserva e folha
-- Recusa confirmações negativas, reserva liberada sem motivo e folha com saldo zero.
START TRANSACTION;
UPDATE Deposito SET confirmacoes_atuais = -1 WHERE id_movimentacao = 1;
UPDATE ReservaSaldo SET liberada_em = NOW() WHERE id_reserva = 17;
UPDATE FolhaProva SET saldo_devido = 0 WHERE id_folha = 1;
ROLLBACK;

-- T06 | M6: os índices novos são usados pelas consultas do dia a dia
-- Fila de saques pendentes (P07), extrato por período (P02) e histórico do cliente (P09).
EXPLAIN FORMAT=TREE SELECT id_movimentacao FROM Movimentacao WHERE tipo_mov = 'SAQUE' AND status = 'PENDENTE';
EXPLAIN FORMAT=TREE SELECT id_transacao FROM Transacao WHERE ocorrida_em >= '2026-10-01';
EXPLAIN FORMAT=TREE SELECT id_movimentacao, solicitada_em FROM Movimentacao WHERE id_cliente = 1 ORDER BY solicitada_em;

-- T07 | M7: a view calcula o mesmo saldo que a soma direta dos lançamentos
-- Compara, para todas as contas, a view com o cálculo manual; divergências devem ser zero.
SELECT COUNT(*) AS contas,
       SUM(v.saldo_contabil <> COALESCE(m.saldo, 0)) AS divergencias_saldo,
       SUM(v.reserva_ativa <> COALESCE(r.reservado, 0)) AS divergencias_reserva
FROM vw_saldo_conta v
LEFT JOIN (SELECT id_conta, SUM(CASE WHEN tipo = 'CREDITO' THEN valor ELSE -valor END) AS saldo
           FROM Lancamento GROUP BY id_conta) m ON m.id_conta = v.id_conta
LEFT JOIN (SELECT id_conta, SUM(valor) AS reservado
           FROM ReservaSaldo WHERE liberada_em IS NULL GROUP BY id_conta) r ON r.id_conta = v.id_conta;
