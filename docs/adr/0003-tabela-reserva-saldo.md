# ADR 0003: Tabela `reserva_saldo` separada

**Status:** aceito (Rodada 3 grill)

## Contexto

Reserva temporária durante saque pode ser coluna em `saque` ou entidade própria. Equipe escolheu tabela separada (Q12 B) — prepara RA3 (concorrência, `SELECT FOR UPDATE`) e deixa explícito saldo disponível = lançamentos − reservas ativas.

## Decisão

Tabela **`reserva_saldo`**:

| Coluna | Papel |
|--------|--------|
| id_reserva | PK |
| id_saque | FK → saque (1:1 enquanto ativa) |
| id_conta | FK → conta ledger |
| valor | DECIMAL |
| criada_em | DATETIME |
| liberada_em | NULL = ativa; preenchida = liberada |
| motivo_liberacao | ENUM: CONFIRMADA, FALHA, REJEITADA, TIMEOUT |

Regra: no máximo uma reserva **ativa** por saque. Saldo disponível exclui reservas com `liberada_em IS NULL`.

## Consequências

- ✅ Modela concorrência sem coluna `valor_bloqueado` duplicada em `saque`
- ✅ Histórico de reservas liberadas (auditoria)
- ⚠️ +1 tabela no escopo — ainda dentro do eixo custódia (não é fraude/KYC)

## Alternativa rejeitada

- `saque.valor_bloqueado` only — mais simples, pior para RA3 e histórico de liberação
