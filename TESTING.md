# Testing

ElvUI_mhTags relies on WoW APIs and secret values that cannot be fully reproduced
outside the game client. Use the static checks for every change and the focused
in-game checks for affected tags.

## Static checks

Run these from the addon directory:

```bash
stylua --check .
luacheck .
python3 scripts/validate_toc.py
git diff --check
```

## Quick smoke test

1. Log in with ElvUI and ElvUI_mhTags enabled.
2. Run `/reload` and confirm no Lua errors appear.
3. Open `/ec`, select a unit frame, and confirm the `mhTags` categories appear
   under Available Tags.
4. Run `/mhtags`, `/mhtags debug`, and `/mhtags help`.
5. Exercise the tags affected by the current change.

## In-game matrix

### Health and power

- Open-world friendly and hostile targets:
  - `[mh-health-current]`
  - `[mh-health-percent{0}]`
  - `[mh-health-percent{1}]`
  - `[mh-health-percent-nosign{2}]`
  - `[mh-health-current-percent]`
  - `[mh-health-percent-current]`
  - `[mh-power-percent{0}]`
  - `[mh-power-percent{1}]`
- Confirm health text, percentage, and gradient respond together during damage
  and healing:
  - `[mh-color-health-gradient][mh-health-current-percent]|r`
- Confirm the power tag intentionally omits the percent sign.

### Secret values

Test enemy nameplates and restricted content such as rated PvP when available:

- Health percentages with `{0}`, `{1}`, `{2}`, and `{3}` render without Lua
  errors.
- `[mh-health-percent-nosign{1}]` renders without a percent sign.
- `[mh-health-deficit-percent{1}]` hides when Blizzard prevents arithmetic.
- Secret names display as provided by Blizzard without uppercase, shortening,
  or abbreviation.
- `[mh-color-health-gradient]` continues to produce a health-based color.

Record the exact content type, unit frame, tag string, and Lua error if a
secret-value case fails.

### Absorbs

- With no absorb, `[mh-absorb]` and the absorb prefix in combined health tags
  are empty; `(0)` must never appear.
- With an absorb, verify:
  - `[mh-absorb]`
  - `[mh-health-current-absorb]`
  - `[mh-health-current-percent-absorb]`
- In restricted content, an absorb may use a raw integer instead of an
  abbreviated value.

### Status

Verify each state with `[mh-status]`, `[mh-status-noicon]`, and
`[mh-name-caps-or-status]`:

1. Offline
2. Ghost
3. Dead
4. Feign Death (must not display Dead)
5. AFK
6. DND
7. Normal/online (status tags should be empty)

### Classification and level

Test normal, rare, elite, rare elite, and boss units:

- `[mh-classification-icon]`
- `[mh-classification-text]`
- `[mh-diff-level]`
- `[mh-diff-level-hide]`
- `[mh-classification-name-level]`
- `[mh-classification-name-level-smart]`

Confirm smart level tags hide only when both player and unit are confirmed at
maximum level.

### Names and raid groups

- Test short and long names with CAPS and abbreviation tags.
- In a raid, verify:
  - `[mh-name-caps-with-raid-group]`
  - `[mh-classification-name-level-raid-group]`
- Confirm the displayed subgroup changes after moving a member between groups.

## Bug report template

```text
WoW version:
ElvUI version:
ElvUI_mhTags commit:
Content type:
Unit frame:
Tag string:
Expected result:
Actual result:
Lua error:
Reproduction steps:
```
