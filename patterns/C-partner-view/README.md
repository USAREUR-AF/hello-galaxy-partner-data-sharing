# Pattern C — the partner's view (discover + isolation)

**Now sit in the partner's seat.** Two questions the partner asks, and this
pattern answers both: *what has been shared with me?* and *what stops me — and
everyone else — from reading things that weren't?*

```
release/<set>/**     ← what you (the partner) may READ: only the sets you're in
<any-other-uuid>/**  ← DENIED: every other org's private root, always
```

## (a) Discover what's shared with you

A partner doesn't guess. There are two read-side questions:

- **Which release sets am I in / what may I receive?** Your read partition is
  `zenoh_partner_read_lanes` — the sets your anchor is a member of. Those are the
  `release/<set>/**` lanes you can subscribe. **[built]**
- **Who is a topic's audience?** `goat access who <topic>` is the reverse query:
  who may write a topic, who may read it, and which partners receive it if it's
  released. It is **operator-gated** — an ordinary partner identity may not have
  it, and the demo says so rather than faking output.

`goat access explain <you> release/<set>/<topic>` traces the decision for a
specific key: for a set you're in, it resolves to **allow (read)**; for a set
you're not in, **deny**. That's how you confirm, honestly, what you can receive.

## (b) The isolation that makes sharing safe

This is the half people forget. Sharing is only trustworthy because a partner
**cannot** read anything that wasn't released — and neither can anyone else read
*your* private data by default:

- Every identity is granted `put` on its **own** root and nothing else,
  deny-by-default.
- A partner reading **any other org's** `<uuid>/**` root gets **denied** — the
  read partition holds strictly to the partner's own anchor plus its granted
  release lanes. **[built]** — the partner read partition.

So "release" is opt-in exposure on top of a floor of total isolation. A partner
sees its own anchor, the release lanes it's a member of, and **nothing else** —
checked by the six-point delivery matrix in
[`docs/partner-data-sharing.md`](../../docs/partner-data-sharing.md) §4, where the
partner reading the producer's own root must get **0 samples** while the same
partner receives the producer's `release/coalition/demo`.

## What the demo shows

`run.sh` runs from *your* seat as a partner:

- tries `goat access who <a-release-topic>` to discover an audience — and, if
  that surface is operator-gated for you, says so and falls back to
  `goat access explain`;
- uses `goat access explain <you> release/<set>/…` to show a lane you *may*
  read;
- uses `goat access explain <you> <some-other-uuid>/state` to show the **deny**
  on another org's private root — the isolation guarantee, at the ACL layer.

Because **denial is silent at publish time**, the trustworthy way to see
isolation is exactly this: a decision trace (`explain`) or absence at a
subscriber — never an error you wait for. **The ACL doesn't reload live
**, so what `explain` shows is the enforced state as of the last router
restart.

## Run it

```bash
bin/hello-zenoh C-partner-view      # active goat context by default
```
