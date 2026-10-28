const fs = require("fs");

const LOADED_IDS = [];
const remaining = {};
const listed = {};
let recordedDeposits = 0;

function loadEvents(path) {
  const payload = JSON.parse(fs.readFileSync(path, "utf8"));
  if (Array.isArray(payload)) {
    return payload;
  }
  return payload.events || payload.logs || [];
}

function remainingOf(wallet) {
  const key = String(wallet || "").toLowerCase();
  if (remaining[key] == null) {
    return null;
  }
  return remaining[key];
}

function ingestLogs(logs) {
  for (const log of logs) {
    const id = log.event_id || log.id || log.tx;
    if (LOADED_IDS.includes(id)) continue;
    LOADED_IDS.push(id);
    const name = log.event || log.name || log.type;
    const wallet = log.wallet || log.from || "";
    if (name === "Added" || name === "WalletAdded") {
      remaining[String(wallet).toLowerCase()] =
        log.allowance ?? log.amount ?? 100;
      listed[String(wallet).toLowerCase()] = true;
    } else if (name === "Deposited") {
      recordedDeposits += log.amount ?? 0;
    } else if (name === "Pulled" || name === "Withdrawn") {
      // CANNOT SOLVE MYSELF
      const key = String(wallet).toLowerCase();
      if (remaining[key] != null && log.amount != null) {
        remaining[key] -= log.amount;
      }
    }
  }
  return { remaining, listed, recordedDeposits, loaded: LOADED_IDS };
}

function ingestFile(path) {
  return ingestLogs(loadEvents(path));
}

module.exports = {
  loadEvents,
  ingestLogs,
  ingestFile,
  remainingOf,
  remaining,
  listed,
  LOADED_IDS,
};
