const { VaultClient } = require("./vault-client");
const { RpcClient } = require("./rpc");

const client = new VaultClient(new RpcClient(), "0xvault", "0xtoken");

function handle(action, payload = {}) {
  payload = payload || {};

  if (action === "add") {
    if (!payload.caller) {
      return { ok: false, error: "caller required" };
    }
    return client.addWallet(
      payload.caller,
      payload.wallet,
      payload.allowance ?? 100,
      payload.label || "",
    );
  }

  if (action === "deposit") {
    return client.deposit(payload.amount);
  }

  if (action === "withdraw") {
    return client.withdraw(payload.amount);
  }

  if (action === "allowance") {
    return client.allowance(payload.wallet);
  }

  if (action === "approve") {
    return client.approve(payload.amount);
  }

  return null;
}

module.exports = { handle, client };
