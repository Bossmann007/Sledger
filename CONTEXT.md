# Sledger

Ledger contábil de custodiante de criptomoedas: partida dobrada interna, movimentações on-chain (depósito/saque) e prova de reservas periódica. Alinhado ao enquadramento regulatório BCB para ativos virtuais (referência acadêmica: Res. BCB 519/2025).

## Language

**Custodiante**:
Instituição que guarda ativos on-chain (hot/cold) e registra direitos dos clientes em contas ledger internas. Vê saldo ledger — operação exige.
_Avoid_: wallet pessoal, corretora cega, non-custodial

**Chave privada / seed**:
Nunca persistida no SGBD. Ian Coleman só gera endereços demo para INSERTs acadêmicos — nunca passphrase real online.
_Avoid_: armazenar seed, Ian Coleman em produção

**Conta ledger**:
Unidade contábil interna por ativo — cliente ou custodiante (hot, cold, reserva).
_Avoid_: conta bancária, wallet, endereço

**Transação contábil**:
Evento no ledger que agrupa lançamentos cuja soma algébrica é zero.
_Avoid_: transação, tx, operação

**Tx on-chain**:
Transferência registrada na blockchain; identificada por hash e estado na rede/mempool.
_Avoid_: transação (sem qualificador), transação contábil

**Lançamento**:
Débito ou crédito em uma conta ledger dentro de uma transação contábil. Imutável após confirmação.
_Avoid_: movimentação, entry (sem tradução)

**Movimentação**:
Operação on-chain iniciada por cliente — supertipo de Depósito e Saque (herança total e exclusiva).
_Avoid_: transação, transferência

**Depósito**:
Movimentação de entrada; crédito após confirmações mínimas na rede.
_Avoid_: recebimento, top-up

**Saque**:
Movimentação de saída; aprovação operacional; reserva temporária até confirmação ou falha on-chain; lançamento contábil só após confirmação.
_Avoid_: retirada, transfer out

**Reserva de saldo**:
Registro temporário em tabela própria (`reserva_saldo`): reduz saldo disponível entre aprovação do saque e confirmação/falha on-chain. Liberada com motivo (CONFIRMADA, FALHA, REJEITADA, TIMEOUT).
_Avoid_: bloqueio, freeze, valor_bloqueado (só coluna em saque)

**Estorno contábil**:
Nova transação contábil que reverte lançamento já confirmado. Não usado quando saque falha antes de confirmar (basta liberar reserva).
_Avoid_: delete, rollback (DELETE), cancelar registro

**Snapshot de reserva**:
Retrato instantâneo: total devido aos clientes vs total verificado on-chain + Merkle root.
_Avoid_: backup, foto

**Folha de prova**:
Comprovante por cliente dentro de um snapshot (saldo devido + hash individual).
_Avoid_: extrato, recibo

**Saldo disponível**:
Derivado de lançamentos confirmados menos reservas ativas — não é coluna persistida na Parte I.
_Avoid_: saldo_atual (coluna), balance
