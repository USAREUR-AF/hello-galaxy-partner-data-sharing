# Enclave or lanes — the two ways to share with a partner

A short piece for someone deciding which shape they are building, or explaining
why this one looks unfamiliar.

## The enclave

Stand up an environment at a level everyone admitted can hold. Admit the
partner. They now have an account, a network, and whatever runs on it. Data
gets shared by being *placed in the environment*, which means being lowered to
its level.

It is the dominant model because it is simple to reason about and it matches how
people already work: you are in the room or you are not.

Its two costs are structural rather than accidental:

1. **Sharing anything means sharing the environment.** A partner who needs one
   feed receives the room and everything in it. The unit of trust is the room.
2. **Withholding is expensive.** Keeping something out of the partner's view
   means keeping it out of the room — so you run a second room, and the good
   data drifts into the one the partner is not in. The arrangement quietly
   selects against sharing the things worth sharing.

## The lanes

Keep two decisions apart that the enclave fuses:

- **What can this identity reach at all?** A certificate, and reachability to a
  router. Nothing else is implied — no account, no session, no surfaces.
- **What data may it read?** Membership of named release sets. Its own root,
  plus the lanes granted to it.

Sharing is then an act on **data**, not on an environment: a producer publishes
into `release/<set>/…`, and the set's membership decides the audience. Nothing
is lowered; nothing moves; nobody is admitted anywhere.

The properties that follow:

- **Withholding is free**, because it is the default. Deny-by-default means the
  unreleased case needs no action, no second environment, and no marking.
- **Two partners on one fabric can hold different data.** A bilateral lane is
  genuinely bilateral — the other partner is not in the set and does not see it.
- **Revocation is ending a grant**, not removing an account, so it is reversible
  and it does not disturb anything else the partner holds.
- **The home population is unaffected** when a partner is carved, which is what
  makes it usable at all. The enclave model's second room costs everyone.

## What the lanes model does not give you

- **It is not an air gap.** A partner is on the network to the degree it reaches
  the router.
- **It is not encryption.** Reads are bounded by access rules; if the threat is
  a reader you do not trust with the bytes, that is a different mechanism —
  see `hello-galaxy-grant-encryption`.
- **It is not automatic.** Partitioning an identity is a deliberate act. Being
  labelled a partner — by affiliation, nation, or coalition standing — changes
  no access rule by itself.

## Choosing

Use an enclave when the partner genuinely needs the environment: they are
working *in* your tooling, using your services, participating in the day-to-day.
A co-development sandbox is exactly this, which is why a sandbox goatnet
typically onboards its partners with logins rather than certificates alone.

Use lanes when the partner needs the **data** and nothing else — which is the
common case at a coalition boundary, and the case the enclave model serves
worst.

The two are not exclusive. The fabric does not care whether an identity also has
a web login; it is a separate grant, and that separability is the point.
