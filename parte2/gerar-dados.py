"""Gera a carga simulada do Sledger (Parte 2).

Execute a partir da raiz do repositório: python3 parte2/gerar-dados.py
Saída: parte2/03-dados.sql. Não usa rede nem dados pessoais reais; CPFs e CNPJs
são fictícios, porém com dígitos verificadores válidos.

A carga é produzida por uma simulação cronológica: cada evento só acontece se o
saldo disponível (lançamentos menos reservas ativas) permitir, cada transação
contábil fecha em zero e cada snapshot é calculado a partir do ledger no instante
da captura, com Merkle root real sobre as folhas.
"""

import random
from datetime import datetime, timedelta
from decimal import Decimal, ROUND_DOWN
from hashlib import sha256
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent / "03-dados.sql"
rng = random.Random(2026)
Q8 = Decimal("0.00000001")

# --------------------------------------------------------------------------- redes e ativos
NETWORKS = [  # nome, protocolo, confirmações, família de endereço
    ("Bitcoin", "UTXO / Proof of Work", 3, "btc"),
    ("Ethereum", "EVM / Proof of Stake", 12, "evm"),
    ("Solana", "Proof of History + PoS", 32, "sol"),
    ("Tron", "TVM / Delegated PoS", 20, "trx"),
    ("Polygon PoS", "EVM / Proof of Stake", 128, "evm"),
    ("BNB Smart Chain", "EVM / Proof of Staked Auth.", 15, "evm"),
    ("Avalanche C-Chain", "EVM / Snowman", 1, "evm"),
    ("Arbitrum One", "EVM / Optimistic Rollup", 20, "evm"),
    ("OP Mainnet", "EVM / Optimistic Rollup", 20, "evm"),
    ("Base", "EVM / Optimistic Rollup", 20, "evm"),
    ("Litecoin", "UTXO / Proof of Work", 6, "ltc"),
    ("Dogecoin", "UTXO / Proof of Work", 40, "doge"),
    ("Cardano", "eUTXO / Ouroboros PoS", 15, "ada"),
    ("Polkadot", "Nominated Proof of Stake", 2, "dot"),
    ("XRP Ledger", "XRP Ledger Consensus", 1, "xrp"),
    ("Stellar", "Stellar Consensus Protocol", 1, "xlm"),
    ("Cosmos Hub", "Tendermint / CometBFT", 1, "atom"),
    ("NEAR Protocol", "Nightshade PoS", 3, "near"),
    ("Algorand", "Pure Proof of Stake", 1, "algo"),
    ("Tezos", "Liquid Proof of Stake", 2, "xtz"),
]
TESTNET = ("Ethereum Sepolia (testnet)", "EVM / Proof of Stake", 12)

ASSETS = [  # símbolo, nome, casas decimais, preço de referência em USD (rede = posição)
    ("BTC", "Bitcoin", 8, "98450.00"),
    ("ETH", "Ether", 18, "3412.50"),
    ("SOL", "Solana", 9, "162.30"),
    ("USDT", "Tether USD (TRC-20)", 6, "1.0002"),
    ("POL", "Polygon Ecosystem Token", 18, "0.4510"),
    ("BNB", "BNB", 18, "604.80"),
    ("AVAX", "Avalanche", 18, "31.20"),
    ("ARB", "Arbitrum", 18, "0.8120"),
    ("OP", "Optimism", 18, "1.7340"),
    ("USDC", "USD Coin (Base)", 6, "0.9998"),
    ("LTC", "Litecoin", 8, "86.40"),
    ("DOGE", "Dogecoin", 8, "0.1532"),
    ("ADA", "Cardano", 6, "0.6120"),
    ("DOT", "Polkadot", 10, "6.4800"),
    ("XRP", "XRP", 6, "0.5530"),
    ("XLM", "Stellar Lumens", 7, "0.1140"),
    ("ATOM", "Cosmos", 6, "7.5200"),
    ("NEAR", "NEAR", 24, "4.8100"),
    ("ALGO", "Algorand", 6, "0.1810"),
    ("XTZ", "Tezos", 6, "0.8530"),
]
SYMBOL_ID = {s[0]: i for i, s in enumerate(ASSETS, start=1)}
PRICE = {i: Decimal(a[3]) for i, a in enumerate(ASSETS, start=1)}
CONF = {i: n[2] for i, n in enumerate(NETWORKS, start=1)}
FAMILY = {i: n[3] for i, n in enumerate(NETWORKS, start=1)}

# --------------------------------------------------------------------------- clientes
PEOPLE = [
    "Ana Beatriz Moreira", "Bruno Carvalho Lima", "Camila Ferreira Santos",
    "Diego Almeida Rocha", "Eduarda Nogueira Pires", "Felipe Barbosa Teixeira",
    "Gabriela Martins Costa", "Henrique Souza Ribeiro", "Isabela Cardoso Mendes",
    "João Pedro Azevedo", "Larissa Gomes Duarte", "Marcelo Vieira Campos",
    "Natália Ramos Freitas", "Otávio Pereira Lopes", "Paula Cristina Araújo",
]
COMPANIES = [
    ("Vértice Capital Gestora de Recursos Ltda", "contato@verticecapital.example.com"),
    ("Araucária Tesouraria Digital S.A.", "tesouraria@araucaria.example.com"),
    ("Nimbus Pagamentos Ltda", "financeiro@nimbuspag.example.com"),
    ("Litoral Trading de Ativos Ltda", "operacoes@litoraltrading.example.com"),
    ("Pinhão Ventures Participações S.A.", "backoffice@pinhaoventures.example.com"),
]
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
B32L = "023456789acdefghjklmnpqrstuvwxyz"
B32U = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
HEX = "0123456789abcdef"


def cpf():
    base = [rng.randint(0, 9) for _ in range(9)]
    for weight_start in (10, 11):
        total = sum(d * w for d, w in zip(base, range(weight_start, 1, -1)))
        base.append(0 if total % 11 < 2 else 11 - total % 11)
    return "".join(map(str, base))


def cnpj():
    base = [rng.randint(0, 9) for _ in range(8)] + [0, 0, 0, 1]
    for weights in ([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2], [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]):
        total = sum(d * w for d, w in zip(base, weights))
        base.append(0 if total % 11 < 2 else 11 - total % 11)
    return "".join(map(str, base))


def chars(alphabet, n):
    return "".join(rng.choice(alphabet) for _ in range(n))


def address(id_rede):
    family = FAMILY[id_rede]
    return {
        "btc": lambda: "bc1q" + chars(B32L, 38),
        "ltc": lambda: "ltc1q" + chars(B32L, 38),
        "doge": lambda: "D" + chars(B58, 33),
        "evm": lambda: "0x" + chars(HEX, 40),
        "sol": lambda: chars(B58, 44),
        "trx": lambda: "T" + chars(B58, 33),
        "ada": lambda: "addr1q" + chars(B32L, 52),
        "dot": lambda: "1" + chars(B58, 47),
        "xrp": lambda: "r" + chars(B58, 33),
        "xlm": lambda: "G" + chars(B32U, 55),
        "atom": lambda: "cosmos1" + chars(B32L, 38),
        "near": lambda: chars(HEX, 64),
        "algo": lambda: chars(B32U, 58),
        "xtz": lambda: "tz1" + chars(B58, 33),
    }[family]()


def tx_hash(id_rede):
    return ("0x" if FAMILY[id_rede] == "evm" else "") + chars(HEX, 64)


def units(id_ativo, usd):
    """Converte um valor em USD para unidades do ativo, com 4 algarismos significativos."""
    raw = Decimal(usd) / PRICE[id_ativo]
    exponent = raw.adjusted() - 3
    step = Decimal(1).scaleb(max(exponent, -8))
    return raw.quantize(step, rounding=ROUND_DOWN).quantize(Q8)


def ts(dt):
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def moment(day_from, day_to, month=9):
    start = datetime(2026, month, day_from, 8, 0)
    span = (datetime(2026, month, day_to, 22, 0) - start).total_seconds()
    return start + timedelta(seconds=rng.randint(0, int(span)))


clients = []
for i, name in enumerate(PEOPLE, start=1):
    first, *_, last = name.split()
    email = f"{first.lower()}.{last.lower()}@example.com".translate(str.maketrans("áâãéêíóôõúç", "aaaeeiooouc"))
    clients.append([i, cpf(), name, email, "ATIVO", ts(moment(1, 28, 8))])
for j, (name, email) in enumerate(COMPANIES, start=len(PEOPLE) + 1):
    clients.append([j, cnpj(), name, email, "ATIVO", ts(moment(1, 28, 8))])
clients[17][4] = "SUSPENSO"  # id 18, Nimbus Pagamentos: KYC societário em revisão

# --------------------------------------------------------------------------- contas
accounts = []  # id, id_cliente, id_ativo, tipo, status
for a in range(1, 21):
    accounts.append([a, None, a, "HOT", "ATIVA"])
for a in range(1, 21):
    accounts.append([20 + a, None, a, "COLD", "ATIVA"])

holdings = set()
for a in range(1, 21):  # todo ativo tem pelo menos dois titulares
    holdings.add(((a - 1) % 20 + 1, a))
    holdings.add(((a + 6) % 20 + 1, a))
for c in range(1, 21):  # ativos populares
    if c % 4 != 3:
        holdings.add((c, SYMBOL_ID["BTC"]))
    if c % 2 == 0 or c > 15:
        holdings.add((c, SYMBOL_ID["ETH"]))
    if c % 3 == 0 or c > 15:
        holdings.add((c, SYMBOL_ID["USDT"]))
    if c % 5 == 1:
        holdings.add((c, SYMBOL_ID["SOL"]))
    if c > 16:
        holdings.add((c, SYMBOL_ID["USDC"]))

client_account = {}
for c, a in sorted(holdings):
    acc_id = len(accounts) + 1
    accounts.append([acc_id, c, a, "CLIENTE", "ATIVA"])
    client_account[(c, a)] = acc_id
hot = {a: a for a in range(1, 21)}
cold = {a: 20 + a for a in range(1, 21)}

addresses = []
for a in range(1, 21):
    addresses.append([len(addresses) + 1, hot[a], address(a), "DEPOSITO"])
    addresses.append([len(addresses) + 1, hot[a], address(a), "SAQUE"])
    addresses.append([len(addresses) + 1, cold[a], address(a), "DEPOSITO"])

# --------------------------------------------------------------------------- simulação
transactions, entries, movements, deposits, withdrawals, reserves = [], [], [], [], [], []
balance = {acc[0]: Decimal(0) for acc in accounts}  # CREDITO - DEBITO
active_reserve = {}  # id_conta -> soma reservada
events = []  # (instante, função) executados em ordem cronológica


def post(when, description, reference, legs, status="CONFIRMADA"):
    tx_id = len(transactions) + 1
    transactions.append([tx_id, ts(when), description, reference, status])
    for acc_id, kind, value in legs:
        entries.append([len(entries) + 1, tx_id, acc_id, kind, value])
        balance[acc_id] += value if kind == "CREDITO" else -value
    return tx_id


def available(acc_id):
    return balance[acc_id] - active_reserve.get(acc_id, Decimal(0))


def custody(a):
    return -(balance[hot[a]] + balance[cold[a]])


def new_movement(c, a, value, when, status, kind, tx_id=None):
    mov_id = len(movements) + 1
    movements.append([mov_id, c, a, client_account[(c, a)], tx_id, value, ts(when), status, kind])
    return mov_id


def fmt(value):
    return f"{value.normalize():f}"


def deposit(c, a, usd, when, status="CONFIRMADA", confirmations=None):
    value = units(a, usd)
    acc = client_account[(c, a)]
    origin, chash = address(a), tx_hash(a)
    minimum = CONF[a]
    symbol = ASSETS[a - 1][0]
    mov_id = new_movement(c, a, value, when, status, "DEPOSITO")
    tx_id = None
    if status == "CONFIRMADA":
        confirmations = minimum + rng.randint(0, 25)
        confirmed_at = when + timedelta(minutes=rng.randint(5, 90))
        tx_id = post(confirmed_at, f"Depósito on-chain confirmado: {fmt(value)} {symbol}", chash,
                     [(acc, "CREDITO", value), (hot[a], "DEBITO", value)])
        movements[mov_id - 1][4] = tx_id
    deposits.append([mov_id, chash, minimum, confirmations or 0, origin])
    return mov_id


def withdraw(c, a, usd, when, outcome, reason=None):
    """outcome: CONFIRMADA, FALHA, TIMEOUT, PENDENTE (aprovado), AGUARDANDO, REJEITADO."""
    acc = client_account[(c, a)]
    value = units(a, usd) if usd else (available(acc) * Decimal("0.4")).quantize(Q8)
    if reason == "SALDO_INSUFICIENTE":
        value = (available(acc) * Decimal("1.35")).quantize(Q8)
    elif value <= 0 or value > available(acc):
        return None
    symbol = ASSETS[a - 1][0]
    if outcome == "CONFIRMADA" and -balance[hot[a]] < value:
        rebalance = min(-balance[cold[a]], (value * Decimal("1.5")).quantize(Q8))
        if rebalance > 0:
            post(when, f"Rebalanceamento cold → hot de {fmt(rebalance)} {symbol}",
                 f"REBAL-{symbol}-{when:%m%d%H%M}",
                 [(hot[a], "DEBITO", rebalance), (cold[a], "CREDITO", rebalance)])
        if -balance[hot[a]] < value:
            return None
    status = {"CONFIRMADA": "CONFIRMADA", "FALHA": "FALHA", "TIMEOUT": "FALHA",
              "PENDENTE": "PENDENTE", "AGUARDANDO": "PENDENTE", "REJEITADO": "CANCELADA"}[outcome]
    mov_id = new_movement(c, a, value, when, status, "SAQUE")
    approved = outcome in ("CONFIRMADA", "FALHA", "TIMEOUT", "PENDENTE")
    approved_at = when + timedelta(minutes=rng.randint(10, 120)) if approved else None
    broadcast = outcome in ("CONFIRMADA", "FALHA", "PENDENTE")
    chash = tx_hash(a) if broadcast else None
    motive = {"FALHA": "FALHA_REDE", "TIMEOUT": "TIMEOUT"}.get(outcome, reason)
    withdrawals.append([mov_id, address(a), "APROVADO" if approved else
                        "REJEITADO" if outcome == "REJEITADO" else "PENDENTE",
                        ts(approved_at) if approved_at else None, motive, chash])
    if not approved:
        return mov_id
    reserve = [len(reserves) + 1, mov_id, acc, value, ts(approved_at), None, None]
    reserves.append(reserve)
    active_reserve[acc] = active_reserve.get(acc, Decimal(0)) + value
    if outcome == "PENDENTE":
        return mov_id
    closed_at = approved_at + (timedelta(hours=26) if outcome == "TIMEOUT"
                               else timedelta(minutes=rng.randint(15, 240)))
    active_reserve[acc] -= value
    reserve[5], reserve[6] = ts(closed_at), {"CONFIRMADA": "CONFIRMADA", "FALHA": "FALHA",
                                             "TIMEOUT": "TIMEOUT"}[outcome]
    if outcome == "CONFIRMADA":
        tx_id = post(closed_at, f"Saque on-chain confirmado: {fmt(value)} {symbol}", chash,
                     [(acc, "DEBITO", value), (hot[a], "CREDITO", value)])
        movements[mov_id - 1][4] = tx_id
    return mov_id


def transfer(src, dst, a, share, when, reversed_=False):
    acc_src, acc_dst = client_account[(src, a)], client_account[(dst, a)]
    value = (available(acc_src) * Decimal(share)).quantize(Decimal(1).scaleb(-6)).quantize(Q8)
    if value <= 0:
        return
    symbol = ASSETS[a - 1][0]
    ref = f"TRF-{sum(1 for t in transactions if t[3] and t[3].startswith('TRF')) + 1:04d}"
    tx_id = post(when, f"Transferência interna entre clientes: {fmt(value)} {symbol}", ref,
                 [(acc_src, "DEBITO", value), (acc_dst, "CREDITO", value)],
                 "ESTORNADA" if reversed_ else "CONFIRMADA")
    if reversed_:
        post(when + timedelta(hours=3), f"Estorno da transação {tx_id} (destinatário incorreto)",
             f"EST-{tx_id:04d}", [(acc_dst, "DEBITO", value), (acc_src, "CREDITO", value)])


def sweep(a, when):
    value = (-balance[hot[a]] * Decimal("0.6")).quantize(Decimal(1).scaleb(-6)).quantize(Q8)
    if value > 0:
        post(when, f"Sweep hot → cold de {fmt(value)} {ASSETS[a - 1][0]}",
             f"SWEEP-{ASSETS[a - 1][0]}-{when:%m%d}",
             [(cold[a], "DEBITO", value), (hot[a], "CREDITO", value)])


# depósito inicial de cada conta de cliente (1 a 10/set)
for (c, a), _ in sorted(client_account.items()):
    events.append((moment(1, 10), lambda c=c, a=a: deposit(c, a, rng.choice([800, 1500, 2500, 4000, 7500, 12000, 20000]) * rng.uniform(0.8, 1.2), events_now[0])))
# depósitos recorrentes (11/set a 9/out)
for _ in range(26):
    c, a = rng.choice(sorted(client_account))
    when = moment(11, 30) if rng.random() < 0.6 else moment(1, 9, 10)
    events.append((when, lambda c=c, a=a: deposit(c, a, rng.choice([500, 1000, 3000, 6000]), events_now[0])))
# depósitos que falharam na rede (substituídos/dropped)
for c, a in [(4, SYMBOL_ID["BTC"]), (12, SYMBOL_ID["DOGE"])]:
    events.append((moment(18, 22), lambda c=c, a=a: deposit(c, a, 900, events_now[0], "FALHA", 0)))
# sweeps hot -> cold
for sym, day in [("BTC", 15), ("ETH", 15), ("USDT", 16), ("SOL", 17), ("BTC", 30), ("ETH", 30), ("USDC", 30), ("BNB", 25)]:
    events.append((datetime(2026, 9, day, 3, 0), lambda a=SYMBOL_ID[sym]: sweep(a, events_now[0])))
# transferências internas (uma estornada)
eth, btc, usdt = SYMBOL_ID["ETH"], SYMBOL_ID["BTC"], SYMBOL_ID["USDT"]
for src, dst, a, share, when, rev in [
    (1, 2, btc, "0.25", datetime(2026, 9, 18, 14, 5), False),
    (2, 4, eth, "0.30", datetime(2026, 9, 21, 10, 40), False),
    (16, 17, usdt, "0.20", datetime(2026, 9, 23, 16, 15), False),
    (17, 1, btc, "0.15", datetime(2026, 9, 26, 11, 0), False),
    (6, 8, eth, "0.10", datetime(2026, 10, 2, 9, 30), True),
    (20, 18, eth, "0.35", datetime(2026, 10, 3, 15, 20), False),
    (1, 5, btc, "0.10", datetime(2026, 10, 6, 13, 45), False),
]:
    if (src, a) in client_account and (dst, a) in client_account:
        events.append((when, lambda s=src, d=dst, a=a, sh=share, r=rev: transfer(s, d, a, sh, events_now[0], r)))

# saques
plan = (
    [("CONFIRMADA", None)] * 12 + [("FALHA", None)] * 3 + [("TIMEOUT", None)]
    + [("REJEITADO", "SALDO_INSUFICIENTE")] * 2 + [("REJEITADO", "APROVACAO_NEGADA")] * 2
)
# janelas terminam antes dos snapshots: liquidação (até ~6 h, ou 26 h no timeout) não cruza a captura
saque_slots = [moment(12, 27) if k % 2 else moment(1, 8, 10) for k in range(len(plan))]
for (outcome, reason), when in zip(plan, saque_slots):
    c, a = rng.choice(sorted(client_account))
    events.append((when, lambda c=c, a=a, o=outcome, r=reason: withdraw(c, a, None, events_now[0], o, r)))
# fila atual: 5 saques aprovados aguardando a rede, 2 aguardando análise
for k, (c, sym) in enumerate([(1, "BTC"), (3, "USDT"), (8, "ETH"), (16, "ETH"), (19, "USDC")]):
    events.append((datetime(2026, 10, 9 + k % 3, 9 + k, 15), lambda c=c, a=SYMBOL_ID[sym]: withdraw(c, a, None, events_now[0], "PENDENTE")))
for c, sym in [(12, "BTC"), (20, "USDT")]:
    events.append((datetime(2026, 10, 12, 17, 30), lambda c=c, a=SYMBOL_ID[sym]: withdraw(c, a, None, events_now[0], "AGUARDANDO")))
# depósitos pendentes de confirmação (10 a 12/out)
for k, (c, sym) in enumerate([(2, "BTC"), (4, "ETH"), (6, "SOL"), (9, "USDT"), (12, "BTC"), (12, "POL")]):
    if (c, SYMBOL_ID[sym]) in client_account:
        a = SYMBOL_ID[sym]
        events.append((datetime(2026, 10, 10 + k % 3, 10 + k, 5),
                       lambda c=c, a=a: deposit(c, a, 2000, events_now[0], "PENDENTE", rng.randint(0, max(CONF[a] - 1, 0)))))

# snapshots de prova de reservas
SNAPSHOT_DATES = [datetime(2026, 9, 30, 23, 59, 59), datetime(2026, 10, 11, 23, 59, 59)]
snapshots, leaves = [], []


def merkle_root(hashes):
    level = [bytes.fromhex(h) for h in hashes]
    while len(level) > 1:
        if len(level) % 2:
            level.append(level[-1])
        level = [sha256(level[i] + level[i + 1]).digest() for i in range(0, len(level), 2)]
    return level[0].hex()


def capture(when):
    second = when == SNAPSHOT_DATES[1]
    for a in range(1, 21):
        sid = len(snapshots) + 1
        owed = [(c, balance[acc]) for (c, aa), acc in sorted(client_account.items())
                if aa == a and balance[acc] > 0]
        total = sum(v for _, v in owed)
        symbol = ASSETS[a - 1][0]
        surplus = Decimal("-0.032") if second and symbol == "DOGE" else Decimal(rng.randint(2, 15)) / 1000
        on_chain = (custody(a) * (1 + surplus)).quantize(Q8)
        hashes = []
        for c, v in owed:
            h = sha256(f"{sid}|{clients[c - 1][1]}|{v:.8f}|{rng.getrandbits(64):016x}".encode()).hexdigest()
            leaves.append([len(leaves) + 1, sid, c, v, h])
            hashes.append(h)
        draft = second and symbol in ("DOGE", "ARB", "NEAR")
        snapshots.append([sid, a, ts(when), total, on_chain, merkle_root(hashes),
                          "RASCUNHO" if draft else "PUBLICADO"])


for when in SNAPSHOT_DATES:
    events.append((when, lambda w=when: capture(w)))

events_now = [None]
for when, action in sorted(events, key=lambda e: e[0]):
    events_now[0] = when
    action()

# --------------------------------------------------------------------------- SQL
lines = [
    "-- Carga simulada do Sledger (gerada por gerar-dados.py; não editar à mão).",
    "-- Execute após 01-ddl.sql e 02-melhorias.sql, em um schema recém-criado.",
    "USE `sys2`;",
    "",
]


def quoted(value):
    if value is None:
        return "NULL"
    if isinstance(value, (int, Decimal)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def emit(table, columns, rows):
    lines.append(f"INSERT INTO `{table}` ({', '.join('`' + c + '`' for c in columns)}) VALUES")
    lines.append(",\n".join("  (" + ", ".join(map(quoted, r)) + ")" for r in rows) + ";")
    lines.append("")


networks = [[i, n[0], n[1], n[2]] for i, n in enumerate(NETWORKS, start=1)] + [[21, *TESTNET]]
emit("RedeBlockchain", ["id_rede", "nome", "protocolo", "confirmacoes_padrao"], networks)
emit("Ativo", ["id_ativo", "simbolo", "nome", "casas_decimais", "id_rede", "preco_usd", "preco_atualizado_em"],
     [[i, s, n, d, i, Decimal(p), "2026-10-12 18:00:00"] for i, (s, n, d, p) in enumerate(ASSETS, start=1)])
emit("Cliente", ["id_cliente", "documento", "nome", "email", "status", "cadastrado_em"], clients)
emit("Conta", ["id_conta", "id_cliente", "id_ativo", "tipo", "status"], accounts)
emit("EnderecoCarteira", ["id_endereco", "id_conta", "endereco", "tipo"], addresses)
emit("Transacao", ["id_transacao", "ocorrida_em", "descricao", "referencia_externa", "status"], transactions)
emit("Lancamento", ["id_lancamento", "id_transacao", "id_conta", "tipo", "valor"], entries)
emit("Movimentacao", ["id_movimentacao", "id_cliente", "id_ativo", "id_conta", "id_transacao",
                      "valor", "solicitada_em", "status", "tipo_mov"], movements)
emit("Deposito", ["id_movimentacao", "tx_hash_rede", "confirmacoes_minimas", "confirmacoes_atuais",
                  "endereco_origem"], deposits)
emit("Saque", ["id_movimentacao", "endereco_destino", "status_aprovacao", "aprovado_em",
               "motivo_rejeicao", "tx_hash_rede"], withdrawals)
emit("ReservaSaldo", ["id_reserva", "id_saque", "id_conta", "valor", "criada_em", "liberada_em",
                      "motivo_liberacao"], reserves)
emit("SnapshotReserva", ["id_snapshot", "id_ativo", "capturado_em", "total_devido_clientes",
                         "total_on_chain", "merkle_root", "status"], snapshots)
emit("FolhaProva", ["id_folha", "id_snapshot", "id_cliente", "saldo_devido", "hash_folha"], leaves)

OUTPUT.write_text("\n".join(lines), encoding="utf-8")
counts = {"RedeBlockchain": len(networks), "Ativo": 20, "Cliente": len(clients), "Conta": len(accounts),
          "EnderecoCarteira": len(addresses), "Transacao": len(transactions), "Lancamento": len(entries),
          "Movimentacao": len(movements), "Deposito": len(deposits), "Saque": len(withdrawals),
          "ReservaSaldo": len(reserves), "SnapshotReserva": len(snapshots), "FolhaProva": len(leaves)}
print(f"Gerado: {OUTPUT}")
for table, n in counts.items():
    print(f"  {table:<17} {n:>4}{'  <-- menos de 20!' if n < 20 else ''}")
