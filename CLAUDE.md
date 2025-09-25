- RULES:
 Make Sure that everything is properly referenced
 Don't make overly complicated names for scripts.
 I don't want emojis used. Instead create IconPlaceholders without an ID and ill make them myself or procedurally generate the Icons yourself.

 Don't recreate scripts constantly, instead rewrite the current scripts if they are the same etc.

 Check Reference images for context. There are GIFS & PNGS Available
 
 GUI Scripts should stay either in StarterGUI.

 This Project is using rojo to connect it to studio so modules are lua files, ServerScripts 
 
 are .server.lua & local scripts are .local.lua
 
 Raycast Uses Exclude & Include because Blacklist & Whitelist are deprecated
 
 Make sure the scripts work before saying they will work.

 I'm making the map by hand so there's no need for automatic generation of one & any UI doesent need the map to have a name.

 Vehicles will be place manually on the map, however there should be a studio console command that can generate a test vehicle (try & make it look nice at least)
 
 Players Spawn in the lobby which is a spawnpoint for not deployed players, whenever you 
 deploy it will switch your team and deploy you onto the battlefield.

 KFC is Maroon & FBI is NavyBlue.
 
 any UI that needs to be made should be created via a console command that only needs to be run once then either tell me where in the UI to place a local script or have the generator create one if possible.

I'm not sure if you are able to run LUA code, but if you can please test before saying its ready 
 Reference Images such as the PhantomForces UI don't need to be copied exact, you can generate something similar or close
 UI needs to be Modern, Professional looking, Slightly Futuristic.
 UI Should be connected & can easily switch between different Sections like: Menu -> loadout/Shop/Settings/leaderboard. flawlessly.
 Onscreen effects like bleeding, Blur (dizzyness), flashbang. ETC should be custom image IDS instead of simple effects. I also want there to be blood particles when shot from the players body that can be seen on the server and small bloodpools
 (Currently Sound & Image ID's have been setup properly by me so don't change them for now.)



- Gameplay:
this game is like  Phantom Forces with random weapons & Battlefield aspects along with other miscellanous systems. some of it is unique.
The gameplay style should remain realistic while still being arcade-like and fast-paced.
Movement will include ledge grabbing, sliding, and dolphin diving (performed by pressing X midair) as well as crouching and prone states.
There are two teams: KFC and FBI. The FBI spawn around This bunker on the map based on the spawn locations in the Spawns Folder & the KFC spawn in & around the city near the KFC. 
These Buildings have already been created by hand so it only needs to grab the spawn locations for each team and spawn them randomly.
The game will feature Phantom Forces-style gameplay & Different battlefield Aspects such as: Enviroment Destruction, Vehicles like tanks & helicopters with destruction physics. 
Each gamemode resets/changes every ~20 minutes before sending players to the menu and waiting for the gamemode to setup. 
Required Core systems will include a XP and leveling system, a gun customization menu that will let you choose the attachments for the guns & weapons you get by random. So you spawn weith random weapons from each category being: Primary, Secondary, Melee, & Extra/Abilities.
In-Game stats that save being: total kills & deaths for each players profile, Kill to death RATIO per match & on the menu a total KDR/ Kill to death Ratio, total XP gained, XP til level up, next weapon unlock.
There will be a credit/currency system that allows you to buy new weapons attachments & skins, Guns that require a specific level can be prebought at a slightly inflated price, attachments can also be prebought for guns owned their price stays the same
Each Rank-Up you gain [X] Amount of credits that increase each time you level up along with required amount of XP to level up. XP can be gained by: Getting Kills, Assists, Objectives/Captures & Holding Objectives (Small Amount), Wallbangs (Small Amount), Suppressing an enemy (Small Amount), headshots, long distance shots, quickscopes, no scopes, backstabs, Double/Triple/Quad Kills, Spotted Player Kills & Assists, Gaining mastery to each weapon & unlocking attachments.
When you rank up you should get a popup on your screen that shows: Level Up! Rank (X) +(X)Credits. Not Sure what to call the currency so for now make it credits but make it so that it can be changed whenever.
XP to level up should work as followed using this formula:  XP = 1000 × ((rank² + rank) ÷ 2). 
The Formula that calculates rank reward from rank 1 to 20 is: Credit = ((rank-1)* 5)+ 200 while rewards past Level 20 should use: Credit = (Rank * 5)+ 200 \
There will be Unlockable perks such as double jump & a temporary speed boost to start & some will have a cooldown while perks like double jump are permanent.
Guns should be tool based & use a viewmodel when equipping the tool. They each have their own dedicated viewmodel folder & weapon model folder (for stuff like gun preview in menu)
Guns should be realistic with advanced stats like: bullet drop, penetration, recoil etc, while also stats that are modified by attachments like suppresion, recoil, & different stats based on ammo types & conversions.
Each weapon config will be stored in the tool for that specific weapon. Viewmodels are stored in ReplicatedStorage.FPSSystem.Viewmodels: Then Depending on what Main category & the sub category it will use that for instance
The G36 is stored in ReplicatedStorage.FPSSystem.Viewmodels.Primary.AssaultRifles.G36 & then the model will be stored in the G36 folder. 
When a weapon tool from this system is equipped it will lock the player in first person on dequipping it allow the player to zoom out again.
There will be other tools not using this system that require certain keybinds so there might need to be a way to check if a player has a tool from this system or not.
So Theoritcally you could make it so that when a player has nothing equipped you can use the movement system freely & when a player has a tool it will possibly check if theres any scripts that use keybinds and either disable certain keys from the movement system or so how have both function properly without one overlapping the other.
Usual Ability Keybinds in other systems: Q,E,R,T,Y,G,H,Z,X,C,V,(*B).
Viewmodels in firstperson should be client sides while on the serverside or what other enemy players see would be different instead they would be animated with a R6 rig that has the gun model attached to the right arm. 
it will play the animations exported from the rig that will sync with the guns state/ client side action like when firing the gun will recoil on the serverside and show bullet tracers.
In the map there will be different pickups that can be placed anywhere on the map manually and could either have a script placed inside or a type of config.
There should also be a roblox config in workspace to store different values. The currently planned pickups are: Armor Pickups, Night Vision Goggles, Medical Equipment, Ammo Refill Packs.
The Night Visions are used along a actively going Day/Night Cycle that should be slow but will change in less than ~10 or more
The gun customization menu should display advanced stats, allow previewing the gun model stored in ReplicatedStorage.FPSSystem.WeaponModels.(Primary,Secondary,Grenade,Melee).(Then the subcategory)
There should be a grenade system in place. 
here are impact grenades that detonate upon contact with any part or surface,
Sticky grenades that will stick to walls, 
High Explosive grenades, Frag grenades, 
Smoke Grenades,
Flashbangs,
Flares (blinds players),
& C4 that can be placed and remotely detonated (despawns after awhile & death of the player that placed it)
each grenade will have its own explosion radius that decreases the further you are away & some will decrease your walkspeed
Some grenades can be cooked while others can't, grenades the can be cooked while tick by expanding the crosshair outward to indicate that a tick has passed and after the final tick the grenade will explode killing the player
Each grenade will have its own viewmodel & custom animations as well.
Grenades will have custom explosion effects accompanied by the default roblox explosion effect.
Melees are set into different groups that being one & two handed blunt & blades.
One handed blades instant kill upon backstabbing a player, while blunt ones do more base damage, have more range & can be used to kill multiple players easier
One handed weapons are quicker than two handed ones, two handed melees have more range than one handed melees
You can right click to play a special attack animation.
Grenades & Melees can be quickly swapped by pressing a hotkey which switches the tool rapidly from your hotbar/inventory, G for grenade & F for melee.
one handed melees will increase your walkspeed depending on which on you have equipped & two handed blades make you slightly slower
Upon first joining the game at Rank 0 the randomized weapon pool will grab a random Primary, Secondary, Melee, Grenade & Magic. 
The default weapons that the player has unlocked by default will have 2 from each category excluding SniperRifles, & Secondaries Subcategory other. 
Grenades & Melees will only use The Default Rank 0 PocketKnife & M26 Grenade until the player unlocks (& or) Pre-buys a weapon.
When a Player unlocks a weapon itll be added to their weapon pool allowed for them to get it out of the randomly selected weapons they have unlocked.\
Weaponskins can be bought in the menu under the shop section, they will be applied on each weapon (as a placeholder for now make it grab a texture ID from a folder or something)
The Skins change every 24 hours in the shop while some can be made exclusive & limited.
There should also be a settingS section in the menu 
that has a  sensitivity slider (seperate from the roblox client/application sensitivity), 
a ragdoll factor slider that can be increased to send players bodies flying upon killing them with a weapon from this system
FOV, (Only affects the players FOV when a weapon from this system is equipped.)
There should be a radar on the lower left of the screen that also has the current score & gamemode name above it.
The radar will go off if somone shoots a weapon that isnt suppressed or is loud. it will show a sort of wave expand and show the players arrow or icon for a few seconds before disappearing.
Enemy Player's Footsteps will be louder than teammates. & the audio should work in 3D.
Bullets that fly past you should make a whizz SFX, along with when they hit through walls.
Bullets that hit different surfaces/materials will make difference sounds based on them.
Each material also has its penetration factor for instance: wood being very poor whilst metal being more strong and requires a higher pentrating gun to pass through.
Players can spot enemies in their viewrange by hitting Q which will put a small red indicator over the enemy players body that can be seen by the spotters whole team.
Spotting a player will play a sound effect each time you spot a player.
the player can crouch or hide in a building out of sightline to remove the indicator.
you can also place markers with Q to ping a specific area on the map.
Game modes: 
Team Deathmatch (TDM), 
King of the Hill (KOTH),
Kill Confirmed (KC),
Capture the Flag (CTF),
Flare Domination,
Hardpoint (HD),
 Gun Game (GG),
 Duel (secondary weapons only),
 Knife Fight (melee only), 
with modes being votable or changeable via admin commands.
Some of the modes will have abbrievations mentioned above while stuff like Flare Domination, Duel & Knife fight won't.
Objectives should be placed manually and have their spawn/position stored in a part on the map that can be in serverstorage
Each gun will have attachments & some will be exlusive to that gun
Supressors are mostly universal for Primary & secondary weapons, while some guns like the NTW-20 for example cannot have it equipped
All Primary guns should have the same grips minus a few that only show up for certain guns.
Shotguns can have different ammo types that can increase or decrease the pellet count, for instance birdshot would have around 18, while slugs would only have one.
some shotguns like the double barrel or the sawed off can switch their firemode with V to burst mode which fires both shells at once.
Some guns will also different firemodes like: Auto, Semi, Burst & Hyperburst.
the gun stats in the gun config should be easily changeable.
there are four classes: Assault, Scout, Support, Recon. each class has their own special guns except some share between two classes
for instance Recon: Exclusively Has SniperRifles, But also shares Carbines, BattleRifles & DMRS Which Carbine is available in all classes.
PDW's Exclusive is Well: PDW
Support's Exclusive is LMG
Assault is ofc AssaultRifles
Assault, Support & Recon Share BattleRifles
Assault PDW & Support Share Shotguns
Scout & Recon Share DMR
Secondaries dont apply to classes so any secondary can be equipped
same goes for Melees & Grenades.
Attachments will attach to a roblox attachment placed within the weapons model for both the gun preview in the menu & the viewmodels gunmodel.
Scopes Should work like they do in phantom forces (the updated scopes though), where u can Hit T on scopes to switch modes between a 3D scope & a UI based scope.
if the player is using the UI scope mode, the gun/View should sway a bit and the player should hold shift to stabilize it for a short time before "running out of breath"
Laser attachments will start at the guns attachment point. Lasers should be clientsides & or should only be able to be seen by the players own team, but flashlights will show up for everyone.
Grip attachments can increase & decrease recoil.(grips can have both positive & negative stat changes)
For Instance one grip can increase the guns aimspeed but decreases accuracy.
Certain Suppressors will only show on the radar up to a certain stud range.
Ammo types for each gun can increase & decrease stats
Such as: Armor Piercing (Better penetration lesser damage to torso & head)
Some guns have different barrels that can increase range or increase CQC damage in exchange for shorter range.
for instance the NTW-20 would have a heavy barrel that makes you much slower but has more range
 & the obrez barrel which allows you to scope without crouching or leaning against a building/wall but has poor accuracy & requires you to aim up higher to hit the target.
 or a AssaultRifle can have a carbine barrel (& or) AssaultBarrel while some DMR's & other guns can have a marksman barrel.
 Shotguns can have different choke barrel attachments that can decrease spread along with other effects.
all attachments require a certain amount of kills to unlock for free starting from 5 (if said gun doesent come with free attachments) to 2-3K and so forth.
different sights will include iron sights, red dots, & scopes for now.
Special rounds can be equipped by a perk giving temporary status effects to the enemies who are shot, The Special rounds are time based and will run out within ~30 or less or if the player has to reload (excluding snipers or guns that dont have multiple shots at once) 
They Will also have a cooldown of ~30 or less
Current Status Effects:
Incendiary, (Fire VFX over enemies body & does D.O.T (Damage over time) or fire damage.)
Frostbite, (Slows the player down & if shot enough times freezes them in a block of ice.)
Explosive (Explodes where the bullets hit)
There are also other status effects that the player can have such as:
Bleeding (D.O.T, Bleed Damage)
Fracture (Slower Walkspeed,small blood trail)
Deafened (a grenade was exploded nearby & a ringing sound will play for a few seconds, but is quiet to not annoy players)
Etc.
Some status effects can be removed by a medical item like a bandage which stops bleeding & tourniquet which stops fractures
the status effects will remove after a decent time has passed (meant to be long but not excruciatingly long)
Currently There are only 4 Weapons setup at the moment so until I have implemented more
make these the only weapons you can obtain while also being able to easily configure, add, & change which weapons are available
You can go ahead and premake different guns in the menu but just have them temporaryily disabled for now.
I'd also like a special ntw variant for admins that has a suppressor on it, that while fling the player back slightly upon firing and upon hitting & killing the enemy will send both you & the enemy into orbit killing you both.
The game will have custom destruction physics where u can use different perks/abilities like a RPG to explode buildings & watch them crumble (I'm unsure how well this feature can be implemented so if it becomes a major issue u can just leave it be)
The game will have different vehicles like tanks & helicopters that are advanced
the vehicle models can be simplified for now so just make it grab specific parts like
for a tank: treads/wheels, TankBarrel, Seat, etc
and for a helicopter, Rotor,Seat, etc
not sure how this will work so this also isnt that neccessary
Currently The system needs to be overhauled with these changes and some scripts can be deleted or rescripted entirely.
for the menu I'd like for you to create a script thats completely seperate from this  system that I run one time in the studio console 
and it will automatically create a custom menu UI in StarterGUI, so that the other scripts can refer to it inside of StarterGUI  instead of it being created each time 
& this script doesent need to be used after that and can be deleted after.
Playerlist should be hidden entirely and when hitting tab a custom player list showing each players rank, Current Match: Kills,Deaths, KDR, Streak, Score.
along with what team they are on
also check the png files for references AttachmentUIExample images show how phantom forces attachments look. you may use this as a reference whilst sticking to the current UI/theme See the menu png for info
also look at Stats Loadout 1 & 2 for info on how the stats should display
there also are 2 gifs that ive converted from mp4's that will showcase what how the UI looks & functions in phantom forces.