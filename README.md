# Wallet Watchlist

## Problems and solutions

**1. Anyone can mint, list wallets, and rewrite remaining** - Admin was taken from `tx.origin` and `mint`, `addWallet`, `seed`, `consume` were open to everyone. Fixed by making admin `msg.sender` with admin-only checks, rejecting zero address and zero allowance, and letting only the vault consume remaining.

**2. Deposits never land and withdraws ignore remaining** - `deposit` never pulled tokens, `withdraw` paid any address and overwrote remaining instead of subtracting it. Fixed by pulling tokens with `transferFrom` (spending allowance, amount > 0), withdrawing only to the listed wallet with listed/remaining checks, and subtracting remaining on every pull. On the client, the vault token balance is now read from the chain (`vaultTokenBalance()`), and an empty or failed RPC result comes back as an explicit failure.

**3. The indexer does not follow the chain** - Unknown wallets looked like remaining `0`, duplicate event ids were applied twice, pull events were skipped, and client decimals/address checks were wrong. Fixed by returning `null` for unknown wallets, deduping by `event_id`, subtracting on pulls, using 18 decimals, and validating full hex addresses - `addWallet` now checks the address before sending the tx.

## Note

I used AI to explain the existing code and draft the README, the code fixes are mine

## Commands


```bash
forge build
```

Or plain solc:

```bash
solc contracts/*.sol
```

Quick check of the client, handlers, and indexer:

```bash
node -e "const h=require('./scripts/handlers');const v=require('./scripts/vault-client');const i=require('./scripts/indexer');h.client.rpc={call:(m,p)=>({ok:true,balance:200})};h.handle('add',{caller:'ops',wallet:'0x9999999999999999999999999999999999999999',allowance:40});h.handle('deposit',{amount:50});console.log('balance:',h.client.vaultTokenBalance());console.log(i.ingestFile('data/events.json'));console.log('DECIMALS:',v.DECIMALS)"
```
