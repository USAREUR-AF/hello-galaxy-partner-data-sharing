# Partner data sharing: release lanes, and why you don't just hand out a read key

Every other way of thinking about this starts wrong. The instinct is "the
partner needs my data, so I'll give the partner read access to my keys." The
fabric won't let you, and that refusal is the whole design. This doc walks the
model from the default up: one writer per root → why a partner can't read
everything → **release lanes** → **rel-them vs rel-all** → the two registry
carves that enforce it → the trade-offs → the one forward piece that isn't built.

> Each claim is marked **[built]** (the mechanism is real), **[standard]** (general practice), or **[future]** (a forward idea, *not*
> built). Read the markers literally.

---

## 1. The default: one writer per root, deny-by-default

**[built]** The router grants each identity `put/delete` on its **own** root
(`<uuid>/**`, plus its `volatile/` mirror) and *nothing else*. Every other write
is denied, and — critically for reads — a partner identity is **partitioned**:
it is admitted to read only its own anchor and the lanes it has been added to.
Everything else is denied by default. There is no ambient "read the fabric"
permission to grant.

That means the naive share is impossible by construction. You cannot "add the
partner as a reader of `<your-uuid>/**`" — the ACL is a pre-cut, identity-bound
partition, not an access-control list you append principals to per key. And you
would not want to: your root carries everything you produce, most of which the
partner must never see.

## 2. So you release, you don't expose

**[built]** To share, you **publish a copy of the stream into a release lane** —
a key in a reserved namespace whose leading segment announces its purpose:

```
release/<set>/<topic>...
```

- **`release/`** is the structural marker. It is not a private root; it exists
  precisely so that a raw-key reader, an auditor, and the ACL all agree "this was
  deliberately released." Your private roots stay untouched — releasing never
  opens `<your-uuid>/**` to anyone. It creates a *separate* place whose whole
  meaning is "shared."
- **`<set>`** is a **release set** — a named group of partner orgs. Choosing the
  set is choosing the audience (§3).
- **`<topic>...`** is your ordinary topic tree, shaped however your data wants
  (see the `hello-galaxy-zenoh-patterns` repo for key-shape guidance).

The producer publishes *once*, into the lane. Who receives it is not encoded in
the key and not decided at publish time — it's a property of the set's
membership, resolved off the key from the registry. That indirection is what
lets you widen or narrow an audience without touching a single published byte.

## 3. rel-them vs rel-all: the audience is the set

**[standard]** There are two flavours of release set, and they are the core of
this whole subject:

- **"rel them"** — a **bilateral** set with a single partner member. A publish
  into it reaches exactly one partner. One-to-one.
- **"rel all"** — a **broad** set (e.g. the `coalition` coalition). A publish into it
  reaches every partner in the set. One-to-many.

A bilateral set with one member **≡** per-partner release — there's no separate
"per-partner" mechanism, it's just a set of size one. And the two flavours are
**the same publish**; only `<set>` differs. You move between them by editing set
**membership** in the registry — adding or removing partner orgs — never by
changing the key, republishing, minting a new cert, adding a NetBird group, or
setting an Ory claim. (Decision guidance: [`rel-them-vs-rel-all.md`](rel-them-vs-rel-all.md).)

## 4. The two registry carves that enforce it

**[built]** Release is enforced by **two** additive ACL carves, both
registry-driven, both default-off, both sitting on top of deny-by-default, and
**neither ever touching a single-owner `<uuid>/**` root** (roots stay
inviolable):

| Carve | Registry key | Maps | Grant |
|---|---|---|---|
| **READ** — partner read partition | `zenoh_partner_read_lanes` | partner anchor → sets it may **read** | admits the partner to `release/<set>/**` |
| **WRITE** — release-lane write grant | `zenoh_release_writers` | producer anchor → sets it may **publish into** | `release-w-<anchor>` ingress rule on `release/<set>/**` |

Two grants, two directions. To share a stream you need **both**: a WRITE grant
so *you* may publish into the set, and a READ grant so the *partner* may receive
it. They are independent — a partner granted READ on a set it can only receive
cannot write it, and a producer granted WRITE cannot thereby read a partner's
root. Point 4 of the delivery matrix below checks that separation.

### "producer" and "partner" are roles, not fixed identities — reciprocity

**[built]** Note the asymmetry carefully, because it is easy to invert: the one
who **writes** a release lane is the **producer** (the side *doing the
releasing*); the **partner** only ever **reads** it. A partner is never handed
write on a lane that was set up for it to *receive* — point 4 above proves the
partner is denied write on the very lane it reads (point 4 of the matrix
below), and that denial is what keeps
"who published this?" answerable.

So if a partner wants to send data **back to you** (reciprocity — a standard
expectation of any real sharing relationship), the partner is not "writing your
rel-them lane." It is acting as a **producer for its own lane**: it needs its
*own* WRITE grant (`zenoh_release_writers`) for a set *you* are a read-member of.
The mechanism is identical, just with the roles swapped — two independent grants
in each direction. There is no path by which being a read-recipient of a lane
silently confers write on it.

**[built]** The full producer→partner loop is checked as a six-point delivery
matrix. With both grants in place and the router restarted, run each on your
goatnet; all six must hold:

1. producer publishes `release/coalition/demo` → the partitioned partner **receives**
   it — shared data reaches the partner;
2. the partner subscribes the producer's own private root → **0 samples** —
   read isolation holds;
3. a non-partner flat reader → sees both — unchanged;
4. the partner writes the lane it can only read → **denied** — read grant ≠
   write grant;
5. the producer writes an ungranted set → **denied** — grants are per-set
   scoped;
6. the partner writes its own root → **allowed** — own-anchor write intact.

## 5. Two fabric properties you must design around

**[built]** These are **deployment properties**, not things a client controls,
and honesty about them is the house rule of this series:

- **The ACL does not reload live.** A newly-added release-writer or
  partner-read grant takes effect only when the router next **restarts**.
  Sharing is a deliberate, deploy-gated act, not an instant runtime toggle. Plan
  a grant change like a deploy, not like flipping a flag.
- **Denial is silent.** A denied `put` returns to the publisher as if it
  worked; the sample simply never routes. So you never confirm a grant by the
  absence of an error. You confirm it by **presence** — the sample actually
  arriving at a subscriber on the lane — and you confirm an un-granted key by
  **absence**. `goat access explain` gives you the decision trace directly, which
  is the cleanest honest check.

## 6. The trade-offs you're accepting

**[standard]**

- **Audience creep on broad sets.** A `rel all` set is convenient and one publish
  serves everyone — but every member reads *everything* in it. If two partners
  should see different slices, that is two lanes, not one broad set with a wide
  membership. Widening membership is cheap; that's exactly why it needs
  discipline.
- **Release is a copy, not a window.** You are publishing into the lane
  deliberately. Data that never enters a `release/<set>/…` key is never shared —
  which is the safe default, but it means sharing is an explicit producer act per
  stream, not a blanket grant.
- **Membership lives in the registry, off the key.** That's the feature (rename,
  reorg, and re-scope without rekeying) and the operational cost (the audience of
  a lane is a registry lookup, not something you can read off the wire). Discovery
  surfaces — `goat access who`, `goat access explain` — exist to answer "who's in
  this set / what may I receive," and `who` is operator-gated.

## 7. The one forward piece: the cross-fabric release gateway

**[future]** Everything above is **same-fabric**: partners homed on the *one*
fabric, read-partitioned, reading the release lanes they're granted. That is the
built thing.

The **cross-fabric release gateway** — a component that forwards `release/<set>/…`
paths *onward* to a partner running their **own** goatnet, so a
partner on a separate fabric receives your releases without being homed on yours
— is **designed, not built**. When you see "the partner has their own goatnet and
still gets our releases," that is the future gateway, not today's mechanism.
Don't build against it yet.

---

## The one-paragraph version

The fabric is deny-by-default with **one writer per root**, and a partner is
partitioned to read only its own anchor plus the lanes it's in — so you can't
hand out a read key, and you don't want to. To share, you **release**: publish a
copy of the stream into `release/<set>/<topic>`, where the leading `release/` is
the "deliberately shared" marker and `<set>` is a release set whose **membership**
is the audience — a **bilateral** set for one partner (*rel them*) or a **broad**
set for a coalition (*rel all*), the same publish either way. Two registry carves
enforce it, both built: a partner-**read** partition and a
release-lane **write** grant, additive on deny-by-default, roots
inviolable. Design around the two fabric truths — the ACL doesn't reload live
and denial is silent — and reserve the cross-fabric gateway for
when it's actually built (**[future]**).
