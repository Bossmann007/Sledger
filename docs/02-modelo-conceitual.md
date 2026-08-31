# Modelo Conceitual — Diagrama Entidade-Relacionamento

Notação: Heuser — entidades em retângulos, relacionamentos nomeados, cardinalidade `(mín,máx)`, PK sublinhada. **Sem FK nas caixas** (FK entra no modelo lógico). Ferramenta: Draw.io ([`er/sledger-conceitual.drawio`](er/sledger-conceitual.drawio)).

> Lição: [`../lessons/0003-diagrama-er-conceitual.html`](../lessons/0003-diagrama-er-conceitual.html)  
> Mapa: [`../reference/er-conceitual.html`](../reference/er-conceitual.html)

## Print

Exporte do Draw.io: **File → Export as → PNG**, zoom **200%**, fundo branco. Salve em `docs/er/sledger-conceitual.png` e referencie abaixo. O restante deste Markdown deve continuar **texto selecionável** no PDF (feedback do professor).

![Modelo conceitual Sledger](er/sledger-conceitual.png)

## Inventário (13 entidades — eixo Parte I)

| # | Entidade | Papel |
|---|----------|--------|
| 1 | RedeBlockchain | Bitcoin, Ethereum… protocolo e confirmações padrão |
| 2 | Ativo | BTC, ETH… símbolo e casas decimais, numa rede |
| 3 | Cliente | Titular das contas ledger (documento, status) |
| 4 | Conta | Unidade contábil por ativo; cliente **ou** hot/cold da custodiante. Sem saldo persistido |
| 5 | EnderecoCarteira | Endereço on-chain ligado à conta (recebimento / operacional) |
| 6 | Transacao | Evento contábil; soma algébrica dos lançamentos = 0 |
| 7 | Lancamento | Débito ou crédito numa conta; ≥2 por transação |
| 8 | Movimentacao | Supertipo on-chain (cliente, valor, data, status, conta) |
| 9 | Deposito | Subtipo: hash, confirmações, origem |
| 10 | Saque | Subtipo: destino, aprovação |
| 11 | ReservaSaldo | Bloqueio temporário do disponível até confirmar ou falhar |
| 12 | SnapshotReserva | Retrato global + Merkle root |
| 13 | FolhaProva | Comprovante por cliente naquele snapshot |

Fora da print (RA3): UsuarioSistema, RegistroAuditoria.

## Especialização Movimentação → Depósito | Saque

| Propriedade | Valor | Escrevam a justificativa com palavras da dupla |
|-------------|-------|-----------------------------------------------|
| Total | Sim | |
| Exclusiva | Sim | |

## Snapshot vs Folha de Prova

Relação: **1 Snapshot : N Folhas**.

Escrevam por que são duas entidades (não uma coluna “folha” dentro do snapshot) — o professor pediu essa justificativa:

## Cardinalidades (Heuser)

O par (mín,máx) ao lado de A = quantos B aquele A tem. Pé-de-galinha no Draw.io toca o lado N.

| A | (mín,máx) | verbo | (mín,máx) | B |
|---|-----------|-------|-----------|---|
| RedeBlockchain | (0,n) | hospeda | (1,1) | Ativo |
| Ativo | (0,n) | denomina | (1,1) | Conta |
| Cliente | (0,n) | possui | (0,1) | Conta |
| Conta | (0,n) | recebe em | (1,1) | EnderecoCarteira |
| Transacao | (1,n) n≥2 | contém | (1,1) | Lancamento |
| Conta | (0,n) | registra | (1,1) | Lancamento |
| Cliente | (0,n) | solicita | (1,1) | Movimentacao |
| Conta | (0,n) | é afetada por | (1,1) | Movimentacao |
| Movimentacao | (0,1) | gera | (0,1) | Transacao |
| Saque | (0,n) | reserva | (1,1) | ReservaSaldo |
| Conta | (0,n) | sofre | (1,1) | ReservaSaldo |
| SnapshotReserva | (1,n) | contém | (1,1) | FolhaProva |
| Cliente | (0,n) | comprova-se em | (1,1) | FolhaProva |

