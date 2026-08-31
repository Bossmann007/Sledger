# ADR 0002: Saque — reserva temporária e lançamento só na confirmação on-chain

**Status:** aceito (Rodada 2 grill)

## Contexto

Saque passa por aprovação operacional e broadcast na rede. Enquanto a tx está na mempool, o saldo não pode ser gasto duas vezes, mas o usuário não quer saldo “preso” para sempre se a rede falhar.

Cenário APP fraud (phishing): fraude detectada **antes** da confirmação → rejeitar saque, liberar reserva, **sem** lançamento contábil.

## Decisão

### Estados do saque

```
PENDENTE → APROVADO → (cria RESERVA) → BROADCAST → MEMPOOL
  → CONFIRMADA   → transação contábil + libera RESERVA
  → FALHA/TIMEOUT → libera RESERVA + status FALHA (sem lançamento contábil)
  → REJEITADO    → libera RESERVA se existir (fraude/negação operador)
```

### Regras

1. **Reserva de saldo** — reduz saldo *disponível*, não altera lançamentos. Duração: aprovação até confirmação ou falha.
2. **Lançamento contábil** — só quando tx on-chain **CONFIRMADA** (depósito ou saque).
3. **FALHA/TIMEOUT** — tx não confirmou (mempool drop, fee, rede). Libera reserva; registro do saque permanece com status FALHA. **Proibido DELETE.**
4. **Estorno contábil** — só se já houve lançamento e algo invalida depois (caso raro; nova transação contábil reversa).

## Consequências

- ✅ Alinha “não prender dinheiro” — reserva some após falha
- ✅ Cenário 2 (fraude pré-confirmação): REJEITADO, sem débito no ledger
- ✅ Imutabilidade — histórico de saques falhos auditável
- ⚠️ Parte I: modelar `ReservaSaldo` ou flag em `saque` — decisão lógica na Parte I

## Alternativas rejeitadas

- Débito no approve — prende valor contabilmente antes da rede; estorno frequente
- Sem reserva — dois saques simultâneos gastam mesmo saldo (RA3 concorrência)
