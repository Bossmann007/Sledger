# Sledger — Arquitetura de Banco de Dados (PUCPR)

Sistema de custódia de criptomoedas com partida dobrada e prova de reservas — **Parte I** (PjBL).

## Integrantes

| Nome | RA |
|------|-----|
| | |
| | |

## Entrega (`docs/` + `sql/`)

| Arquivo | Conteúdo |
|---------|----------|
| [`docs/00-declaracao-uso-ia.md`](docs/00-declaracao-uso-ia.md) | Declaração PUCPR 274/2024 (incluir no PDF) |
| [`docs/01-minimundo.md`](docs/01-minimundo.md) | Minimundo |
| [`docs/02-modelo-conceitual.md`](docs/02-modelo-conceitual.md) | Modelo conceitual + print do ER |
| [`docs/03-justificativas-tecnicas.md`](docs/03-justificativas-tecnicas.md) | Justificativas (PK, FK, normalização) |
| [`docs/err/`](docs/err/) | Diagrama ER (Workbench `.mwb` + PDF) |
| [`docs/adr/`](docs/adr/) | Decisões de modelagem (ADRs 0001–0004) |
| [`sql/01-ddl.sql`](sql/01-ddl.sql) | DDL MySQL 8 |

## Como rodar o SQL

```bash
mysql -u root -p < sql/01-ddl.sql
```

No MySQL Workbench: **File → Open SQL Script** → `sql/01-ddl.sql` → Execute.

## Decisões principais

1. Saldo derivado — sem coluna em `Conta`
2. Lançamento contábil só após confirmação on-chain
3. Reserva temporária em `ReservaSaldo`
4. Modelo custodial; herança Movimentação → Depósito \| Saque
