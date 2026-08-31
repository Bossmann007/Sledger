# Notas do workspace Sledger

## Equipe

- **Dupla** — ER, minimundo e DDL feitos **juntos**
- Os **dois** defendem qualquer FK na prova de autoria
- Preencher nomes/RAs no `README.md` antes do PDF

## Preferências

- Aprender fazendo — não entregar texto copiado de IA
- **Sem coautor** de agente no GitHub — commits só dos integrantes
- Ian Coleman: **só** endereços públicos fake para INSERTs demo — nunca seed/passphrase no BD ou online (prod)

## Pastas

| Pasta | Uso |
|-------|-----|
| `docs/` | **Entrega** — minimundo, ER, lógico, normalização |
| `docs/adr/` | Decisões fechadas no grill — fonte da verdade |
| `sql/` | **Entrega** — DDL + dados demo |
| `_referencia-agente/` | Exemplo alinhado aos ADRs — estudo, **não entregar** |
| `lessons/` | Lições 0001–0002 |
| `reference/` | Glossário HTML |

## Decisões rápidas (grill)

- **Modelo:** custodial (Opção 1) — ADR 0004
- **Saldo:** derivado, sem coluna — ADR 0001
- **Saque:** reserva → mempool → confirmada \| falha — ADR 0002
- **Reserva:** tabela `reserva_saldo` — ADR 0003
- **Fraude:** contexto no minimundo only — sem tabela Parte I
- **Produto pós-faculdade:** portfolio → ledger demo → testnet; OSS se B2B/C falhar

## Referências externas

- [`../../referenciascripto/README.md`](../../referenciascripto/README.md) — Honey Island (regulatório, fraude, BTC quântico)

## IA (PUCPR)

> "Durante a preparação deste [TIPO], o(s) autor(es) usaram [FERRAMENTA] para [MOTIVO]. Após usar essa ferramenta, o(s) autor(es) revisaram e editaram o conteúdo conforme necessário e assumem total responsabilidade pelo conteúdo."

## Próximo passo

Lição 0003 + Draw.io: exportar PNG 200% → `docs/er/sledger-conceitual.png`. Dupla preenche justificativas em `docs/02-modelo-conceitual.md`. Minimundo (`docs/01`) ainda é esqueleto — escrever em paralelo para a print e o texto baterem.
