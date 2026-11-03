#!/usr/bin/env bash
# Pattern B — "rel all": release a stream to EVERY partner in a broad coalition set.
#
# Same mechanism as Pattern A — a publish under release/<set>/… — but <set> is a
# BROAD set (coalition, the whole coalition) so one publish reaches all of its members. The
# only difference from "rel them" is the set's membership, which is a registry
# fact. Sharing is deployment-gated and denial is silent, so this shows
# the shape + grants and points at the delivery check instead of faking success.
#
#   Override the broad set / topic:
#     HZ_REL_SET=COALITION-X HZ_REL_TOPIC=demo/cop ./run.sh
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/lib/hello-zenoh.sh"
hz_parse_env "$@"; set -- ${HZ_ARGS[@]+"${HZ_ARGS[@]}"}

hz_banner "Pattern B — \"rel all\" (broad release set)" \
          "One publish under release/<set>/… reaches EVERY partner in the coalition set."

hz_preflight || exit 1
ANCHOR="$(hz_anchor)"
SET="${HZ_REL_SET:-coalition}"                    # a BROAD set: a whole coalition of partner orgs
TOPIC="${HZ_REL_TOPIC:-demo/cop}"
RUN="$(hz_run_id)"
KEY="release/$SET/$TOPIC"

hz_step "1. The release lane — same marker, a broad set"
hz_note "$KEY"
hz_say  "'release/' is the same marker as Pattern A. What changed is the SET:"
hz_say  "'$SET' is a BROAD set — a whole coalition. Every partner in it reads this lane."
hz_say  "So ONE publish here is one-to-many: it reaches all members at once."

hz_step "2. A and B are the SAME mechanism — only the set differs"
hz_say  "  rel them (A):  release/partner-alpha/…   → one partner (bilateral set)"
hz_say  "  rel all  (B):  release/$SET/…            → the whole coalition (broad set)"
hz_note "A bilateral set with one member ≡ per-partner release. You widen the"
hz_note "audience by ADDING MEMBERS TO THE SET — a registry edit — never by changing"
hz_note "the key, republishing, a new cert, a NetBird group, or an Ory claim."

hz_step "3. The same two grants (now the READ grant is held by many partners)"
hz_say  "WRITE — you may publish into '$SET' (zenoh_release_writers).  [built]"
hz_say  "READ  — each partner in '$SET' may read it (zenoh_partner_read_lanes)."
hz_say  "        [built] — for a broad set, many partner anchors hold it."
hz_note "Registry-driven, default-off, additive on deny-by-default, roots inviolable."
hz_note "The ACL does NOT reload live: a partner added to '$SET' receives only after"
hz_note "the next router RESTART."

hz_step "4. Trace the ACL decision for YOUR identity"
DECISION="unknown"
if hz_goat access explain --help >/dev/null 2>&1; then
  hz_cmd "goat access explain $ANCHOR $KEY"
  EXPL="$(hz_goat access explain "$ANCHOR" "$KEY" 2>&1)"
  printf '%s\n' "$EXPL"
  if printf '%s' "$EXPL" | grep -qiE 'allow|granted|permit'; then
    DECISION="allow"
    hz_say "You ARE a granted release-writer for '$SET' — a publish here would land for all members."
  elif printf '%s' "$EXPL" | grep -qiE 'deny|denied|forbid|no.*grant'; then
    DECISION="deny"
    hz_say "You are NOT a granted release-writer for '$SET' — a publish here is DENIED."
    hz_note "Expected for an ordinary identity: the grant is an operator/registry act."
  else
    hz_note "Could not classify the decision; treating as ungranted."
  fi
else
  hz_note "\`goat access explain\` isn't in this goat build — skipping the live trace."
fi

hz_step "5. The publish — shown honestly (denial is silent)"
hz_cmd "goat pub $KEY --payload '{\"cop\":\"nominal\",\"run\":\"$RUN\"}'"
if [ "$DECISION" = "allow" ]; then
  OUT="$(hz_goat pub "$KEY" --payload "{\"cop\":\"nominal\",\"run\":\"$RUN\"}" --encoding json 2>&1)"
  printf '%s\n' "$OUT"
  hz_say "Sent as a granted writer — every partitioned partner in '$SET' receives it."
else
  hz_say "NOT publishing for real: as an ungranted writer this put is SILENTLY denied"
  hz_say "(returns as if it worked, sample never routes). We do not claim it landed."
  hz_note "Delivery is checked on a goatnet with both grants (docs/partner-data-sharing.md §4):"
  hz_note "release/$SET/… REACHES each partitioned partner; their read of your own root sees 0."
fi

# --- assertions -------------------------------------------------------------
hz_step "Verify"
hz_assert_contains "the key uses the 'release/' marker" "$KEY" "release/"
hz_assert_contains "the key carries the broad-set segment" "$KEY" "/$SET/"
hz_assert_lacks    "the key is NOT your private <uuid>/** root" "$KEY" "$ANCHOR/"
hz_done
