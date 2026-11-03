# Pattern A — "rel them" (bilateral release)

**Share a stream with ONE named partner.** You publish into a **release lane**
whose set has a single member — the partner you mean — and no one else on the
fabric can read it.

```
release/<bilateral-set>/<topic>...     ← a lane read by exactly one partner
  │        │             └ your topic tree, published as normal
  │        └ a release SET whose only member is that one partner org
  └ the structural marker: "deliberately released, not a private root"
```

## The mental model

The fabric is deny-by-default. Your data lives under your own root
(`<your-uuid>/**`) and a partner is **denied** every root but its own. So you
don't grant the partner a key into your space — you **release** a copy of the
stream into a lane, and you make the lane's audience *exactly one partner* by
using a **bilateral set**: a release set with one member.

"rel them" is the one-to-one case. If tomorrow a second partner should also see
it, you don't touch the key or republish — you add that partner to the set's
membership in the registry (that's Pattern B's territory). The key
`release/<bilateral-set>/<topic>` is stable; the audience is a registry fact.

## The two grants that make it work

A release lane needs **two** additive grants, both sitting on top of
deny-by-default and neither touching any private root:

1. **WRITE — you may publish into the set.** `zenoh_release_writers` maps your
   producer anchor to the sets you may publish into (the `release-w-<anchor>`
   ingress rule on `release/<set>/**`). **[built]** — the release-lane write
   grant.
2. **READ — the partner may read the set.** `zenoh_partner_read_lanes` maps the
   partner's anchor to the sets it may read. **[built]** — the partner read
   partition.

Both are **registry-driven** and **default-off**. Adding you as a writer, and
adding the partner as a reader, are operator/registry edits — not something a
demo self-serves. And **the ACL does not reload live**: a new grant
takes effect only when the router next **restarts**.

## What the demo shows

`run.sh` derives *your* anchor, builds the `release/<bilateral-set>/<topic>` key
you *would* publish, and:

- shows the key and points out the `release/` marker and the set segment;
- uses `goat access explain <you> <key>` (when available) to **trace the actual
  ACL decision** for your identity — honest either way: if you aren't a granted
  release-writer, it shows the **deny**, and the driver does **not** pretend the
  publish landed;
- explains the two grants + the restart-to-enforce, and points at the six-point
  delivery matrix in [`docs/partner-data-sharing.md`](../../docs/partner-data-sharing.md) §4
  that checks enforcement end to end.

Because **denial is silent**, the demo never reads success from a
`put` return code — it verifies the *shape* it can prove locally (the key is
under `release/`, carries the set, and is **not** a private root) and leaves the
delivery check to that matrix, run on a goatnet where both grants are in place.

## Run it

```bash
bin/hello-zenoh A-rel-them          # active goat context by default
```
