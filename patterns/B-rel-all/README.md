# Pattern B — "rel all" (broad release set)

**Share a stream with EVERY partner in a coalition set.** Same mechanism as
Pattern A — a publish under `release/<set>/…` — but the set is **broad**, so one
publish reaches *all* of its members at once.

```
release/coalition/<topic>...     ← a lane read by every partner in the coalition set
  │      │      └ your topic tree, published as normal
  │      └ a broad release SET — a whole coalition of partner orgs
  └ the same structural marker: "deliberately released, not a private root"
```

## A and B are the same mechanism — only the set differs

This is the teaching point of the repo. Releasing to one partner and releasing
to a coalition are **not two features**. They are one publish into
`release/<set>/…`, and the *only* thing that changes is `<set>`'s **membership**:

| | set | members | audience |
|---|---|---|---|
| **Pattern A — rel them** | `partner-alpha` (bilateral) | one partner | that one partner |
| **Pattern B — rel all** | `coalition` (broad) | the whole coalition | every member |

A bilateral set with one member ≡ per-partner release. Widen the audience by
**adding members to the set** — a registry edit — never by changing the key,
republishing, minting a new cert, adding a NetBird group, or setting an Ory
claim. The producer publishes once; who receives it is a registry fact resolved
off the key.

## The same two grants

Identical to Pattern A, because the mechanism is identical:

1. **WRITE** — you may publish into the set (`zenoh_release_writers`,
   `release-w-<anchor>`). **[built]**
2. **READ** — each partner in the set may read it (`zenoh_partner_read_lanes`).
   **[built]**

For a broad set, the READ grant is simply held by *many* partner anchors instead
of one. Both grants remain registry-driven, default-off, additive on
deny-by-default, and never touch a private `<uuid>/**` root. **The ACL does not
reload live** — a partner added to the set starts receiving only after
the next router restart.

## Choosing broad vs bilateral

Reach for a broad set (`coalition`) when the data is genuinely coalition-wide and you
*want* every member to have it — a common operating picture, a shared advisory
feed. Reach for a bilateral set (Pattern A) when only one partner should see it,
or when different partners get different things. The decision guide is
[`docs/rel-them-vs-rel-all.md`](../../docs/rel-them-vs-rel-all.md).

The risk to weigh is **audience creep**: a broad set is convenient, but every
member reads everything in it. If two partners should see *different* slices,
that's two lanes, not one broad set with a wide membership.

## What the demo shows

`run.sh` mirrors Pattern A against the broad `coalition` set: it derives your anchor,
builds `release/coalition/<topic>`, traces the ACL decision for your identity with
`goat access explain` (honest either way), and — because sharing is
deployment-gated and **denial is silent** — shows the shape and the
grants and points at the delivery matrix rather than faking a landed publish. The contrast it
draws is the audience: *one publish, many partners.*

## Run it

```bash
bin/hello-zenoh B-rel-all           # active goat context by default
```
