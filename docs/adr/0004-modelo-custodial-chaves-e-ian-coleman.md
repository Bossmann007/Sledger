# ADR 0004: Modelo custodial — chaves, Ian Coleman, PII

**Status:** aceito

## Decisão

**Modelo 1 — custodial.** Custodiante controla hot/cold. Cliente tem **conta ledger** (saldo visível à operação). Prova de reservas mantida.

### Ian Coleman

- **Só** endereços públicos fake para INSERTs demo / testnet
- **Nunca** seed, passphrase ou chave privada no MySQL ou no site (prod)
- Produção real: fora escopo PjBL (HSM/HW wallet)

### Segurança no modelo

| Dado | Regra |
|------|--------|
| Chaves privadas | Fora do BD; custodiante em infra segura |
| PII (CPF, nome) | Cifrar ou hash+salt |
| Endereço on-chain | Público |
| Saldo ledger | Custodiante vê — necessário p/ operação |
| Operadores | RA3: perfis + auditoria |

## Rejeitado

- Non-custodial / corretora cega ao saldo (Opção 3)
- Ian Coleman com passphrase real para clientes

## Minimundo (1 frase)

> A custodiante guarda os ativos on-chain; o cliente tem direito contábil na conta ledger interna — prova de reservas compara o devido ao que existe on-chain.
