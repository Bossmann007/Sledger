# PROJECT.md — Sledger

Project brain — semi-static. Update when stack or architecture changes.

## Stack

- **Disciplina:** Arquitetura de Banco de Dados (PUCPR, PjBL Sledger)
- **Entrega acadêmica:** Markdown (`docs/`) + DDL MySQL 8 (`sql/`)
- **Ferramenta:** MySQL Workbench — ver [`../../Slides/DocumentacaoMySQL.md`](../../Slides/DocumentacaoMySQL.md)
- **Produto futuro (fora Parte I):** backend custodial + prova de reservas — `src/` ainda não existe

## Commands

```bash
# MySQL Workbench: abrir sql/ quando DDL existir
# Lições locais: abrir lessons/0001-autoria-o-que-e-seu.html no navegador
# Glossário: reference/glossario-sledger.html
```

Sem package manager — repo é documentação + SQL, não app runtime.

## Architecture

Ledger contábil de **custodiante de criptomoedas**: partida dobrada interna, movimentações on-chain (Depósito/Saque com herança), reserva temporária em saque, e prova de reservas periódica (Snapshot + Folha de Prova). Saldo é **derivado** de lançamentos confirmados menos reservas ativas — nunca coluna persistida na Parte I (ADR 0001). Escopo acadêmico ~9 entidades core; ver [`CONTEXT.md`](CONTEXT.md) para vocabulário ubíquo.

```
Cliente → Movimentação (Depósito | Saque) → Tx on-chain
                ↓
Conta ledger ← Lançamento ← Transação contábil (Σ = 0)
                ↓
         reserva_saldo (saque pendente)
                ↓
         Snapshot → Folha de prova (Merkle)
```

## Conventions

- **`docs/` + `sql/`** = entrega PjBL (autoria do aluno)
- **`_referencia-agente/`** = exemplo IA — estudo only, **não entregar**
- **ADRs** em `docs/adr/` — decisões de modelagem (saldo derivado, reserva, saque tardio)
- **Commits GitHub:** só do aluno — sem coautor de agente/IA
- **Minimundo:** palavras próprias — lição 0002 em `lessons/`

## Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-08 | Saldo derivado, não coluna | ADR 0001 — 3FN, prova de autoria |
| 2026-08 | Reserva em tabela `reserva_saldo` | ADR 0003 — saldo disponível = lançamentos − reservas |
| 2026-08 | Lançamento contábil só após confirmação on-chain | ADR 0002 — saque falho libera reserva, sem estorno |
| 2026-08 | Modelo custodial; Ian Coleman só demo | ADR 0004 — alinhado ao feedback professor |
| 2026-08 | Dupla — estudo e entrega conjuntos | Prova autoria: os dois dominam ER |
| 2026-08 | Trilha B: docs/sql = PjBL; src/ = produto | MVP pós-faculdade 1→2→3 |
## Known issues

- `sql/` vazio — DDL ainda não escrito
- `docs/01-minimundo.md` esqueleto — próximo passo do aluno
- Slides herança ER (aula 2+) podem faltar localmente — ver Canvas

## Current work

- **Prazo Parte I:** ~03/09/2026 (RA1: conceitual, lógico, físico, DDL)
- **Próximo:** minimundo → ER → modelo lógico → DDL MySQL
- Live task state: `.cursor/state/checkpoint.json`
