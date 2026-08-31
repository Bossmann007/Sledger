# Minimundo — Sledger

## 1. Escopo

O Sledger é um sistema de custódia institucional de criptomoedas (modelo custodial). O foco desta Parte I é registrar saldos com partida dobrada, processar depósitos e saques on-chain e publicar prova periódica de reservas. Cadastro de operadores e auditoria detalhada existem como suporte (RA3), mas o eixo central é ledger + custódia + prova.

## 2. Contexto e custódia

O Sledger é um sistema de custódia de ativos digitais com ledger contábil interno e prova periódica de reservas. A custodiante controla as carteiras operacionais on-chain. Cada cliente possui uma conta ledger por ativo (BTC, ETH, …), onde se registram seus direitos sobre aquele ativo. Cada ativo pertence a uma rede blockchain (Bitcoin, Ethereum), que define regras como confirmações mínimas para depósitos. Endereços públicos de recebimento vinculam-se às contas operacionais da custodiante. A custodiante também mantém contas internas hot (online) e cold (offline); essas contas operacionais não pertencem aos clientes — apenas as contas ledger do tipo cliente representam o saldo devido a cada um. Em resumo: o cliente tem direito registrado na conta ledger; a custodiante detém a moeda nas carteiras hot/cold.

## 3. Ledger contábil

O registro contábil interno do Sledger segue partida dobrada: cada evento contabilizado vira uma Transacao que agrupa dois ou mais Lancamentos. A soma algébrica dos lançamentos de uma mesma transação é sempre zero; cada lançamento é débito ou crédito e aponta para uma Conta ledger. Transacao contábil é distinta da transação registrada na blockchain. O saldo de uma conta não é armazenado em coluna fixa: deriva da soma dos lançamentos daquela conta, descontadas reservas ativas quando aplicável (ADR 0001). Lançamentos não são excluídos; erros são corrigidos com nova transação de estorno. Depósito confirmado on-chain produz crédito na conta CLIENTE e débito na conta HOT, na mesma transação contábil, com soma zero.

## 4. Movimentações on-chain

Toda operação de entrada ou saída de ativos na blockchain é registrada como Movimentacao, vinculada a um cliente, a um ativo, a um valor, a um status e à conta ledger afetada. Deposito e Saque especializam Movimentacao por herança total e exclusiva: toda movimentação é exatamente um depósito ou um saque, nunca os dois ao mesmo tempo. Atributos comuns ficam em Movimentacao; particularidades de cada fluxo ficam no subtipo correspondente.

No Deposito, registram-se o hash da transação na rede, as confirmações mínimas exigidas e as confirmações já obtidas, além do endereço de origem. Enquanto a movimentação não atinge o status CONFIRMADA on-chain, não há lançamento contábil. Após a confirmação, o sistema gera a Transacao contábil com crédito na conta CLIENTE do cliente e débito na conta HOT da custodiante.

No Saque, o cliente informa valor e endereço de destino; um operador aprova ou rejeita o pedido. Na aprovação, cria-se uma reserva_saldo (ADR 0003), que reduz o saldo disponível da conta sem registrar débito contábil imediato. Em seguida, a custodiante envia a transação à rede. Se a movimentação for CONFIRMADA on-chain, registra-se a Transacao contábil com débito na conta CLIENTE e crédito na conta HOT, e a reserva é liberada com motivo CONFIRMADA. Se ocorrer FALHA, TIMEOUT ou REJEIÇÃO antes da confirmação, a reserva é liberada com o motivo correspondente, o saque permanece no histórico com status final, sem lançamento contábil e sem exclusão de registros (ADR 0002).

## 5. Prova de reservas

Em intervalos definidos, o compliance gera um SnapshotReserva: retrato instantâneo com total devido aos clientes (soma dos saldos ledger), total verificado on-chain nas carteiras da custodiante e Merkle root para publicação externa. Para cada cliente com saldo naquele instante, o snapshot contém uma FolhaProva com saldo devido individual e hash próprio, permitindo que o cliente verifique sua inclusão no conjunto publicado.

SnapshotReserva e FolhaProva são entidades separadas porque cumprem papéis distintos: o snapshot é o cabeçalho agregado (totais, data, Merkle root); a folha é o detalhe por cliente (1:N). Separar evita repetir dados globais em cada linha de cliente, facilita consultas do tipo “qual era meu saldo na data D?” e mantém normalização adequada para o modelo relacional.

## Cardinalidades principais

| Relacionamento | Cardinalidade |
|----------------|---------------|
| Cliente — Conta | 1:N |
| Ativo — Conta | 1:N |
| RedeBlockchain — Ativo | 1:N |
| Transacao — Lancamento | 1:N (mín. 2) |
| Conta — Lancamento | 1:N |
| Cliente — Movimentacao | 1:N |
| Movimentacao — Deposito / Saque | 1:1 (herança ISA) |
| Saque — ReservaSaldo | 1:N (no máximo 1 ativa por saque) |
| SnapshotReserva — FolhaProva | 1:N |
| Cliente — FolhaProva | 1:N (por snapshot) |
