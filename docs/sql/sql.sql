-- MySQL Workbench Forward Engineering (corrigido — Sledger Parte I)

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE SCHEMA IF NOT EXISTS `Sledger` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `Sledger`;

-- DROP em ordem inversa de dependência (reexecução segura)
DROP TABLE IF EXISTS `FolhaProva`;
DROP TABLE IF EXISTS `ReservaSaldo`;
DROP TABLE IF EXISTS `Deposito`;
DROP TABLE IF EXISTS `Saque`;
DROP TABLE IF EXISTS `Lancamento`;
DROP TABLE IF EXISTS `Movimentacao`;
DROP TABLE IF EXISTS `EnderecoCarteira`;
DROP TABLE IF EXISTS `Transacao`;
DROP TABLE IF EXISTS `Conta`;
DROP TABLE IF EXISTS `Cliente`;
DROP TABLE IF EXISTS `Ativo`;
DROP TABLE IF EXISTS `RedeBlockchain`;
DROP TABLE IF EXISTS `SnapshotReserva`;

-- -----------------------------------------------------
-- Table `RedeBlockchain`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `RedeBlockchain` (
  `id_rede`             INT NOT NULL AUTO_INCREMENT,
  `nome`                VARCHAR(50)  NOT NULL,
  `protocolo`           VARCHAR(30)  NOT NULL,
  `confirmacoes_padrao` INT NOT NULL DEFAULT 6,
  PRIMARY KEY (`id_rede`),
  UNIQUE INDEX `uk_rede_nome` (`nome` ASC) VISIBLE)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Ativo`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Ativo` (
  `id_ativo`       INT NOT NULL AUTO_INCREMENT,
  `simbolo`        VARCHAR(10) NOT NULL,
  `nome`           VARCHAR(80) NOT NULL,
  `casas_decimais` INT NOT NULL,
  `id_rede`        INT NOT NULL,
  PRIMARY KEY (`id_ativo`),
  UNIQUE INDEX `uk_ativo_rede_simbolo` (`id_rede` ASC, `simbolo` ASC) VISIBLE,
  INDEX `fk_ativo_rede_idx` (`id_rede` ASC) VISIBLE,
  CONSTRAINT `fk_ativo_rede`
    FOREIGN KEY (`id_rede`)
    REFERENCES `RedeBlockchain` (`id_rede`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Cliente`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Cliente` (
  `id_cliente`    INT NOT NULL AUTO_INCREMENT,
  `documento`     VARCHAR(14)  NOT NULL,
  `nome`          VARCHAR(120) NOT NULL,
  `email`         VARCHAR(120) NOT NULL,
  `status`        ENUM('ATIVO', 'SUSPENSO', 'ENCERRADO') NOT NULL DEFAULT 'ATIVO',
  `cadastrado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_cliente`),
  UNIQUE INDEX `uk_cliente_documento` (`documento` ASC) VISIBLE)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Conta`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Conta` (
  `id_conta`   INT NOT NULL AUTO_INCREMENT,
  `id_cliente` INT NULL,
  `id_ativo`   INT NOT NULL,
  `tipo`       ENUM('CLIENTE', 'HOT', 'COLD', 'RESERVA') NOT NULL,
  `status`     ENUM('ATIVA', 'BLOQUEADA', 'ENCERRADA') NOT NULL DEFAULT 'ATIVA',
  PRIMARY KEY (`id_conta`),
  INDEX `fk_conta_cliente_idx` (`id_cliente` ASC) VISIBLE,
  INDEX `fk_conta_ativo_idx` (`id_ativo` ASC) VISIBLE,
  CONSTRAINT `fk_conta_cliente`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `Cliente` (`id_cliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_conta_ativo`
    FOREIGN KEY (`id_ativo`)
    REFERENCES `Ativo` (`id_ativo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `chk_conta_titular` CHECK (
    (`tipo` = 'CLIENTE' AND `id_cliente` IS NOT NULL)
    OR (`tipo` IN ('HOT', 'COLD', 'RESERVA') AND `id_cliente` IS NULL)
  ))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `EnderecoCarteira`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `EnderecoCarteira` (
  `id_endereco` INT NOT NULL AUTO_INCREMENT,
  `id_conta`    INT NOT NULL,
  `endereco`    VARCHAR(100) NOT NULL,
  `tipo`        ENUM('DEPOSITO', 'SAQUE') NOT NULL DEFAULT 'DEPOSITO',
  PRIMARY KEY (`id_endereco`),
  UNIQUE INDEX `uk_endereco` (`endereco` ASC) VISIBLE,
  INDEX `fk_endereco_conta_idx` (`id_conta` ASC) VISIBLE,
  CONSTRAINT `fk_endereco_conta`
    FOREIGN KEY (`id_conta`)
    REFERENCES `Conta` (`id_conta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Transacao`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Transacao` (
  `id_transacao`       INT NOT NULL AUTO_INCREMENT,
  `ocorrida_em`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `descricao`          VARCHAR(255) NOT NULL,
  `referencia_externa` VARCHAR(128) NULL,
  `status`             ENUM('CONFIRMADA', 'ESTORNADA') NOT NULL DEFAULT 'CONFIRMADA',
  PRIMARY KEY (`id_transacao`))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Lancamento`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Lancamento` (
  `id_lancamento` INT NOT NULL AUTO_INCREMENT,
  `id_transacao`  INT NOT NULL,
  `id_conta`      INT NOT NULL,
  `tipo`          ENUM('DEBITO', 'CREDITO') NOT NULL,
  `valor`         DECIMAL(20,8) NOT NULL,
  PRIMARY KEY (`id_lancamento`),
  INDEX `fk_lancamento_transacao_idx` (`id_transacao` ASC) VISIBLE,
  INDEX `fk_lancamento_conta_idx` (`id_conta` ASC) VISIBLE,
  CONSTRAINT `fk_lancamento_transacao`
    FOREIGN KEY (`id_transacao`)
    REFERENCES `Transacao` (`id_transacao`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_lancamento_conta`
    FOREIGN KEY (`id_conta`)
    REFERENCES `Conta` (`id_conta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `chk_lancamento_valor_positivo` CHECK (`valor` > 0))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Movimentacao`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Movimentacao` (
  `id_movimentacao` INT NOT NULL AUTO_INCREMENT,
  `id_cliente`      INT NOT NULL,
  `id_ativo`        INT NOT NULL,
  `id_conta`        INT NOT NULL,
  `id_transacao`    INT NULL,
  `valor`           DECIMAL(20,8) NOT NULL,
  `solicitada_em`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status`          ENUM('PENDENTE', 'CONFIRMADA', 'CANCELADA', 'FALHA') NOT NULL DEFAULT 'PENDENTE',
  `tipo_mov`        ENUM('DEPOSITO', 'SAQUE') NOT NULL,
  PRIMARY KEY (`id_movimentacao`),
  INDEX `fk_mov_cliente_idx` (`id_cliente` ASC) VISIBLE,
  INDEX `fk_mov_ativo_idx` (`id_ativo` ASC) VISIBLE,
  INDEX `fk_mov_conta_idx` (`id_conta` ASC) VISIBLE,
  INDEX `fk_mov_transacao_idx` (`id_transacao` ASC) VISIBLE,
  CONSTRAINT `fk_mov_cliente`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `Cliente` (`id_cliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_mov_ativo`
    FOREIGN KEY (`id_ativo`)
    REFERENCES `Ativo` (`id_ativo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_mov_conta`
    FOREIGN KEY (`id_conta`)
    REFERENCES `Conta` (`id_conta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_mov_transacao`
    FOREIGN KEY (`id_transacao`)
    REFERENCES `Transacao` (`id_transacao`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `chk_mov_valor_positivo` CHECK (`valor` > 0))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Deposito`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Deposito` (
  `id_movimentacao`      INT NOT NULL,
  `tx_hash_rede`         VARCHAR(128) NOT NULL,
  `confirmacoes_minimas` INT NOT NULL,
  `confirmacoes_atuais`  INT NOT NULL DEFAULT 0,
  `endereco_origem`      VARCHAR(100) NULL,
  PRIMARY KEY (`id_movimentacao`),
  UNIQUE INDEX `uk_deposito_tx` (`tx_hash_rede` ASC) VISIBLE,
  CONSTRAINT `fk_deposito_mov`
    FOREIGN KEY (`id_movimentacao`)
    REFERENCES `Movimentacao` (`id_movimentacao`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `Saque`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Saque` (
  `id_movimentacao`  INT NOT NULL,
  `endereco_destino` VARCHAR(100) NOT NULL,
  `status_aprovacao` ENUM('PENDENTE', 'APROVADO', 'REJEITADO') NOT NULL DEFAULT 'PENDENTE',
  `aprovado_em`      DATETIME NULL,
  PRIMARY KEY (`id_movimentacao`),
  CONSTRAINT `fk_saque_mov`
    FOREIGN KEY (`id_movimentacao`)
    REFERENCES `Movimentacao` (`id_movimentacao`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `ReservaSaldo`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ReservaSaldo` (
  `id_reserva`       INT NOT NULL AUTO_INCREMENT,
  `id_saque`         INT NOT NULL,
  `id_conta`         INT NOT NULL,
  `valor`            DECIMAL(20,8) NOT NULL,
  `criada_em`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `liberada_em`      DATETIME NULL,
  `motivo_liberacao` ENUM('CONFIRMADA', 'FALHA', 'REJEITADA', 'TIMEOUT') NULL,
  PRIMARY KEY (`id_reserva`),
  INDEX `fk_reserva_saque_idx` (`id_saque` ASC) VISIBLE,
  INDEX `fk_reserva_conta_idx` (`id_conta` ASC) VISIBLE,
  CONSTRAINT `fk_reserva_saque`
    FOREIGN KEY (`id_saque`)
    REFERENCES `Saque` (`id_movimentacao`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_reserva_conta`
    FOREIGN KEY (`id_conta`)
    REFERENCES `Conta` (`id_conta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `chk_reserva_valor` CHECK (`valor` > 0))
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `SnapshotReserva`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `SnapshotReserva` (
  `id_snapshot`           INT NOT NULL AUTO_INCREMENT,
  `capturado_em`          DATETIME NOT NULL,
  `total_devido_clientes` DECIMAL(20,8) NOT NULL,
  `total_on_chain`        DECIMAL(20,8) NOT NULL,
  `merkle_root`           VARCHAR(128) NOT NULL,
  `status`                ENUM('RASCUNHO', 'PUBLICADO') NOT NULL DEFAULT 'RASCUNHO',
  PRIMARY KEY (`id_snapshot`),
  UNIQUE INDEX `uk_snapshot_capturado` (`capturado_em` ASC) VISIBLE)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `FolhaProva`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `FolhaProva` (
  `id_folha`     INT NOT NULL AUTO_INCREMENT,
  `id_snapshot`  INT NOT NULL,
  `id_cliente`   INT NOT NULL,
  `saldo_devido` DECIMAL(20,8) NOT NULL,
  `hash_folha`   VARCHAR(128) NOT NULL,
  PRIMARY KEY (`id_folha`),
  UNIQUE INDEX `uk_folha_snapshot_cliente` (`id_snapshot` ASC, `id_cliente` ASC) VISIBLE,
  INDEX `fk_folha_snapshot_idx` (`id_snapshot` ASC) VISIBLE,
  INDEX `fk_folha_cliente_idx` (`id_cliente` ASC) VISIBLE,
  CONSTRAINT `fk_folha_snapshot`
    FOREIGN KEY (`id_snapshot`)
    REFERENCES `SnapshotReserva` (`id_snapshot`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_folha_cliente`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `Cliente` (`id_cliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
