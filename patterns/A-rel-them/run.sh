#!/usr/bin/env bash
# Pattern A — "rel them": release a stream to ONE named partner via a bilateral set.
#
# Derives YOUR anchor, builds the release/<bilateral-set>/<topic> key you would
# publish, and traces the real ACL decision for your identity. Sharing into a
# release lane is deployment-gated (you must be a granted release-writer, and the
# router must restart to pick up a new grant), so this shows the SHAPE and the
# grants and points at the delivery check instead of faking a success.
#
#   Override the bilateral set / topic:
#     HZ_REL_SET=partner-bravo HZ_REL_TOPIC=demo/posture ./run.sh
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/lib/hello-zenoh.sh"
hz_parse_env "$@"; set -- ${HZ_ARGS[@]+"${HZ_ARGS[@]}"}

hz_banner "Pattern A — \"rel them\" (bilateral release)" \
          "Share a stream with ONE named partner via a release set whose only member is that partner."

hz_preflight || exit 1
ANCHOR="$(hz_anchor)"
SET="${HZ_REL_SET:-partner-alpha}"          # a bilateral set: its ONLY member is one partner org
TOPIC="${HZ_REL_TOPIC:-demo/posture}"
RUN="$(hz_run_id)"
KEY="release/$SET/$TOPIC"

hz_step "1. The release lane — a key that says 'deliberately released'"
hz_note "$KEY"
hz_say  "The leading 'release/' segment is the marker: this is NOT a private root."
hz_say  "'$SET' is a BILATERAL set — a release set whose only member is one partner."
hz_say  "So a sample published here reaches exactly that one partner, and no one else."
hz_note "Contrast your OWN private root, which a partner is DENIED entirely:"
hz_note "  $ANCHOR/**   (yours alone; deny-by-default protects it)"

hz_step "2. The two grants that stand this lane up"
hz_say  "WRITE — you may publish into the set (zenoh_release_writers →"
hz_say  "  release-w-<anchor> on release/$SET/**).  [built]"
hz_say  "READ  — the partner may read the set (zenoh_partner_read_lanes)."
hz_say  "        [built] the partner read partition."
hz_note "Both are registry-driven, default-off, additive on deny-by-default, and"
hz_note "NEVER touch a single-owner <uuid>/** root. The ACL does NOT reload live:"
hz_note "a new grant takes effect only on the next router RESTART."

hz_step "3. Trace the ACL decision for YOUR identity"
DECISION="unknown"
if hz_goat access explain --help >/dev/null 2>&1; then
  hz_cmd "goat access explain $ANCHOR $KEY"
  EXPL="$(hz_goat access explain "$ANCHOR" "$KEY" 2>&1)"
  printf '%s\n' "$EXPL"
  if printf '%s' "$EXPL" | grep -qiE 'allow|granted|permit'; then
    DECISION="allow"
    hz_say "You ARE a granted release-writer for '$SET' — a publish here would land."
  elif printf '%s' "$EXPL" | grep -qiE 'deny|denied|forbid|no.*grant'; then
    DECISION="deny"
    hz_say "You are NOT a granted release-writer for '$SET' — a publish here is DENIED."
    hz_note "That is expected for an ordinary identity: the release-writer grant is an"
    hz_note "operator/registry act (see step 2). Nothing to fix; this is the guardrail."
  else
    hz_note "Could not classify the decision from the output; treating as ungranted."
  fi
else
  hz_note "\`goat access explain\` isn't in this goat build — skipping the live trace."
  hz_note "Update goat to trace the mesh→identity→ACL→release decision for a key."
fi

hz_step "4. The publish — shown honestly (denial is silent)"
hz_cmd "goat pub $KEY --payload '{\"posture\":\"green\",\"run\":\"$RUN\"}'"
if [ "$DECISION" = "allow" ]; then
  OUT="$(hz_goat pub "$KEY" --payload "{\"posture\":\"green\",\"run\":\"$RUN\"}" --encoding json 2>&1)"
  printf '%s\n' "$OUT"
  hz_say "Sent as a granted writer — the partitioned partner reading '$SET' receives it."
else
  hz_say "NOT publishing for real: as an ungranted writer this put would be SILENTLY"
  hz_say "denied — it returns as if it worked, but the sample never routes."
  hz_say "So we do not claim it landed. Delivery is checked on a goatnet with both grants:"
  hz_note "the six-point matrix in docs/partner-data-sharing.md §4 — the producer's lane"
  hz_note "REACHES the partitioned partner; its read of the producer's own root gets 0 samples."
fi

hz_step "5. Growing the audience later is a registry edit — not a new key"
hz_say  "To let a SECOND partner see this too, you do NOT republish or change the key."
hz_say  "You add that partner to the set's membership in the registry — a read-lane"
hz_say  "grant. Broad, coalition-wide audiences are Pattern B ('rel all'). The key"
hz_note "release/$SET/$TOPIC is stable; the audience is a registry fact, resolved off-key."

# --- assertions -------------------------------------------------------------
hz_step "Verify"
hz_assert_contains "the key uses the 'release/' marker (deliberately released)" "$KEY" "release/"
hz_assert_contains "the key carries the release-set segment" "$KEY" "/$SET/"
hz_assert_lacks    "the key is NOT your private <uuid>/** root" "$KEY" "$ANCHOR/"
hz_done
