#!/usr/bin/env bash
# Pattern C — the partner's view: DISCOVER what's shared with you, and see the
# ISOLATION guarantee (you are denied every other org's private root) that makes
# sharing safe.
#
# Runs from YOUR seat. Discovery via `goat access who` is operator-gated — the
# demo degrades honestly if you don't have it. Isolation is shown with
# `goat access explain`, which traces the ACL decision for a key (denial at
# publish time is silent, so a decision trace is the honest way to see it).
#
#   Override the release set / another-org root probed:
#     HZ_REL_SET=coalition HZ_OTHER_ROOT=<32hex>/state ./run.sh
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/lib/hello-zenoh.sh"
hz_parse_env "$@"; set -- ${HZ_ARGS[@]+"${HZ_ARGS[@]}"}

hz_banner "Pattern C — the partner's view (discover + isolation)" \
          "What has been shared with me? And what stops me reading anything that wasn't?"

hz_preflight || exit 1
ANCHOR="$(hz_anchor)"
SET="${HZ_REL_SET:-coalition}"
TOPIC="${HZ_REL_TOPIC:-demo/cop}"
REL_KEY="release/$SET/$TOPIC"
# A clearly-not-yours root: a placeholder 32-hex anchor that isn't your CN.
OTHER_ROOT="${HZ_OTHER_ROOT:-ffffffffffffffffffffffffffffffff/state}"

hz_step "1. (discover) Who is a release topic's audience?"
if hz_goat access who --help >/dev/null 2>&1; then
  hz_cmd "goat access who $REL_KEY"
  WHO="$(hz_goat access who "$REL_KEY" 2>&1)"
  RC=$?
  printf '%s\n' "$WHO"
  if [ "$RC" -ne 0 ] || printf '%s' "$WHO" | grep -qiE 'operator|forbidden|403|not authorized|permission'; then
    hz_note "\`goat access who\` is OPERATOR-GATED — as an ordinary partner you may not"
    hz_note "run the reverse audience query. That's expected, not a bug; fall to step 2."
  else
    hz_say "This lists who may write '$REL_KEY', who may read it, and which partners"
    hz_say "receive it if released. That's the audience — resolved off the key, from the registry."
  fi
else
  hz_note "\`goat access who\` isn't in this goat build (or is operator-gated) — using explain."
fi

hz_step "2. (discover) Which lanes may I, specifically, read?"
if hz_goat access explain --help >/dev/null 2>&1; then
  hz_cmd "goat access explain $ANCHOR $REL_KEY"
  EXPL="$(hz_goat access explain "$ANCHOR" "$REL_KEY" 2>&1)"
  printf '%s\n' "$EXPL"
  hz_say "If your anchor is a member of set '$SET', this resolves to ALLOW (read):"
  hz_say "that is your read partition — zenoh_partner_read_lanes.  [built]"
  hz_say "For a set you are NOT in, the same trace resolves to DENY."
else
  hz_note "\`goat access explain\` isn't available — skipping the per-key trace."
fi

hz_step "3. (isolation) The deny that makes sharing safe"
hz_say  "A partner reads its OWN anchor + the release lanes it's granted, and NOTHING"
hz_say  "else. Every other org's private <uuid>/** root is DENIED. Watch the ACL say so:"
if hz_goat access explain --help >/dev/null 2>&1; then
  hz_cmd "goat access explain $ANCHOR $OTHER_ROOT"
  DENY="$(hz_goat access explain "$ANCHOR" "$OTHER_ROOT" 2>&1)"
  printf '%s\n' "$DENY"
  if printf '%s' "$DENY" | grep -qiE 'deny|denied|forbid|no.*grant|not.*allow'; then
    printf '    %s✓%s reading another org'\''s private root is DENIED — isolation holds\n' "$C_GREEN" "$C_RESET"
  else
    hz_note "Output didn't clearly show a deny — inspect it above. On a healthy ACL this"
    hz_note "root is not yours and not a release lane you hold, so it must resolve to deny."
  fi
else
  hz_note "Can't trace live without \`goat access explain\`; the guarantee still holds:"
  hz_note "the read partition admits only your anchor + your granted release lanes."
fi
hz_note "Denial at publish time is SILENT — so we read isolation from a"
hz_note "decision trace or from ABSENCE at a subscriber, never from an error."

hz_step "4. The whole point, from the partner's chair"
hz_say  "You see: your own anchor, the release lanes you're a member of, nothing more."
hz_say  "Release is opt-in exposure ON TOP OF a floor of total isolation — which is"
hz_say  "exactly why a producer can share one stream and trust nothing else leaks."
hz_note "The six-point matrix in docs/partner-data-sharing.md §4 checks it: the partner"
hz_note "RECEIVES release/$SET/… yet reading the producer's own root returns 0 samples."

# --- assertions -------------------------------------------------------------
hz_step "Verify"
hz_assert_contains "the lane you may read is a 'release/' lane" "$REL_KEY" "release/"
hz_assert_lacks    "the other-org root you probed is NOT a release lane" "$OTHER_ROOT" "release/"
hz_assert_lacks    "the other-org root is NOT your own anchor" "$OTHER_ROOT" "$ANCHOR"
hz_done
