# FPSFrameworkEngine — Full Specification (claude.md)

## RULES
- Make sure that everything is properly referenced.
- Don't make overly complicated names for scripts.
- Do not use emojis. Instead create `IconPlaceholders` without an ID (you will provide IDs or procedurally generate icons yourself).
- Don't recreate scripts constantly; rewrite existing scripts if they already exist and serve the same purpose.
- Check reference images (GIFs & PNGs) for context when implementing UI and systems.
- GUI scripts should be stored in `StarterGUI`.
- This project uses Rojo to connect to Studio:
  - Modules are `.lua`
  - ServerScripts are `.server.lua`
  - LocalScripts are `.client.lua`
- Raycast should use `Include` and `Exclude` (Blacklist/Whitelist are deprecated).
- Make sure scripts work before claiming they are ready.
- Map is created manually; do not implement automatic map generation. UI does not require the map to have a name.
- Vehicles are placed manually in the map, but provide a Studio console command to generate a test vehicle (should be presentable).
- Players spawn in a lobby spawn point for not-deployed players. Deploying switches a player's team and deploys them to the battlefield.
- KFC is Maroon; FBI is NavyBlue.
- Any UI that needs to be created should be generated via a console command (one-time). The generator should either create required LocalScripts or tell where to place them.
- If you can run Lua tests locally, test scripts before declaring them ready.
- Reference images (e.g., Phantom Forces UI) are for inspiration — do not copy exactly but produce similar, modern, slightly futuristic UI.
- UI must be modern, professional, and slightly futuristic. Menus should switch seamlessly between sections: Menu → Loadout / Shop / Settings / Leaderboard.
- On-screen effects (bleeding, blur/dizziness, flashbang, etc.) should use custom image IDs (not simple built-in effects).
- Blood: shots cause blood particles visible server-side and create small blood pools on the ground (server authoritative).
- Sound & Image IDs are set up by the user—do not change them unless requested.

---

## GAMEPLAY SUMMARY
- Core gameplay = Phantom Forces-style gunplay with Battlefield aspects (vehicles, destructible elements) and additional unique features.
- Keep gameplay realistic but arcade-like and fast-paced.
- Movement features:
  - Crouch, Prone
  - Sliding
  - Ledge grabbing
  - Dolphin dive (press X midair)
- Two teams exist (KFC and FBI) for aesthetics/lore. Core gameplay is FFA-focused; teams are primarily visual. Admins can run sort-RP events using teams for narrative flavor.
- Spawns:
  - FBI spawn points located around the bunker (use `Spawns` folder spawn locations).
  - KFC spawn points located around the KFC/city area (use `Spawns` folder).
  - Randomize spawn location from each team's spawn list when deploying.
- Gamemodes and lifecycle:
  - Modes include: TDM, KOTH, Kill Confirmed (KC), CTF, Flare Domination, Hardpoint (HD), Gun Game (GG), Duel (secondaries only), Knife Fight (melee only).
  - Modes are votable or changable via admin commands.
  - Each gamemode lasts ~20 minutes, then resets/returns players to the menu while the next gamemode sets up.

---

## PROGRESSION, XP & CURRENCY
- XP formula: `XP = 1000 × ((rank² + rank) ÷ 2)`.
- Rank rewards (credits):
  - Rank 1–20 → `Credits = ((rank - 1) × 5) + 200`
  - Rank 21+ → `Credits = (rank × 5) + 200`
- Rank-Up popup: `Level Up! Rank (X) + (Y) Credits` (credits are a configurable currency; default name: credits).
- XP sources (examples): kills, assists, objectives/captures, holding objectives (small amount), wallbangs (small), suppression (small), headshots, long-distance, quickscopes, no-scopes, backstabs, multi-kills, spotting assists, weapon mastery progress and attachment unlocks.
- Unlocks:
  - Weapons and attachments unlock via XP/weapon kills or can be pre-bought for credits at an inflated price.
  - Attachments unlocking is tied to kills with that specific gun (see Loadout section).

---

## CLASSES
- Four classes: Assault, Scout, Support, Recon.
  - Assault: Assault Rifles (exclusive), shares Battle Rifles, PDWs&Shotguns overlaps.
  - Scout: DMRs; shares some weapons with Recon.
  - Support: LMGs (exclusive) and shared Shotguns with Assault.
  - Recon: Sniper Rifles (exclusive), also has Carbines, DMRs, Battle Rifles.
- Secondary, Melee, Grenades not class-locked.

---

## WEAPONS, VIEWMODELS & TOOLS
- Weapon architecture:
  - Weapons are Tools. Each weapon tool contains its config and metadata.
  - Viewmodels are client-side and stored under `ReplicatedStorage.FPSSystem.Viewmodels.<Category>.<Subcategory>.<WeaponName>`.
  - Server representation uses R6 rigs that animate and show the weapon to other players.
  - Tool equipping: locks the local camera to first-person; unequipping restores freedom.
- Weapon stats basics:
  - Bullet drop, velocity, penetration, recoil, spread, handling, aim speed, ADS speeds, reload timings, fire modes.
  - Stats can be modified by attachments and ammo types.
- Storage conventions:
  - Example: `ReplicatedStorage.FPSSystem.Viewmodels.Primary.AssaultRifles.G36` stores viewmodel and model folders for G36.
- Config should be easy to edit; attachments and weapon stats should be data-driven via JSON-like Lua tables stored in the tool.

### Non-FPS Custom Weapons
- There will be separate weapons that do not use the FPS system. These can be custom Roblox gears (e.g., Periastrons) or other tools with unique abilities and custom keybinds. The system should manage compatibility between a player having an FPS-system tool equipped and other custom tools (disable overlapping keybinds or coordinate input handling).

---

## MELEE & GRENADE SYSTEM
- Grenade types: impact (detonate on contact), sticky, high-explosive, frag, smoke, flashbang, flare (blinds), C4 (placeable & remote detonation; despawns on death/time).
- Grenade mechanics:
  - Each grenade has its own explosion radius and effects; damage diminishes with distance.
  - Some grenades reduce walk speed or apply other status effects.
  - Cookable grenades: crosshair ticks outward per tick; final tick detonates. Some grenades cannot be cooked.
  - Each grenade has its own viewmodel & custom animations. Explosions have custom VFX + Roblox explosion.
- Melee:
  - Categories: one-handed blade, one-handed blunt, two-handed blade, two-handed blunt.
  - One-handed blades: instant backstab kill when hitting from behind.
  - One-handed blunt: more base damage, faster swings, multi-hit potential.
  - Two-handed: slower, more range and damage.
  - Right-click triggers special attack animation.
  - Grenades & melees quick-swap hotkeys: G for grenade, F for melee.
  - Melee weight/speed affects player movement (1H increases speed, 2H decreases).

---

## ATTACHMENTS & CUSTOMIZATION
- Attachments attach to actual Roblox Attachment instances within weapon models to ensure correct positioning for both menu preview and viewmodels.
- Attachment effects include: recoil modification, aim speed changes, accuracy, suppression, sway reduction, and other stat shifts. Grips can trade aim speed vs accuracy.
- Suppressors: mostly universal, but some guns cannot equip them (e.g., NTW-20 example). Some suppressors only show on radar up to a certain stud range.
- Scopes:
  - Scopes function similarly to Phantom Forces' updated scopes.
  - Press **T** to switch a scope between a 3D in-world scope and a UI-based scope.
  - UI scope mode introduces sway; hold **Shift** to steady aim for a short duration before stamina runs out.
- Ammo types change pen/damage profile (e.g., Armor Piercing = better penetration less torso/head damage; slugs in shotguns = single pellet) and may change other traits.
- Barrel variants, chokes for shotguns, and other attachments modify weapon handling and performance.
- All attachments have unlock thresholds based on kill counts with that specific gun (example thresholds: 5 kills to 2–3k kills depending on rarity).
- Attachments may also be pre-bought through the Loadout (purchased per gun).

---

## STATUS EFFECTS & MEDICAL ITEMS
- Status effects include:
  - Incendiary: fire VFX on the enemy and DOT.
  - Frostbite: slows target; repeated hits can freeze them into an ice block.
  - Explosive: bullets or rounds that explode on impact.
  - Bleeding: DOT and visible blood trail.
  - Fracture: slower walk speed and a small blood trail.
  - Deafened: ringing after nearby explosion (mild, short).
- Some status effects removable by items:
  - Bandage (stops bleeding)
  - Tourniquet (stops fractures)
- Status effects decay after a set duration (long, but not permanent).

---

## AUDIO & MATERIALS
- Footsteps are 3D. Enemy footsteps louder than teammates.
- Bullet whizz SFX for rounds flying past.
- Material-based hit sounds and penetration multipliers/pen values (wood low, metal high).
- Each material has a penetration factor affecting if a bullet passes through.

---

## RADAR & HUD
- Radar: **top-left** of the screen (changed from lower-left). Displays small map/range indicator, player icons/arrows for pings, current score & game mode above the radar.
- Radar behavior:
  - When an unsuppressed or loud shot occurs, radar pings show for a short time (wave expand effect and player icon shown for a few seconds).
  - Radar pings are based on suppression/noise and distance thresholds.
- HUD should be clean, minimal, with sections for health, armor, ammo count, equipped weapon, and a compact killfeed.

---

## PICKUPS & WORLD INTERACTABLES
- Manual placement of pickups on the map. Each pickup can hold a script or config object with type & behavior.
- Planned pickups: Armor, Night Vision Goggles (NVG), Medical Kits, Ammo Packs.
- NVGs used in conjunction with day/night cycle. Day/Night cycle should be slow (less than ~10 minutes to cycle? configurable).

---

## VEHICLES & DESTRUCTION
- Vehicles: Tanks, Helicopters, others. Simplified vehicle assembly by selecting key parts (tank: treads/wheels, TankBarrel, Seat; heli: rotor, Seat).
- Vehicles should be advanced but can be simplified for prototyping; admin/studio spawn command for a test vehicle.
- Destructible environment is desired (RPGs, explosives crumbling buildings). This can be scaled back if performance or complexity is an issue.
- Vehicle destruction and physics should be server-authoritative and network-optimized.

---

## MENU & UI GENERATOR
- Create a one-time Studio console command script that builds a complete custom menu UI in `StarterGUI` (modern, slightly futuristic).
- The generator should create the structure (Menu container, Loadout, Shop, Settings, Leaderboard, HUD templates), and either add LocalScripts or indicate where to place them.
- The menu generator can be deleted after running once.
- Playerlist: hide default Roblox playerlist. Press **Tab** to show custom player list with:
  - Rank, Current Match: Kills, Deaths, KDR, Streak, Score, Team.
- Settings menu should include:
  - Sensitivity slider (separate from Roblox client/application sensitivity)
  - Ragdoll factor slider
  - FOV slider (affects FPS viewmodels only)
- Gun customization menu must display advanced stats and allow previewing weapon models from `ReplicatedStorage.FPSSystem.WeaponModels.<Category>.<Subcategory>.<WeaponName>`.
- Shop specifics:
  - **Skin Shop**: only skins. Skins rotate every 24 hours; some are limited/exclusive.
  - **Loadout Menu**: where you pre-buy guns (if not unlocked) at a higher price and buy attachments individually per gun. Attachments unlocking depends on kill counts for that weapon (tracked per-player).
- Ensure UI sections switch seamlessly (Menu → Loadout / Shop / Settings / Leaderboard).

---

## STATS & PERSISTENCE
- Save per-player persistent stats:
  - Total kills, deaths, overall KDR
  - XP and rank level
  - Credits balance
  - Weapon unlocks and mastery progress (per weapon kill counts)
  - Owned attachments, skins, and pre-buys
- In-match stats:
  - Current match kills, deaths, KDR, streak, score (displayed on Tab playerlist).
- Implement safe, atomic saving (robust to disconnects) and server-side validation for purchases and unlocks.

---

## ADMIN & CONSOLE COMMANDS
- Admin commands to:
  - Force gamemode change or vote outcome
  - Spawn test vehicles
  - Grant items or credits
  - Trigger server events for RP/sort events
  - Spawn menu UI via generator (one-time)
- Console commands should be placed in a dev/admin module and accessible to authorized users.

---

## IMPLEMENTATION NOTES & STYLE GUIDE
- Follow Rojo conventions for file naming and placement.
- Keep module/script names simple and consistent (`GameServer`, `WeaponTool_G36`, `MenuGenerator`, etc.).
- Use `Include`/`Exclude` raycast params.
- Use `ReplicatedStorage` for shared data and models; `ServerStorage` for server-only resources like objective markers/parts.
- Use Bindable/Remote events conservatively and validate on server for all client requests related to gameplay, purchases, spawns and state transitions.
- Keep UI creation via a generator; avoid creating UI at runtime each round.
- Prefer data-driven configs for weapons, attachments, pickup definitions, and gamemode settings.

---

## NOTES ON CURRENT STATUS & TODOs
- There are currently only 4 weapons implemented. For now, make these four available in the randomized weapon pool and ensure they are easy to configure and extend.
- Pre-create placeholders for additional weapons in the menu but mark them disabled until implementation.
- Implement the NTW admin variant (suppressed NTW with recoil fling + kill effect that launches both players into orbit) as a special admin-only weapon.
- Prioritize systems in this order: core weapon/gunplay mechanics → weapon attachment unlock system → UI generator & menu → gamemode lifecycle & spawn system → vehicles & destructible environment.
- If destructible buildings or advanced vehicle physics become intractable, document fallback options (simplified destruction, breakable parts, or cosmetic destruction VFX).

---

## REFERENCES
- Refer to provided PNGs & GIFs (menu references, AttachmentUIExample, StatsLoadout images) for UI and attachment visuals.
- Phantom Forces UI is a visual reference but do not copy verbatim.

---

## CHANGE LOG (Recent Edits)
- Radar moved to **top-left** (was previously lower-left).
- **Skin Shop** clarified to be *only* for skins.
- **Loadout** clarified: prebuy guns (if not unlocked) and buy attachments per gun. Attachments unlock by kills on that specific gun.
- Added **Non-FPS custom weapons** (Roblox gears & ability-based tools) that do not use the FPS system but must interoperate with it.
- Teams are aesthetic/lore-only; core gameplay remains FFA. Admin-run sort-RP events can utilize team system for narrative purposes.
