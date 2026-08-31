# Mission: Entregar o Sledger com autoria real (Arquitetura de BD)

## Why

Você precisa **passar na Parte I do PjBL (03/09)** e provar na prova de autoria que **entende** o modelo que apresenta — custódia de cripto, partida dobrada, herança Depósito/Saque e prova de reservas. O objetivo não é ter arquivos prontos; é **saber explicar cada entidade, cada FK e cada trigger** sem depender de cola ou IA na hora H.

## Success looks like

- Escrever o **minimundo** em suas palavras a partir do domínio Sledger (sem copiar texto pronto).
- Desenhar o **diagrama ER** com herança Movimentação → Depósito | Saque e justificar Snapshot vs Folha de Prova.
- Montar **modelo lógico** (tabelas + PK/FK) e **modelo físico** (DDL MySQL) que você executa no Workbench.
- Responder oralmente/ por escrito: "por que esta FK?", "como a partida dobrada é garantida?", "o que muda entre depósito e saque?".
- Entregar PDF **com texto selecionável**, equipe identificada, declaração de IA conforme Resolução PUCPR 274/2024.

## Constraints

- **Autoria:** professor cobra autoria individual — você refaz o conteúdo; material em `_referencia-agente/` é só estudo, **não entregar**.
- **GitHub:** commits só seus; **sem coautor** de agente/IA no histórico.
- **Prazo:** Parte I ~03/09/2026 (RA1: conceitual, lógico, físico, DDL).
- **Feedback já recebido:** herança, escopo central, PDF legível, nomes na capa (`../feedbackprofessor.md`).
- **Ferramenta:** MySQL 8 + Workbench ([guia](../../Slides/DocumentacaoMySQL.md)).

## Pós-faculdade (decisões Rodada 1)

- **Repo:** trilha B — `docs/` + `sql/` = PjBL; `src/` = produto em paralelo (fora do PDF Parte I).
- **Produto:** prova de reservas + ledger + backend custodial, alinhado a regras BCB / blockchain (priorizar MVP na Rodada 2).
- **Escopo acadêmico:** eixo estrito (~9 entidades core) — ver `CONTEXT.md`.
- **Equipe:** mesma equipe no PjBL e no lançamento (autoria coletiva na faculdade).
- **Saque falho:** reserva temporária; lançamento só na confirmação on-chain; FALHA libera reserva (ADR 0002).
- **Produto:** MVP 1→2→3; v1 = portfolio (Q8 A); OSS (D) se B2B/B2C não decolar.
- **Autoria equipe:** dupla — ER e DDL **juntos**; os dois defendem qualquer FK na prova (Q10 B adaptado).
- **Reserva:** tabela `reserva_saldo` separada (ADR 0003).
- **Fraude Parte I:** só contexto no minimundo — eixo é ledger + reservas (feedback professor).
- **Modelo custodial (Opção 1):** custodiante guarda on-chain; Ian Coleman só endereços demo — ADR 0004.

## Out of scope (Parte I)

- Parte II/III completas, KYC, taxas, multi-sig — só esqueleto se necessário pro RA3.
- Mainnet com dinheiro real — testnet/demo only.
