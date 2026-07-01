// Presence / "listening" (spec §15, v0.4) — derived from existing poll/subscription activity;
// online/offline/unknown by the freshness window.

import test from "node:test";
import assert from "node:assert/strict";
import { Hub } from "../src/hub.js";

const KEY = "hub-presence-key-0123456789abcdef0123456789abcdef";
const T0 = 1_782_056_000_000;
const AGENT = "deploybot/dev-team";

function newHub(now: { t: number }): Hub {
  return new Hub({ signingKey: KEY, now: () => now.t, presenceFreshnessSeconds: 90 });
}

test("unknown before any activity — never-seen is distinct from offline (§15.2)", () => {
  const now = { t: T0 };
  const hub = newHub(now);
  const p = hub.getPresence(AGENT);
  assert.equal(p.state, "unknown");
  assert.equal(p.last_seen, undefined);
  assert.equal(p.freshness_seconds, 90);
});

test("online after a poll within the freshness window (derived, §15.1)", () => {
  const now = { t: T0 };
  const hub = newHub(now);
  hub.drainInbox(AGENT); // a mailbox drain is presence activity
  const p = hub.getPresence(AGENT);
  assert.equal(p.state, "online");
  assert.equal(p.last_seen, new Date(T0).toISOString());
});

test("a message GET also refreshes presence (§15.1)", () => {
  const now = { t: T0 };
  const hub = newHub(now);
  hub.get("msg_does_not_exist", AGENT); // an authenticated poll counts even for an unknown id
  assert.equal(hub.getPresence(AGENT).state, "online");
});

test("offline once last_seen falls outside the window (§15.2)", () => {
  const now = { t: T0 };
  const hub = newHub(now);
  hub.drainInbox(AGENT);
  assert.equal(hub.getPresence(AGENT).state, "online");
  now.t += 91_000; // past the 90s window
  const p = hub.getPresence(AGENT);
  assert.equal(p.state, "offline");
  assert.equal(p.last_seen, new Date(T0).toISOString(), "last_seen is retained; only the state ages out");
});

test("presence is per-agent — one agent's activity does not make another online", () => {
  const now = { t: T0 };
  const hub = newHub(now);
  hub.drainInbox(AGENT);
  assert.equal(hub.getPresence(AGENT).state, "online");
  assert.equal(hub.getPresence("other/agent").state, "unknown");
});
