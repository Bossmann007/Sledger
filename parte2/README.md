# Sledger — Parte 2 (RA2) e Parte 1 corrigida

Scripts SQL e gerador de dados da Parte 2, executados em **MySQL 8** (InnoDB, com CHECK e chaves estrangeiras ativas).

## Ordem de execução

Execute em um MySQL 8 local, sempre nesta ordem. `01-ddl.sql` apaga e recria o schema `sys2`.

| Arquivo | Conteúdo |
|---|---|
| `01-ddl.sql` | DDL da Parte 1 (13 tabelas, CHECKs, FKs) |
| `02-melhorias.sql` | Melhorias M1–M7 (snapshot por ativo, conta única por cliente e ativo, cotação USD, motivo de rejeição do saque, novos CHECKs, índices, view `vw_saldo_conta`) |
| `03-dados.sql` | Carga simulada, gerada por `gerar-dados.py` |
| `04-consultas.sql` | J01–J10 (JOIN), G01–G05 (GROUP BY + HAVING), S01–S05 (subconsultas) |
| `05-alteracoes.sql` | U01–U03 (UPDATE) e D01 (DELETE), com antes e depois |
| `06-consultas-professor.sql` | P01–P10, as dez consultas do professor (`SLEDGER.pdf`), e P08b, que prova que a P08 detecta erro |
| `07-validacao.sql` | V00 (contagens) e V01–V11 (consistência; todas devem retornar vazio) |
| `08-testes-melhorias.sql` | T01–T07: cada melhoria recusando um dado inválido, `EXPLAIN` dos índices e conferência da view; tudo desfeito com `ROLLBACK` |

`04-consultas.sql`, `05-alteracoes.sql` e `06-consultas-professor.sql` não estão neste repositório público.

```bash
for f in 01-ddl 02-melhorias 03-dados 04-consultas 05-alteracoes 06-consultas-professor 07-validacao; do
  mysql -u root < "$f.sql"
done
mysql -u root --force < 08-testes-melhorias.sql   # os erros são o resultado esperado
```

## Regenerar os dados

A partir desta pasta, com Python 3:

```bash
python3 gerar-dados.py   # reescreve 03-dados.sql (semente fixa, resultado determinístico)
```

## Linhas por tabela (após o DELETE)

| Tabela | Linhas |
|---|---:|
| RedeBlockchain | 20 (21 antes de D01) |
| Ativo | 20 |
| Cliente | 20 |
| Conta | 121 |
| EnderecoCarteira | 60 |
| Transacao | 135 |
| Lancamento | 270 |
| Movimentacao | 142 |
| Deposito | 115 |
| Saque | 27 |
| ReservaSaldo | 21 |
| SnapshotReserva | 40 |
| FolhaProva | 162 |
