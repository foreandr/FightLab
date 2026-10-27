# Storm Overdrive tuning

Overdrive now lasts 14 seconds instead of 7, at the existing 18-mana cost. While
powered, Storm's six-strike preference contains three knees, two punches and one
front kick. Uppercuts remain available. His powered forward burst closes to
1.1 m before the follow-up, and he pursues into knee range rather than repeatedly
starting attacks from outside it.

The buff powers elemental leg augmentation without another mana payment. Powered
strikes cost 25% less stamina and deal 35% more damage. The mantle reduces direct
incoming damage by 25%; it does not remove knockback, wall crashes, burn damage
over time or freezing. Buff expiration restores ordinary costs/damage and the
unbuffed move cycle. The HUD shows remaining Overdrive seconds.

A persistent golden mantle surrounds his actual pelvis position, with animated
flame edges, rising sparks/flames, five lightning arcs and one short-range golden
light. Resources are reused and transient particles use the existing bounded
pool. The aura fades with buff expiry and hides on death/reset. Its clock follows
simulation time, including slow motion.

The focused test verifies funded duration, damage reduction, stamina efficiency,
knee preference, augmentation funding, aura expiry/death/reset and actual physical
dash-to-knee contact. The full regression suite and 180-second combat check pass.
The native controlled recording shows casting, aura activation and real knee
contacts against a stationary target; it is not a win-rate test.

Before the later arena widening, three 180-second autonomous trials used fighter RNG offsets 0, 1777 and 3554.
Before this change, completed wins were Fire 8, Ice 10, Storm 1. After tuning,
they were Fire 7, Ice 8, Storm 4. Storm's action counts contained 86 knees and 41
kicks across the updated trials, including time outside Overdrive. This is a small
simulation sample, not a guarantee of a long-run win rate. Extending duration and
changing the move preference alone produced no Storm wins in the initial tuning
sample; stamina efficiency, melee power and protection were added afterward.

```powershell
.\validate.ps1
.\scripts\core\review-video.ps1 -OverdriveShowcase
.\tools\Godot_v4.6-stable_win64_console.exe --headless --fixed-fps 60 --path . -s res://tests/overdrive_balance.gd
```
