# ADR 0001: Saldo derivado de lançamentos (não coluna)

**Status:** aceito (Rodada 2 — alinhado ao RA1/normalização)

## Contexto

Saldo de conta ledger pode ser armazenado como coluna, calculado por VIEW ou agregado em query. Parte I exige normalização; produto exige consultas rápidas.

## Decisão (proposta)

- **Parte I–II (PjBL):** saldo **nunca** é coluna em `conta`. Sempre `SUM(lançamentos) − reservas_ativas`.
- **Parte III / produto:** VIEW `saldo_por_conta` se performance exigir; documentada como desnormalização consciente.

## Consequências

- ✅ 3FN, fácil de defender na prova de autoria
- ✅ Imutabilidade: histórico completo nos lançamentos
- ⚠️ Consultas de saldo exigem JOIN/agregação — aceitável no escopo acadêmico

## Alternativas rejeitadas

- Coluna `saldo_atual` + trigger: risco de dessincronia, difícil de auditar
- Cache externo (Redis): fora do escopo SQL puro da disciplina
