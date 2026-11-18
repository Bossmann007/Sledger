# Minimundo — Sledger

## 1. Escopo

O Sledger é um sistema de custódia institucional de criptomoedas (modelo custodial). O foco desta Parte I é registrar saldos com partida dobrada, processar depósitos e saques on-chain e publicar prova periódica de reservas. Cadastro de operadores e auditoria detalhada existem como suporte (RA3), mas o eixo central é ledger + custódia + prova.

## 2. Contexto e custódia

O Sledger é um sistema de custódia de ativos digitais com ledger contábil interno e prova periódica de reservas. A custodiante controla as carteiras operacionais on-chain. Cada cliente possui uma conta ledger por ativo (BTC, ETH, …), onde se registram seus direitos sobre aquele ativo. Cada ativo pertence a uma rede blockchain (Bitcoin, Ethereum), que define regras como confirmações mínimas para depósitos. Endereços públicos de recebimento vinculam-se às contas operacionais da custodiante. A custodiante também mantém contas internas hot (online) e cold (offline); essas contas operacionais não pertencem aos clientes — apenas as contas ledger do tipo cliente representam o saldo devido a cada um. Em resumo: o cliente tem direito registrado na conta ledger; a custodiante detém a moeda nas carteiras hot/cold.

### Processos do negócio

O cadastro começa quando a custodiante registra o cliente, seus dados de identificação e seu status operacional. Para cada ativo que o cliente possa custodiar, o sistema mantém uma conta ledger do tipo `CLIENTE`; contas `HOT` e `COLD` representam a custódia operacional e não têm titular cliente. Um ativo só pode ser cadastrado depois que sua rede blockchain estiver registrada, pois a rede define o protocolo e a quantidade padrão de confirmações.

No depósito, o cliente recebe um endereço público vinculado à conta operacional. Ao detectar uma transação na rede, o sistema cria uma movimentação `DEPOSITO` com hash, origem, valor e contagem de confirmações. A movimentação permanece pendente enquanto não atingir o mínimo configurado para o ativo. Um serviço de monitoramento atualiza as confirmações; somente quando o depósito é confirmado o sistema grava a transação contábil balanceada, creditando a conta do cliente e debitando a conta hot correspondente. Hashes repetidos são rejeitados, evitando contabilização duplicada da mesma transação on-chain.

No saque, o cliente solicita valor e endereço de destino. O sistema valida que o valor é positivo, que a conta pertence ao cliente e que o saldo disponível — lançamentos menos reservas ativas — é suficiente. Um operador analisa o pedido e pode aprová-lo ou rejeitá-lo. Na aprovação, uma `ReservaSaldo` bloqueia temporariamente o valor para impedir gasto duplo durante a transmissão. Depois do broadcast, o monitoramento acompanha a confirmação on-chain. A confirmação cria o débito na conta do cliente e o crédito na conta hot; falha, timeout ou rejeição libera a reserva sem apagar o pedido e sem criar lançamento contábil.

Em cada ciclo de prova de reservas, o compliance captura um instante consistente do ledger e das carteiras controladas pela custodiante. O `SnapshotReserva` registra o total devido aos clientes, o total verificado on-chain e a Merkle root publicada. Cada `FolhaProva` associa um cliente ao saldo devido naquele instante e ao hash que compõe a árvore. Assim, o cliente consegue verificar sua inclusão sem receber o saldo dos demais clientes.

### Fluxo de informações

As informações nascem em cadastro, eventos observados na blockchain e solicitações operacionais de saque. O cadastro alimenta contas, endereços e parâmetros de confirmação. O monitoramento on-chain alimenta as movimentações e seus estados, mas só a confirmação produz efeitos no ledger. O ledger é a fonte de verdade dos direitos dos clientes, enquanto as reservas representam apenas bloqueios temporários. No ciclo de prova, o compliance consulta obrigações no ledger e ativos nas carteiras e publica somente o snapshot, a Merkle root e as folhas necessárias para verificação individual. Dados de PII ficam restritos à operação; hashes, totais e provas publicáveis podem ser expostos sem revelar o saldo de terceiros.

### Requisitos não funcionais

O sistema deve manter integridade financeira e auditabilidade: nenhuma linha histórica de ledger ou movimentação deve ser apagada, correções devem ocorrer por estorno, e cada transação contábil deve ter pelo menos dois lançamentos com soma algébrica zero. Para o escopo acadêmico, considera-se volume médio de até 100 mil clientes, até 1 milhão de lançamentos por mês e picos de 50 movimentações on-chain por segundo; o desenho mantém índices nas PKs, FKs, status e chaves naturais para suportar essas consultas sem particionamento na Parte I. Consultas de saldo e verificação devem ter disponibilidade alvo de 99,9% em horário operacional, enquanto a publicação da prova pode ocorrer em janelas agendadas.

O tratamento de PII deve observar minimização e LGPD: documento, nome e e-mail são dados operacionais e devem ter acesso restrito, criptografia em repouso na implantação real e retenção definida pela política da custodiante. Endereços públicos e hashes on-chain não são chaves privadas; sementes, passphrases e chaves privadas ficam fora do banco, idealmente em HSM ou carteira de hardware. Toda alteração operacional relevante deve possuir trilha de auditoria com ator, instante, ação e referência; a Parte I prepara o domínio para `UsuarioSistema` e `RegistroAuditoria`, enquanto o ledger financeiro permanece append-only.

### Relatórios e consultas principais

A operação consulta saldo contábil por conta e ativo, saldo disponível após reservas, depósitos pendentes por confirmações, saques aguardando aprovação ou confirmação e o histórico imutável de lançamentos. O compliance gera o relatório de prova de reservas com total devido, total on-chain, diferença entre os dois e Merkle root, além da folha individual solicitada por cada cliente. A auditoria verifica transações sem equilíbrio, movimentações confirmadas sem transação contábil, reservas ativas incompatíveis com o status do saque e duplicidade de hash de depósito. As consultas de verificação entregues em `sql/02-verificacao.sql` materializam esses controles para a evidência da execução.

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
