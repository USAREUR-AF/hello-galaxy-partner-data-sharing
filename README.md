# hello-galaxy: partner data sharing

**How to share data with a partner so they see ONLY what you released to them —
and how to address a topic as "rel them" (one partner) vs "rel all" (a whole
coalition) — shown, not told, on a running goat fabric.**

This is a repo in the **Hello Galaxy** series. Each Hello Galaxy is a small,
self-contained, runnable example of *best practice in one specific dimension we
work with* — the way "hello, world" is the smallest honest example of a
language. This one covers **partner data sharing**: the fabric is
deny-by-default with one writer per root, so a partner can't just "read
everything" — you *release* data to them by publishing it into a **release
lane**, and you address that lane at one partner or at a coalition.

It follows the shape of
[`hello-galaxy-zenoh-patterns`](https://github.com/usareur-af/hello-galaxy-zenoh-patterns):
a short, cold-readable runbook per pattern plus a single script that drives the
`goat` CLI against a **running fabric** (your goat CLI's active context by
default) and narrates what's happening. Nothing is faked; where a behaviour is a **deployment property**
rather than something a client controls, the docs say so plainly.

---

## The question this repo answers

You have data on the fabric. A partner — another organisation — needs
*some* of it, and must see *nothing else*. How?

The wrong mental model is "give the partner a read key to my stuff." The fabric
won't let you: every identity is granted `put` on its **own** root
(`<uuid>/**`) and *nothing else*, deny-by-default, and a partner identity is
partitioned so it reads only its own anchor plus the lanes it's a member of. A
partner literally **cannot** read your private roots — and that isolation is the
thing that makes sharing safe.

So you don't hand out read keys. You **release** data by publishing it into a
lane whose name says, structurally, "this was deliberately released":

```
release/<set>/<topic>...
```

The leading `release/` prefix is the marker. `<set>` is a **release set** — a
named group of partner orgs — and choosing the set is how you choose the
audience:

> **"rel them"** = a bilateral set only ONE partner reads (one-to-one).
> **"rel all"** = a broad set EVERY partner in it reads (one-to-many).
> A release set with one member ≡ per-partner release.

**Who writes, who reads** — don't invert this: the **producer** (you, sharing
*out*) is the one who **writes** the lane; the **partner** (the recipient) only
ever **reads** it. Two separate grants, two directions. A partner is never handed
write on a lane set up for it to receive — if a partner needs to send data *back*
(reciprocity), it acts as a producer for its *own* lane, with its own write grant.
See [`docs/partner-data-sharing.md`](docs/partner-data-sharing.md) §4.

Read [`docs/partner-data-sharing.md`](docs/partner-data-sharing.md) first — it's
the whole model in prose, with every claim marked built / standard / future.

---

## The patterns

| Pattern | One-line | Key shape | Audience |
|---|---|---|---|
| **[A — rel them](patterns/A-rel-them/)** | release to ONE named partner | `release/<bilateral-set>/<topic>` | exactly that one partner |
| **[B — rel all](patterns/B-rel-all/)** | release to a whole coalition | `release/coalition/<topic>` | every partner in the set |
| **[C — partner view](patterns/C-partner-view/)** | the partner's side: discover + isolation | *(read side)* | what *you* may receive; and the deny that protects everyone |
| **[D — not inside](patterns/D-not-inside/)** | what the partner had to be GIVEN to receive anything | *(no key at all)* | the contrast with an admitted-to-an-enclave arrangement |

A and B are the **same mechanism** — a publish under `release/<set>/…` — with a
different `<set>`. The teaching point is that the *only* thing that changes
between releasing to one partner and releasing to a coalition is the set's
**membership**, which is a registry edit — never a republish, a new key, a cert
change, a NetBird group, or an Ory claim. Pattern C flips to the partner's seat:
how you find out what's been shared *with* you, and the isolation guarantee (you
are denied every other org's private root) that makes the whole thing trustworthy.

Pick with [`docs/rel-them-vs-rel-all.md`](docs/rel-them-vs-rel-all.md).

Pattern D steps back from all three: A, B and C show how data is released and what the partner sees; D asks what the partner had to be **given** in order to receive it. In the arrangement this replaces — one shared enclave partners are admitted to — the answer is an account, a network and the services on it. Here it can be a certificate and nothing else, because *what you can reach* and *what you can read* are separate grants. Read [`docs/enclave-vs-lanes.md`](docs/enclave-vs-lanes.md) for the comparison on its own.

---

## Run it

```bash
git clone https://github.com/usareur-af/hello-galaxy-partner-data-sharing
cd hello-galaxy-partner-data-sharing

# confirm goat can see a fabric (a context named my-goatnet shown):
goat --context my-goatnet health    # should print a per-class health table

bin/hello-zenoh A-rel-them           # run a pattern, narrated (active context by default)
bin/hello-zenoh all                  # run all four in order
bin/hello-zenoh list                 # list the patterns
```

Each pattern is a folder with a `README.md` (read it cold) and a `run.sh` (the
driver). `bin/hello-zenoh <pattern>` just runs the folder's `run.sh` with the
env you chose (the active context by default; `--env <context>` picks another).

**What needs a goatnet.** Every pattern runs against a goatnet: the drivers
derive your anchor from your context's certificate and ask the goatnet's ACL
for decisions. If you don't have a goatnet, the goatlite tutorial stands one up
on a single box: [`docs/tutorials/00-goatlite.md`](https://github.com/usareur-af/goatcore/blob/main/docs/tutorials/00-goatlite.md)
in goatcore. Landing a `release/` write, and seeing a partner receive it,
additionally needs an operator on that goatnet to add the two grants below. The
docs and runbooks read without one.

The demos derive **your own** write anchor from your cert at runtime and show
you the `release/<set>/…` key you *would* publish. **A real release publish is
deployment-gated** (see Honesty notes) — an arbitrary caller is not a granted
release-writer, so the demos show the shape, trace the ACL decision for your
identity, and explain the two grants that make it work rather than faking a
success.

---

## Prerequisites

- The `goat` CLI on your `PATH`, with a configured context for the env
  (`goat context use <context>`, or `goat init`). Verify with
  `goat --context <context> health`.
- `openssl` (the drivers read your cert CN to derive your anchor).
- An identity on the fabric (a slot/org cert). To *actually* land a release
  publish you additionally need a **release-writer grant** for the set — which
  is an operator/registry act, not something a demo can self-serve (that gate is
  the point; see below).

---

## Honesty notes

**Nothing is faked.** Two things in this repo are **deployment properties**, not
things a client controls, and the demos state them plainly instead of
pretending otherwise:

- **The demo user is (almost certainly) not a granted release-writer.** Sharing
  into `release/<set>/…` requires a write grant (`zenoh_release_writers`, the
  `release-w-<anchor>` ingress rule) that an operator adds in the registry. If
  you run these demos as an ordinary identity, your publish into a release lane
  is **denied** — so the drivers show you the key *shape*, the marker, the
  discovery surface, and the two grants involved, and they **do not claim your
  publish landed**. How to verify enforcement on your goatnet is below.
- **The ACL does not reload live.** A newly-added release-writer or
  partner-read grant takes effect only when the router next **restarts**.
  Sharing is deliberate and deploy-gated, not an instant runtime toggle.
- **Denial is silent.** A denied `put` returns as if it worked; the
  sample simply never routes. So you verify a grant by **presence** — the sample
  actually arriving at a subscriber — and an un-granted key by **absence**, never
  by expecting an error.

**What is built.** Two registry-driven ACL carves sit *additively* on top of
deny-by-default and never touch a single-owner `<uuid>/**` root:

- **READ** — `zenoh_partner_read_lanes` maps a partner anchor to the sets it may
  read (the partner read partition).
- **WRITE** — `zenoh_release_writers` maps a producer anchor to the sets it may
  publish into (the release-lane write grant).

With both grants in place, the producer→partner loop is checked as a six-point
delivery matrix: a producer's `release/coalition/demo` **reaches** the
partitioned partner; the partner reading the producer's own root gets **0
samples**; a non-partner flat reader is unchanged; the partner writing the lane
it can only read is **denied**; the producer writing an ungranted set is
**denied**; the partner writing its own root is **allowed**. Run it on your
goatnet by presence and absence at a subscriber, as
[`docs/partner-data-sharing.md`](docs/partner-data-sharing.md) §4 describes.

**One [future] piece.** Everything above is *same-fabric*: partners homed on the
one fabric, read-partitioned, reading the lanes they're granted. The
**cross-fabric release gateway** — forwarding `release/<set>/…` onward to a
partner running their *own* goatnet — is **designed, not built**.
It's called out as `[future]` wherever it appears.

Full model + trade-offs: [`docs/partner-data-sharing.md`](docs/partner-data-sharing.md).
When to pick a bilateral vs a broad set: [`docs/rel-them-vs-rel-all.md`](docs/rel-them-vs-rel-all.md).

---

## License

Apache 2.0 — see [LICENSE](LICENSE).
