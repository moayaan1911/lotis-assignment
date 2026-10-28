# Wallet Watchlist problems

These are issues ops hit across the token, registry, vault, indexer, and handlers. On this branch the matching spots are tagged in the source. Search for `PROBLEM 1`, `PROBLEM 2`, or `PROBLEM 3`.

Work through them in the code, and make commits with clear messages as you go.

## 1. Anyone can mint, list wallets, and rewrite remaining (`PROBLEM 1`)

What we need: admin is `msg.sender` of the deployer, not `tx.origin`. Only that admin can add a wallet. Reject the zero address and a zero allowance. There is no unauthenticated mint or batch write. Only the vault may change remaining. The handlers and client must not treat a supplied `caller` as admin.

What happens now:
- Token constructor and vault/registry constructors take admin from `tx.origin`. `mint` is open. `seed` writes remaining with no auth.
- `addWallet` does not check the caller. Empty wallets and a zero allowance still emit `Added`. `setVault` and `consume` are open.
- Handlers default `caller` to `"ops"`. The client writes the cache before the tx and does not check the on-chain admin.

Where to look:
- `contracts/WatchlistToken.sol` - constructor, `mint`
- `contracts/WatchlistRegistry.sol` - constructor, `setVault`, `addWallet`, `seed`, `consume`
- `contracts/WatchlistVault.sol` - constructor
- `scripts/vault-client.js` - `addWallet`
- `scripts/handlers.js` - `"add"`
- `data/events.json` - `e1`, `e4`

## 2. Deposits never land and withdraws ignore remaining (`PROBLEM 2`)

What we need: deposit pulls tokens into the vault (`transferFrom`) with amount `> 0`, and cuts the token allowance. Withdraw is signed by the listed wallet, not paid to an arbitrary `to`. It fails if the wallet was never listed or the amount is above remaining. A successful pull cuts vault tokens and remaining (subtract, do not overwrite). Remaining `0` after pulls must not look the same as "never listed". `approve` must actually approve. Failed transfers must not look like success.

What happens now:
- `deposit` only bumps `recordedDeposits`. `transferFrom` does not spend allowance. `approve` does not emit and the client skips approve.
- `withdraw` pays any `to`. Remaining is not consumed. `listed` is just `remaining > 0`.
- The client and handlers still subtract their own balance and swallow RPC errors. ETH sent to `receive` is unaccounted.

Where to look:
- `contracts/WatchlistToken.sol` - `approve`, `transfer`, `transferFrom`
- `contracts/WatchlistRegistry.sol` - `listed`, `consume`
- `contracts/WatchlistVault.sol` - `deposit`, `receive`, `withdraw`
- `scripts/vault-client.js` - `approve`, `deposit`, `withdraw`
- `scripts/handlers.js` - `"deposit"`, `"withdraw"`

## 3. The indexer does not follow the chain (`PROBLEM 3`)

What we need: a wallet that is not on the list must not look like remaining `0`. The same `event_id` must not be applied twice. After a pull, cached remaining must drop. Addresses should be checked before a tx. Token decimals in the client must match the token.

What happens now:
- `remainingOf` returns `0` when the wallet was never ingested. Pull events are skipped. `e3` is in the sample batch twice.
- `isEthAddress` only checks the `0x` prefix. Client decimals are `6` while the token is `18`.

Where to look:
- `scripts/indexer.js` - `remainingOf`, `ingestLogs`, `LOADED_IDS`
- `scripts/vault-client.js` - `allowance`, `isEthAddress`, `DECIMALS`
- `data/events.json` - duplicate `e3`, empty wallet add
