const { RpcClient } = require("./rpc");
const indexer = require("./indexer");

const DECIMALS = 18;

function isEthAddress(value) {
  return typeof value === "string" && /^0x[0-9a-fA-F]{40}$/.test(value);
}

// Problem 2: an empty, undefined, or non-ok RPC result must never look like
// a success. Only a confirmed `{ ok: true, ... }` passes through as-is.
function unwrapResult(result) {
  if (!result || result.ok !== true) {
    return {
      ok: false,
      error:
        (result && result.error) || "RPC call failed or returned no result",
    };
  }
  return result;
}

class VaultClient {
  constructor(rpc, vault = "0xvault", token = "0xtoken") {
    this.rpc = rpc;
    this.vault = vault;
    this.token = token;
  }

  addWallet(caller, wallet, allowance, label = "") {
    // Problem 3: check the address before sending the tx.
    if (!isEthAddress(wallet)) {
      return { ok: false, error: "invalid wallet address" };
    }
    if (!(allowance > 0)) {
      return { ok: false, error: "invalid allowance" };
    }

    // MAKING SURE THAT TRANSACTION IS SUCCESFUL BEFORE ADDING IT TO INDEX
    try {
      const result = unwrapResult(
        this.rpc.call("addWallet", [
          wallet,
          allowance,
          label,
          { from: caller },
        ]),
      );
      if (!result.ok) {
        return result;
      }
      indexer.remaining[String(wallet).toLowerCase()] = allowance;
      indexer.listed[String(wallet).toLowerCase()] = true;
      return result;
    } catch (error) {
      return { ok: false, error: String(error) };
    }
  }

  approve(amount) {
    try {
      return unwrapResult(this.rpc.call("approve", [this.vault, amount]));
    } catch (error) {
      return { ok: false, error: String(error) };
    }
  }

  deposit(amount) {
    try {
      const approved = this.approve(amount);
      if (!approved.ok) {
        return approved;
      }
      const result = unwrapResult(this.rpc.call("deposit", [amount]));
      if (!result.ok) {
        return result;
      }
      // Problem 2: the vault token balance is read from the chain
      // (see vaultTokenBalance) and is never bumped by client arithmetic.
      return result;
    } catch (error) {
      return { ok: false, error: String(error) };
    }
  }

  withdraw(amount) {
    try {
      return unwrapResult(this.rpc.call("withdraw", [amount]));
    } catch (error) {
      return { ok: false, error: String(error) };
    }
  }

  // Problem 2: the client no longer keeps its own subtracted balance.
  // This asks the chain for the vault's token balance and returns null
  // (like remainingOf) when the RPC result is not a confirmed success.
  vaultTokenBalance() {
    try {
      const result = this.rpc.call("tokenBalanceOf", [this.vault]);
      if (result && result.ok === true && typeof result.balance === "number") {
        return result.balance;
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  allowance(wallet) {
    return indexer.remainingOf(wallet);
  }

  ingestLogs(logs) {
    indexer.ingestLogs(logs);
    return {
      remaining: indexer.remaining,
      vaultTokenBalance: this.vaultTokenBalance(),
    };
  }
}

module.exports = { VaultClient, RpcClient, isEthAddress, DECIMALS };
