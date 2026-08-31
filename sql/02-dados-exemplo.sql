-- Sledger — Dados de exemplo (endereços públicos fake — sem seed/chave privada)
-- Executar após: mysql -u root -p sledger < sql/02-dados-exemplo.sql

USE sledger;

-- Redes e ativos
INSERT INTO rede_blockchain (nome, protocolo, confirmacoes_padrao) VALUES
    ('Bitcoin', 'UTXO', 6),
    ('Ethereum', 'EVM', 12);

INSERT INTO ativo (id_rede, simbolo, nome, casas_decimais) VALUES
    (1, 'BTC', 'Bitcoin', 8),
    (2, 'ETH', 'Ethereum', 18);

-- Clientes
INSERT INTO cliente (documento, nome, email, status) VALUES
    ('12345678901', 'Ana Silva', 'ana@email.com', 'ATIVO'),
    ('98765432100', 'Bruno Costa', 'bruno@email.com', 'ATIVO');

-- Contas ledger
-- id 1: Ana BTC (cliente) | id 2: Bruno BTC | id 3: hot wallet BTC (custodiante)
INSERT INTO conta (id_cliente, id_ativo, tipo, status) VALUES
    (1, 1, 'CLIENTE', 'ATIVA'),
    (2, 1, 'CLIENTE', 'ATIVA'),
    (NULL, 1, 'HOT', 'ATIVA');

INSERT INTO endereco_carteira (id_conta, endereco, tipo) VALUES
    (3, 'bc1qhot000000000000000000000000000000', 'DEPOSITO');

-- Depósito confirmado — Ana, 1.5 BTC
INSERT INTO movimentacao (id_cliente, id_ativo, id_conta, valor, status, tipo_mov) VALUES
    (1, 1, 1, 1.50000000, 'CONFIRMADA', 'DEPOSITO');

INSERT INTO deposito (id_movimentacao, tx_hash_rede, confirmacoes_minimas, confirmacoes_atuais, endereco_origem) VALUES
    (1, '0xabc123deposito_ana_btc', 6, 6, 'bc1qexterno000000000000000000000');

INSERT INTO transacao (descricao, referencia_externa) VALUES
    ('Depósito BTC — Ana Silva', '0xabc123deposito_ana_btc');

UPDATE movimentacao SET id_transacao = 1 WHERE id_movimentacao = 1;

INSERT INTO lancamento (id_transacao, id_conta, tipo, valor) VALUES
    (1, 1, 'CREDITO', 1.50000000),
    (1, 3, 'DEBITO',  1.50000000);

-- Saque pendente — Bruno, 0.25 BTC (reserva ativa, sem transação contábil)
INSERT INTO movimentacao (id_cliente, id_ativo, id_conta, valor, status, tipo_mov) VALUES
    (2, 1, 2, 0.25000000, 'PENDENTE', 'SAQUE');

INSERT INTO saque (id_movimentacao, endereco_destino, status_aprovacao) VALUES
    (2, 'bc1qbruno_saida000000000000000000', 'PENDENTE');

INSERT INTO reserva_saldo (id_saque, id_conta, valor) VALUES
    (2, 2, 0.25000000);

-- Snapshot global de prova de reservas
INSERT INTO snapshot_reserva (capturado_em, total_devido_clientes, total_on_chain, merkle_root, status) VALUES
    ('2026-08-30 12:00:00', 1.50000000, 1.50000000, 'merkle_root_exemplo_a1b2c3', 'PUBLICADO');

INSERT INTO folha_prova (id_snapshot, id_cliente, saldo_devido, hash_folha) VALUES
    (1, 1, 1.50000000, 'hash_folha_ana_001'),
    (1, 2, 0.00000000, 'hash_folha_bruno_002');

-- Depósito posterior ao snapshot — Bruno, 0.1 BTC
INSERT INTO movimentacao (id_cliente, id_ativo, id_conta, valor, status, tipo_mov) VALUES
    (2, 1, 2, 0.10000000, 'CONFIRMADA', 'DEPOSITO');

INSERT INTO deposito (id_movimentacao, tx_hash_rede, confirmacoes_minimas, confirmacoes_atuais) VALUES
    (3, '0xdef456deposito_bruno_btc', 6, 6);

INSERT INTO transacao (descricao, referencia_externa) VALUES
    ('Depósito BTC — Bruno Costa', '0xdef456deposito_bruno_btc');

UPDATE movimentacao SET id_transacao = 2 WHERE id_movimentacao = 3;

INSERT INTO lancamento (id_transacao, id_conta, tipo, valor) VALUES
    (2, 2, 'CREDITO', 0.10000000),
    (2, 3, 'DEBITO',  0.10000000);
