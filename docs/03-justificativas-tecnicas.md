# Justificativas Técnicas da Modelagem — Sledger

Ferramenta: MySQL Workbench · schema `sledger` · 13 entidades

---

## Relacionamentos

### Cadastro

- **RedeBlockchain → Ativo (1:N)** → todo ativo pertence a uma rede; rede pode ter vários ativos
- **Ativo → Conta (1:N)** → conta sempre em um ativo; muitas contas por ativo (clientes + hot/cold)
- **Cliente → Conta (1:N, opcional na Conta)** → cliente tem várias contas; hot/cold sem cliente (`id_cliente` NULL)
- **Conta → EnderecoCarteira (1:N)** → vários endereços por conta; cada endereço em uma conta só

### Ledger (partida dobrada)

- **Transacao → Lancamento (1:N, mín. 2)** → soma algébrica zero; um evento, vários débitos/créditos
- **Conta → Lancamento (1:N)** → cada lançamento em uma conta; saldo = soma dos lançamentos
- **Movimentacao → Transacao (0:1)** → lançamento contábil só após confirmação on-chain; pendente/falha = sem transação

### On-chain

- **Cliente → Movimentacao (1:N)** → depósito/saque sempre iniciado por cliente
- **Conta → Movimentacao (1:N)** → movimentação aponta conta ledger afetada
- **Movimentacao → Deposito | Saque (1:1 ISA)** → herança total e exclusiva; comum no supertipo, particular no subtipo
- **Saque → ReservaSaldo (1:N)** → histórico de reservas; no máximo uma ativa (`liberada_em` NULL)
- **Conta → ReservaSaldo (1:N)** → reserva reduz saldo disponível, não altera lançamentos

### Prova de reservas

- **SnapshotReserva → FolhaProva (1:N)** → snapshot = cabeçalho (totais + Merkle); folha = item por cliente
- **Cliente → FolhaProva (1:N)** → mesmo cliente em vários snapshots ao longo do tempo

### N:N

- **Não há N:N direto**
- **Cliente ↔ Ativo** → resolvido por **Conta** (associativa enriquecida: `tipo`, `status`, PK própria)
- **Por quê não par (cliente, ativo)?** → hot/cold sem cliente; lançamentos precisam de conta estável

---

## Chaves Primárias (PK)

**Padrão:** surrogate `INT AUTO_INCREMENT` em entidades fortes

- **RedeBlockchain.id_rede** → artificial; `nome` pode mudar (rebrand)
- **Ativo.id_ativo** → artificial; `simbolo` repete em redes (ex.: USDT)
- **Cliente.id_cliente** → artificial; `documento` fica UNIQUE, não PK
- **Conta.id_conta** → artificial; par (cliente, ativo) falha com `id_cliente` NULL
- **EnderecoCarteira.id_endereco** → artificial; `endereco` é UNIQUE natural
- **Transacao.id_transacao** → artificial; agrupa lançamentos
- **Lancamento.id_lancamento** → artificial; linha imutável do ledger
- **Movimentacao.id_movimentacao** → artificial; supertipo da herança
- **Deposito.id_movimentacao / Saque.id_movimentacao** → PK = FK do supertipo (ISA 1:1)
- **ReservaSaldo.id_reserva** → artificial; histórico de liberações
- **SnapshotReserva.id_snapshot** → artificial; instantâneo publicável
- **FolhaProva.id_folha** → artificial; UK (snapshot, cliente) na implementação

**Impacto** → JOINs rápidos, FKs estáveis, sem depender de formato externo mutável

---

## Chaves Estrangeiras (FK)

- **Ativo.id_rede → RedeBlockchain** → ativo sem rede inválido
- **Conta.id_ativo → Ativo** → conta sempre denominada
- **Conta.id_cliente → Cliente (nullable)** → titular opcional (hot/cold)
- **EnderecoCarteira.id_conta → Conta** → endereço pertence a conta
- **Lancamento.id_transacao → Transacao** → lançamento sempre em evento contábil
- **Lancamento.id_conta → Conta** → débito/crédito em conta existente
- **Movimentacao.id_cliente / id_ativo / id_conta** → contexto completo on-chain
- **Deposito.id_movimentacao / Saque.id_movimentacao → Movimentacao** → herança 1:1
- **ReservaSaldo.id_saque → Saque** → reserva ligada ao saque
- **ReservaSaldo.id_conta → Conta** → conta com disponível reduzido
- **FolhaProva.id_snapshot → SnapshotReserva** → folha pertence ao instante
- **FolhaProva.id_cliente → Cliente** → quem está sendo comprovado

**Política** → `ON DELETE RESTRICT` nas relações críticas (sem apagar histórico financeiro)

---

## Atributos e Domínios

- **DECIMAL(20,8)** → valores monetários; 8 casas decimais; sem erro de FLOAT
- **VARCHAR(14) + UQ + NN** → `Cliente.documento` (CPF/CNPJ)
- **VARCHAR(100) + UQ** → `EnderecoCarteira.endereco`
- **DATETIME + NN** → datas operacionais (auditoria)
- **ENUM** → domínios fechados (`status`, `tipo`, `motivo_liberacao`)
- **NN em FKs obrigatórias** → integridade mandatória
- **sem NN em Conta.id_cliente** → hot/cold sem titular
- **sem NN em ReservaSaldo.liberada_em** → NULL = reserva ativa
- **sem coluna saldo em Conta** → derivado de lançamentos − reservas
- **sem seed/chave privada no BD** → segurança; modelo custodial

---

## Normalização

- **1FN** → atributos atômicos (um endereço por linha)
- **2FN** → atributos dependem da PK inteira (subtipos só de `id_movimentacao`)
- **3FN** → sem transitiva; saldo fora de Conta (dependeria de Lancamento)
- **Snapshot totais** → medida do instante, não cache em tempo real
- **Desnormalização Parte I** → nenhuma
- **VIEW saldo (Parte III)** → leitura só; documentada à parte

---

## Especializações (ISA)

- **Movimentacao → Deposito | Saque**
- **Total** → toda movimentação é depósito ou saque
- **Exclusiva** → nunca os dois
- **Comum em Movimentacao** → cliente, ativo, valor, conta, data, status
- **Só em Deposito** → `tx_hash_rede`, confirmações, origem
- **Só em Saque** → destino, aprovação, reserva
- **Implementação** → PK = FK (`id_movimentacao`) em cada subtipo

---

## Desempenho e Escalabilidade

- **PK INT** → índice B-tree compacto
- **UK documento, endereco** → busca sem full scan
- **Índice Lancamento(id_conta)** → saldo por agregação
- **Índice ReservaSaldo(id_conta) WHERE liberada_em IS NULL** → disponível
- **Índice Movimentacao(status)** → fila pendente
- **Ledger separado de on-chain** → escala cada eixo sem reescrever o outro
- **Particionamento por data** → expansão futura; não na Parte I

---

## Alternativas Descartadas

- **saldo_atual em Conta + trigger** → dessincronia; difícil auditar
- **movimentação única com tipo + NULL** → sem herança; muitos campos vazios
- **valor_bloqueado só em Saque** → sem histórico de liberação
- **Folha como JSON no Snapshot** → sem FK para Cliente
- **non-custodial** → fora do domínio adotado
- **DELETE em saque falho** → viola imutabilidade; usa status FALHA
- **lançamento no approve** → débito antes da rede; estorno frequente

---

## Defesa rápida (oral)

- Partida dobrada → Transacao + ≥2 Lancamentos, soma zero
- Saldo → derivado, nunca coluna
- Herança → Movimentacao 1:1 Deposito ou Saque
- Saque → reserva primeiro; lançamento só na confirmação
- Prova → Snapshot (global) + Folha (por cliente)
