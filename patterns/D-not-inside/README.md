# Pattern D — data without an enclave

**The partner is not *inside* anything.** Patterns A, B and C show how data is
released and what the partner sees. This one answers the question underneath:
**what did the partner have to be given in order to receive it at all?**

```
./run.sh                 # read-only; publishes nothing, grants nothing
```

## The contrast this exists for

The arrangement this replaces is **one shared enclave that partners are
admitted to**. It works, it is familiar, and two costs follow from its shape —
neither of which is a configuration mistake:

| | enclave | lanes |
|---|---|---|
| the decision | admit the partner to an **environment** | release **data** into a lane |
| what it grants | a login, a network, the services on it | membership of one release set |
| granularity | the enclave | the topic namespace |
| withholding | requires a **second enclave** | is the **default**; release is the act |
| the partner's service reach | every service in the enclave | can be **zero** |
| revocation | remove the account | end-date the grant |

The first row is the whole difference. An enclave fuses *what you can reach*
with *what you can read*, so sharing one feed means sharing an environment, and
keeping something back means running another environment to keep it in.

## What the run shows

**Steps 2 and 3** ask the goatnet: `goat access who` lists what an identity may
read **with the reason at each layer**, and `goat access why` traces one
decision across mesh → identity → Zenoh ACL → release. Both are operator-gated;
from an ordinary participant's seat they refuse, and *that refusal is itself
part of the point* — a participant cannot enumerate the fabric. Denial here is
**silent** at publish and subscribe time, so a decision trace is the only honest
way to see it. (Pattern C shows the same isolation from the receiving side.)

**Step 4** is the claim with no enclave equivalent. A partner needs exactly two
things: an mTLS certificate whose CN is its own anchor, and reachability to the
router. It needs **no web identity** — and with no account in the identity
provider, every human-facing service refuses it. There is no session to hold and
nothing to log into. "Partner" is not a tier of membership; it is a certificate
plus a list of lanes, and the list can be empty.

## Honesty notes

- **That posture is a deployment choice, not a property of the fabric.** A
  sandbox goatnet built for co-development may deliberately do the opposite:
  onboard its partners at developer tier, which carries a web login and
  therefore the web surfaces, because it wants people in them. Quote this
  pattern as *what the architecture permits*, not as what any particular goatnet
  currently does.
- **This is not an air gap and not encryption.** A partner is on the network to
  the extent that it reaches the router. What is bounded is what it may read
  once it is there. For the encryption dimension — restricting a stream to an
  audience with nothing in the read path able to decrypt — see
  `hello-galaxy-grant-encryption`.
- **The carve is opt-in per identity.** Onboarding somebody as a partner does
  not by itself partition them: affiliation, nation and coalition standing leave
  the access rules untouched. An operator adds the identity to the partitioned
  set, and until that happens the identity reads the fabric like any member.
  That is worth knowing before assuming a partner is carved.
- **`run.sh` shows the decisions, not the enforcement.** Enforcement is checked
  by the six-point delivery matrix in
  [`docs/partner-data-sharing.md`](../../docs/partner-data-sharing.md) §4, run on
  a goatnet with the grants in place.
