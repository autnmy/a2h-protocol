# a2h-skills

**Meta-skills that build A2H skills for your app.**

[A2H](https://a2hprotocol.org) is the Agent-to-Human Protocol — a vendor-neutral way for an agent to
reach a human and get a decision back (`notify` · `ask` · `task`). To use it from your own app, your
agents need a skill that knows *your* Hub's URL, auth, and conventions.

Rather than hand-write that three times, this plugin gives you three **builders** — meta-skills that
scaffold a custom, app-specific verb skill wired to your Hub:

| Builder | Generates | Your agents then… |
|---|---|---|
| `/a2h-skills:build-notify` | `<app>-notify` | send fire-and-forget notifications (digests, status, FYIs) |
| `/a2h-skills:build-ask` | `<app>-ask` | ask a human a decision; the signed answer routes back |
| `/a2h-skills:build-task` | `<app>-task` | ask a human to perform a manual action, then mark it done |

Each builder gathers your A2H config (Hub URL, auth, agent identity, callback strategy), writes a
ready-to-use skill into your repo, and smoke-tests it against your Hub.

## Install

```
/plugin marketplace add autnmy/a2h-protocol
/plugin install a2h-skills@a2h
```

Then, in your app's repo:

```
/a2h-skills:build-notify     # scaffold a notify skill for this app
/a2h-skills:build-ask        # scaffold an ask skill
/a2h-skills:build-task       # scaffold a task skill
```

(They also auto-trigger from intent, e.g. "add A2H notify to my app".)

## What you need first

An **A2H Hub** to point at — e.g. [OH HAI](https://a2hprotocol.org), or any conformant Hub — and a
bearer token for your agents. `notify` needs only the Hub URL + token; `ask`/`task` additionally need a
**callback** (a URL the Hub posts the signed answer to, or a pull endpoint) and a way for your agent run
to resume on that callback.

## License

Apache-2.0 · part of [autnmy/a2h-protocol](https://github.com/autnmy/a2h-protocol).
