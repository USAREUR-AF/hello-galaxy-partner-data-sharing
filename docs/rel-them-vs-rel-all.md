# rel-them vs rel-all: a decision guide

You're about to release a stream. The only real choice is **which set** to
publish it into — a **bilateral** set (one partner: *rel them*) or a **broad**
set (a coalition: *rel all*). Same key shape, same publish, same two grants; the
set is the whole decision. This is the short guide to making it well.

> The mechanism is one thing (see [`partner-data-sharing.md`](partner-data-sharing.md)).
> This page is only about *choosing the set*.

## The one question

**Should every partner who could plausibly want this actually have it?**

- **Yes, coalition-wide** — a common operating picture, a shared advisory, a feed
  the whole coalition is meant to hold in common → **rel all** (broad set, e.g.
  `coalition`).
- **No, just this one** — a bilateral exchange, a partner-specific product, anything
  where different partners get different things → **rel them** (bilateral set).

If you're unsure, default to **rel them**. Narrow is reversible cheaply (add a
member later); wide is not (you can't un-see data, and pulling a member back
doesn't recall what they already received).

## A bilateral set is just a set of size one

There is no separate "per-partner" feature. **Per-partner release ≡ a release
set with one member.** So "rel them" and "rel all" are not two mechanisms — they
are the same release lane pointed at a set whose membership is one, or many. A
bilateral set that later needs a second reader simply *grows a member*.

## Widening or narrowing is a registry edit — nothing else

Moving between the two, or changing who's in a set, is **a membership change in
the registry**. It is emphatically **not**:

- a **republish** — the producer doesn't touch the data; the key
  `release/<set>/<topic>` is stable;
- a **new key or key change** — the audience isn't in the key, it's in the set;
- a **cert change** — identity certs are born-as, not re-stamped to grant a lane;
- a **NetBird group** — affiliation/audience is never a mesh group;
- an **Ory claim** — it's not an OIDC/identity-provider assertion either.

It's one thing: edit `zenoh_partner_read_lanes` (add/remove the partner anchor on
the set). Because **the ACL doesn't reload live**, the change takes
effect on the next router **restart** — so treat a membership edit as a deploy,
not a live toggle.

## Watch for audience creep

The failure mode of *rel all* is convenience. A broad set is one publish for
everyone, so it's tempting to widen membership rather than carve a second lane.
But **every member of a set reads everything in it.** If two partners should see
*different* slices, that's **two lanes**, not one broad set with a wide
membership. Keep a set's membership matched to what genuinely belongs to
*everyone* in it.

## Quick reference

| | rel them | rel all |
|---|---|---|
| set | bilateral (one member) | broad (a coalition) |
| example | `release/partner-alpha/…` | `release/coalition/…` |
| audience | exactly one partner | every member of the set |
| when | partner-specific / bilateral / different slices per partner | genuinely coalition-wide, shared in common |
| widen | add a member (registry) → becomes broader | already broad |
| default when unsure | **← start here** | only when it's truly for everyone |

Both are the same publish under `release/<set>/…`, enforced by the same two
built carves — partner **read** and release **write**. Pick the
set; the mechanism is identical.
