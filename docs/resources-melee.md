# Mana, stamina and distance-driven fistfighting — 2026-10-27

The elemental duel now mixes ranged magic with close-range boxing. Both fighters
have 100 mana and 100 stamina, shown in named purple and green HUD meters. Health
and shield guard remain separate. MAGIC, FISTS and RECOVER identify current intent.

## Costs and recovery

Mana is charged at actual spell release, including heals. An unaffordable release
creates no effect and spends no partial mana. Interrupted windups do not create a
free projectile. Mana begins recovering at 4.2/s after a 1.7 s delay, outside casting
and takeoff. Shields cost 8 to raise and 3/s to sustain; an empty mana pool drops
the shield. Guard energy still determines how much incoming damage it absorbs.

| Spell | Mana |
|---|---:|
| Quick offhand spark / water dart | 10 |
| Palm fireball / aqua bolt | 14 |
| Flick slash | 16 |
| Overhead cleave / ground sigil | 18 |
| Spear / lance | 20 |
| Twin-palm blast / crashing wave | 22 |
| Healing | 24 |
| Channel / torrent | 26 |
| Nova / surge | 28 |

Stamina is charged on commitment: jab 8, cross 11, hook 13, dash 14, backward
step 10, roll 18, jump 12, backflip 16 and air dash 22. Running drains 6/s and
pursuit 8/s. Regeneration starts after a short delay, at up to 17/s while resting
and 10/s during guarded footwork. Exhaustion prevents new paid actions. Low
stamina slows pursuit; recovery holds guard or backs away until enough returns.

Every pool is bounded and a new round restores all pools. Test/review scenes use
the same rules. There is no hidden free-mana switch in the autonomous fight.

## Tactical decisions and actual contacts

Below 24 mana, a fighter commits to FISTS: pursue the opponent, enter punching
range, alternate left/right jabs, crosses and hooks. Mana recovery to 62 returns
the fighter to MAGIC and starts a retreat to make space. Different thresholds
prevent rapid back-and-forth mode switching. An enemy already at close range can
provoke punches even with available mana. Stamina below 16 triggers recovery;
that recovery continues until at least 40, rather than spending each tiny recharge.

Jabs/crosses/hooks reuse the included licensed skeletal clips on both rigs. During
the active strike window, a small sphere sweeps from the previous animated fist
position to the current one against the opposing animated hurtboxes. Only an
outbound moving fist can hit, and each attack connects at most once. No health
damage is awarded simply for being close. Punches can miss, be evaded, hit a
directional shield, stagger or knock out. Small neutral flashes identify fist
contacts separately from elemental explosions.

Pursuits and retreats use CharacterBody movement and a soft inward steering area
at the edge of the meadow. The known flat ground also constrains the root to
prevent capsule depenetration pushing crowded fighters below the surface.

## Validation and recorded review

`validate.ps1` passes in the working project and a fresh staged-file package with no import cache, including the existing 120-second duel, shield/footwork,
both-rig movement, saved casting study and pose checks, plus `resources_test.gd`.
The long duel verifies both fighters spend/deplete resources, land melee hits,
switch tactics, retain aerial actions, finish rounds and keep the camera framed.
Health, mana and stamina remain bounded and agree with the visible meters.

Focused resource tests verify exact-cost and insufficient-mana releases, delayed
regeneration, no free low-mana shield, no free exhausted punch/jump/roll, gradual
stamina recovery, physical low-mana pursuit, retreat when mana recovers, and round
reset. Both rigs land one actual jab, while disabled hurtboxes, distant opponents
and an opponent leaving the fist path produce misses.

The final native 70-second recording was inspected across fist exchanges, recovery
and the return to ranged spacing. Fire switches to FISTS at 10.78 s, Water at
11.87 s; they switch back toward MAGIC at 21.55 s and 22.33 s. Fire wins the first
round at 55.17 s with a jab, and a fresh round starts automatically.

| Observed over the recording | Fire | Water |
|---|---:|---:|
| Punches attempted | 22 | 23 |
| Actual melee contacts | 11 | 11 |
| Health damage from fists | 96 | 103 |
| Lowest mana | 18.72 | 13.00 |
| Lowest stamina | 3.57 | 5.22 |
| Tactical switches | 3 | 5 |

Rendered runtime error logs are empty. Initial checks caught an uninitialized HUD
meter and flat-floor penetration during crowded pursuit; both were fixed and
retested. No new assets, plugins or runtime dependencies were added.

```powershell
.\run.ps1
.\validate.ps1
.\scripts\core\review-video.ps1 -Seconds 70
```

The demo remains autonomous: Space slow motion, R restart, Esc quit. This is a
first resource-driven combat pass; it has no player controls, grappling, or
branching player combo system. Costs and tactical thresholds are tuning values.
