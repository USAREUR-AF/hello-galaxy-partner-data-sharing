#!/usr/bin/env bash
# Pattern D — the partner is not INSIDE anything.
#
# A, B and C answer "how do I release data, and what does the partner see."
# This one answers the question underneath: what did the partner have to be
# GIVEN in order to receive it? In the arrangement this replaces — one
# shared enclave that partners are admitted to — the answer is "an
# account, a network and the reach that comes with them." Here the answer can
# be "a certificate," and nothing else.
#
# Runs from YOUR seat, read-only. Nothing is published, nothing is granted.
#
#   Override the foreign root probed:
#     HZ_OTHER_ROOT=<32hex>/state ./run.sh
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/lib/hello-zenoh.sh"
hz_parse_env "$@"; set -- ${HZ_ARGS[@]+"${HZ_ARGS[@]}"}

hz_banner "Pattern D — data without an enclave" \
          "What a partner had to be given in order to receive anything."

hz_preflight || exit 1
ANCHOR="$(hz_anchor)"
OTHER_ROOT="${HZ_OTHER_ROOT:-ffffffffffffffffffffffffffffffff/state}"

hz_step "1. The two models, stated before anything runs"
hz_say  "ENCLAVE   admission is the decision. It is binary and it is to an"
hz_say  "          ENVIRONMENT: a login, a network, the services on it. Sharing"
hz_say  "          one feed means sharing all of that. Withholding means standing"
hz_say  "          up a second enclave, so the pressure is to keep good data out"
hz_say  "          of the shared one."
hz_say  ""
hz_say  "LANES     release is the decision, and it is about DATA. The partner's"
hz_say  "          reach and the partner's data are separate grants. Withholding"
hz_say  "          is the default state and costs nothing."
hz_note "The rest of this run is evidence for the second column, from the goatnet you are using."

hz_step "2. What can this identity read, and WHY?"
hz_cmd  "goat access who $ANCHOR"
WHO="$(hz_goat access who "$ANCHOR" 2>&1)"; RC=$?
printf '%s\n' "$WHO"
if [ "$RC" -ne 0 ]; then
  hz_note "Operator-gated from this seat — that refusal is itself the point of"
  hz_note "step 4: an ordinary participant cannot enumerate the fabric."
else
  hz_say "Every line carries its reason. In an enclave there is no such query,"
  hz_say "because the answer is 'they are inside' and it is the same for everyone."
fi

hz_step "3. A foreign root, traced rather than guessed"
hz_cmd  "goat access why $ANCHOR $OTHER_ROOT"
WHY="$(hz_goat access why "$ANCHOR" "$OTHER_ROOT" 2>&1)"; RC=$?
printf '%s\n' "$WHY"
if [ "$RC" -ne 0 ]; then
  hz_note "Also operator-gated. The decision still holds; you just cannot ask it"
  hz_note "from here. Pattern C shows the same isolation from the receiving side."
else
  hz_say "The trace walks mesh -> identity -> Zenoh ACL -> release. A denial names"
  hz_say "the layer that produced it. Denial on this fabric is SILENT at publish"
  hz_say "and subscribe time, so a trace is the only honest way to see it."
fi

hz_step "4. The part that has no enclave equivalent"
hz_say  "A partner needs exactly two things to exchange data here:"
hz_say  "  * a fabric identity — an mTLS certificate whose CN is its own anchor"
hz_say  "  * reachability to the router endpoint"
hz_say  ""
hz_say  "It does NOT need a web identity. With no account in the identity"
hz_say  "provider, every human-facing service refuses it: the portal, the"
hz_say  "dashboards, the admin console, the inspection surfaces. There is no"
hz_say  "session to hold and nothing to log in to."
hz_note "So 'partner' is not a tier of membership. It is a certificate plus a"
hz_note "list of lanes, and the list can be empty."
hz_say  ""
hz_say  "Whether a given goatnet chooses that is a DEPLOYMENT decision, not a"
hz_say  "property of the fabric. A sandbox goatnet for co-development may do the"
hz_say  "opposite — onboard partners at developer tier, which carries a web"
hz_say  "login, because it wants people in the surfaces. Read the honesty note"
hz_say  "before quoting this pattern at anyone."

hz_step "5. What follows, and what does not"
hz_say  "FOLLOWS      revoking data access is ending a grant, not removing an"
hz_say  "             account; two partners on one fabric can hold different data;"
hz_say  "             the home population is unaffected when a partner is carved."
hz_say  "DOES NOT     this is not an air gap, and not encryption. A partner IS on"
hz_say  "             the network to the extent it reaches the router. What is"
hz_say  "             bounded is what it may read once there."
hz_note "For the encryption dimension see hello-galaxy-grant-encryption."

printf '\n'
hz_say "Docs: ../../docs/enclave-vs-lanes.md"
