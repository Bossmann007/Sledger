-- Sledger — Modelo Físico (MySQL 8.0+)
-- Disciplina: Arquitetura de Banco de Dados — PUCPR
-- Executar: mysql -u root -p < sql/01-ddl.sql

CREATE DATABASE IF NOT EXISTS sledger
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE sledger;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- Cadastro base (entidades 1–5)
-- ---------------------------------------------------------------------------

CREATE TABLE rede_blockchain (
    id_rede             INT UNSIGNED AUTO_INCREMENT,
    nome                VARCHAR(50)  NOT NULL,
    protocolo           VARCHAR(30)  NOT NULL,
    confirmacoes_padrao INT UNSIGNED NOT NULL DEFAULT 6,
    PRIMARY KEY (id_rede),
    UNIQUE KEY uk_rede_nome (nome)
) ENGINE=InnoDB;

CREATE TABLE ativo (
    id_ativo       INT UNSIGNED AUTO_INCREMENT,
    id_rede        INT UNSIGNED NOT NULL,
    simbolo        VARCHAR(10)  NOT NULL,
    nome           VARCHAR(80)  NOT NULL,
    casas_decimais TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (id_ativo),
    UNIQUE KEY uk_ativo_rede_simbolo (id_rede, simbolo),
    CONSTRAINT fk_ativo_rede
        FOREIGN KEY (id_rede) REFERENCES rede_blockchain (id_rede)
) ENGINE=InnoDB;

CREATE TABLE cliente (
    id_cliente    INT UNSIGNED AUTO_INCREMENT,
    documento     VARCHAR(14)  NOT NULL,
    nome          VARCHAR(120) NOT NULL,
    email         VARCHAR(120) NOT NULL,
    status        ENUM('ATIVO', 'SUSPENSO', 'ENCERRADO') NOT NULL DEFAULT 'ATIVO',
    cadastrado_em DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente),
    UNIQUE KEY uk_cliente_documento (documento)
) ENGINE=InnoDB;

CREATE TABLE conta (
    id_conta   INT UNSIGNED AUTO_INCREMENT,
    id_cliente INT UNSIGNED NULL,
    id_ativo   INT UNSIGNED NOT NULL,
    tipo       ENUM('CLIENTE', 'HOT', 'COLD', 'RESERVA') NOT NULL,
    status     ENUM('ATIVA', 'BLOQUEADA', 'ENCERRADA') NOT NULL DEFAULT 'ATIVA',
    PRIMARY KEY (id_conta),
    CONSTRAINT fk_conta_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT fk_conta_ativo
        FOREIGN KEY (id_ativo) REFERENCES ativo (id_ativo),
    CONSTRAINT chk_conta_titular CHECK (
        (tipo = 'CLIENTE' AND id_cliente IS NOT NULL)
        OR (tipo IN ('HOT', 'COLD', 'RESERVA') AND id_cliente IS NULL)
    )
) ENGINE=InnoDB;

CREATE TABLE endereco_carteira (
    id_endereco INT UNSIGNED AUTO_INCREMENT,
    id_conta    INT UNSIGNED NOT NULL,
    endereco    VARCHAR(100) NOT NULL,
    tipo        ENUM('DEPOSITO', 'SAQUE') NOT NULL DEFAULT 'DEPOSITO',
    PRIMARY KEY (id_endereco),
    UNIQUE KEY uk_endereco (endereco),
    CONSTRAINT fk_endereco_conta
        FOREIGN KEY (id_conta) REFERENCES conta (id_conta)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Ledger — partida dobrada (entidades 6–7)
-- ---------------------------------------------------------------------------

CREATE TABLE transacao (
    id_transacao       INT UNSIGNED AUTO_INCREMENT,
    ocorrida_em        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descricao          VARCHAR(255) NOT NULL,
    referencia_externa VARCHAR(128) NULL,
    status             ENUM('CONFIRMADA', 'ESTORNADA') NOT NULL DEFAULT 'CONFIRMADA',
    PRIMARY KEY (id_transacao)
) ENGINE=InnoDB;

CREATE TABLE lancamento (
    id_lancamento INT UNSIGNED AUTO_INCREMENT,
    id_transacao  INT UNSIGNED NOT NULL,
    id_conta      INT UNSIGNED NOT NULL,
    tipo          ENUM('DEBITO', 'CREDITO') NOT NULL,
    valor         DECIMAL(20, 8) NOT NULL,
    PRIMARY KEY (id_lancamento),
    CONSTRAINT fk_lancamento_transacao
        FOREIGN KEY (id_transacao) REFERENCES transacao (id_transacao),
    CONSTRAINT fk_lancamento_conta
        FOREIGN KEY (id_conta) REFERENCES conta (id_conta),
    CONSTRAINT chk_lancamento_valor_positivo CHECK (valor > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Movimentações on-chain — herança ISA (entidades 8–11)
-- ---------------------------------------------------------------------------

CREATE TABLE movimentacao (
    id_movimentacao INT UNSIGNED AUTO_INCREMENT,
    id_cliente      INT UNSIGNED NOT NULL,
    id_ativo        INT UNSIGNED NOT NULL,
    id_conta        INT UNSIGNED NOT NULL,
    id_transacao    INT UNSIGNED NULL,
    valor           DECIMAL(20, 8) NOT NULL,
    solicitada_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          ENUM('PENDENTE', 'CONFIRMADA', 'CANCELADA', 'FALHA') NOT NULL DEFAULT 'PENDENTE',
    tipo_mov        ENUM('DEPOSITO', 'SAQUE') NOT NULL,
    PRIMARY KEY (id_movimentacao),
    CONSTRAINT fk_mov_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT fk_mov_ativo
        FOREIGN KEY (id_ativo) REFERENCES ativo (id_ativo),
    CONSTRAINT fk_mov_conta
        FOREIGN KEY (id_conta) REFERENCES conta (id_conta),
    CONSTRAINT fk_mov_transacao
        FOREIGN KEY (id_transacao) REFERENCES transacao (id_transacao),
    CONSTRAINT chk_mov_valor_positivo CHECK (valor > 0)
) ENGINE=InnoDB;

CREATE TABLE deposito (
    id_movimentacao      INT UNSIGNED NOT NULL,
    tx_hash_rede         VARCHAR(128) NOT NULL,
    confirmacoes_minimas INT UNSIGNED NOT NULL,
    confirmacoes_atuais  INT UNSIGNED NOT NULL DEFAULT 0,
    endereco_origem      VARCHAR(100) NULL,
    PRIMARY KEY (id_movimentacao),
    UNIQUE KEY uk_deposito_tx (tx_hash_rede),
    CONSTRAINT fk_deposito_mov
        FOREIGN KEY (id_movimentacao) REFERENCES movimentacao (id_movimentacao)
) ENGINE=InnoDB;

CREATE TABLE saque (
    id_movimentacao  INT UNSIGNED NOT NULL,
    endereco_destino VARCHAR(100) NOT NULL,
    status_aprovacao ENUM('PENDENTE', 'APROVADO', 'REJEITADO') NOT NULL DEFAULT 'PENDENTE',
    aprovado_em      DATETIME NULL,
    PRIMARY KEY (id_movimentacao),
    CONSTRAINT fk_saque_mov
        FOREIGN KEY (id_movimentacao) REFERENCES movimentacao (id_movimentacao)
) ENGINE=InnoDB;

CREATE TABLE reserva_saldo (
    id_reserva       INT UNSIGNED AUTO_INCREMENT,
    id_saque         INT UNSIGNED NOT NULL,
    id_conta         INT UNSIGNED NOT NULL,
    valor            DECIMAL(20, 8) NOT NULL,
    criada_em        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    liberada_em      DATETIME NULL,
    motivo_liberacao ENUM('CONFIRMADA', 'FALHA', 'REJEITADA', 'TIMEOUT') NULL,
    PRIMARY KEY (id_reserva),
    CONSTRAINT fk_reserva_saque
        FOREIGN KEY (id_saque) REFERENCES saque (id_movimentacao),
    CONSTRAINT fk_reserva_conta
        FOREIGN KEY (id_conta) REFERENCES conta (id_conta),
    CONSTRAINT chk_reserva_valor CHECK (valor > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Prova de reservas (entidades 12–13)
-- ---------------------------------------------------------------------------

CREATE TABLE snapshot_reserva (
    id_snapshot           INT UNSIGNED AUTO_INCREMENT,
    capturado_em          DATETIME NOT NULL,
    total_devido_clientes DECIMAL(20, 8) NOT NULL,
    total_on_chain        DECIMAL(20, 8) NOT NULL,
    merkle_root           VARCHAR(128) NOT NULL,
    status                ENUM('RASCUNHO', 'PUBLICADO') NOT NULL DEFAULT 'RASCUNHO',
    PRIMARY KEY (id_snapshot),
    UNIQUE KEY uk_snapshot_capturado (capturado_em)
) ENGINE=InnoDB;

CREATE TABLE folha_prova (
    id_folha     INT UNSIGNED AUTO_INCREMENT,
    id_snapshot  INT UNSIGNED NOT NULL,
    id_cliente   INT UNSIGNED NOT NULL,
    saldo_devido DECIMAL(20, 8) NOT NULL,
    hash_folha   VARCHAR(128) NOT NULL,
    PRIMARY KEY (id_folha),
    UNIQUE KEY uk_folha_snapshot_cliente (id_snapshot, id_cliente),
    CONSTRAINT fk_folha_snapshot
        FOREIGN KEY (id_snapshot) REFERENCES snapshot_reserva (id_snapshot),
    CONSTRAINT fk_folha_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Índices de consulta
-- ---------------------------------------------------------------------------

CREATE INDEX idx_lancamento_conta ON lancamento (id_conta);
CREATE INDEX idx_lancamento_transacao ON lancamento (id_transacao);
CREATE INDEX idx_movimentacao_cliente ON movimentacao (id_cliente, solicitada_em);
CREATE INDEX idx_movimentacao_status ON movimentacao (status);
CREATE INDEX idx_movimentacao_transacao ON movimentacao (id_transacao);
CREATE INDEX idx_reserva_conta_ativa ON reserva_saldo (id_conta, liberada_em);
CREATE INDEX idx_folha_cliente ON folha_prova (id_cliente);

-- ---------------------------------------------------------------------------
-- Triggers — integridade de negócio
-- ---------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_lancamento_partida_dobrada
AFTER INSERT ON lancamento
FOR EACH ROW
BEGIN
    DECLARE saldo DECIMAL(20, 8);
    DECLARE qtd   INT;

    SELECT COUNT(*) INTO qtd
    FROM lancamento
    WHERE id_transacao = NEW.id_transacao;

    IF qtd >= 2 THEN
        SELECT COALESCE(SUM(CASE tipo WHEN 'CREDITO' THEN valor ELSE -valor END), 0)
        INTO saldo
        FROM lancamento
        WHERE id_transacao = NEW.id_transacao;

        IF saldo <> 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Partida dobrada violada: lançamentos da transação não somam zero.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_deposito_tipo_mov
BEFORE INSERT ON deposito
FOR EACH ROW
BEGIN
    IF (SELECT tipo_mov FROM movimentacao WHERE id_movimentacao = NEW.id_movimentacao) <> 'DEPOSITO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'deposito exige movimentacao.tipo_mov = DEPOSITO';
    END IF;
END$$

CREATE TRIGGER trg_saque_tipo_mov
BEFORE INSERT ON saque
FOR EACH ROW
BEGIN
    IF (SELECT tipo_mov FROM movimentacao WHERE id_movimentacao = NEW.id_movimentacao) <> 'SAQUE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'saque exige movimentacao.tipo_mov = SAQUE';
    END IF;
END$$

CREATE TRIGGER trg_lancamento_no_delete
BEFORE DELETE ON lancamento
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exclusão de lançamentos não permitida (imutabilidade).';
END$$

CREATE TRIGGER trg_transacao_no_delete
BEFORE DELETE ON transacao
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exclusão de transações não permitida (imutabilidade).';
END$$

DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;
