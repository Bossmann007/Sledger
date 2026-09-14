<!-- ENZO-PORTFOLIO-BRAND -->
<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:111111,100:D97706&height=165&section=header&text=Sledger&fontSize=42&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=Double-entry%20digital-asset%20custody%20and%20proof-of-reserves%20project.&descAlignY=57&descSize=14" alt="Sledger" />
</p>

<p align="center"><strong>MySQL · Data Modeling · FinTech</strong></p>

---

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

<!-- ENZO-PORTFOLIO-BRAND-FOOTER -->
<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:111111,100:D97706&height=85&section=footer" alt="Footer" />
</p>
