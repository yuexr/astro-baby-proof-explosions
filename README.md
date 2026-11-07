![Baby-Proof Explosions](./img/babyproof-banner.png)

# Baby-Proof Explosions

Makes all explosions (from dynamites, gas, flora, etc.) tiny with negligible blast force that effectively do not damage terrain or players. Equipment is protected from the game's direct explosion-destruction checks.

EXO caches and supported debris are still destroyable and release intended objects. Vehicle protection can be toggled in game. Dynamite must be directly attached to the item intended to break.

Multiplayer tested.

## Install

Vortex and AstroModLoader-Classic installation recommended.

[Please see detailed installation guide here.](https://yuexr.github.io/astro/mods/installation.html)

UE4SS (and UE4SS ConsoleCommandsMod) required. Both automatically installed through instructions above.

**Multiplayer:** Server-side mod. Only the host needs to have the mod installed, and only the host can change protection settings. Guests cannot change settings whether or not the mod is installed.

## Baby-Proof Explosions Controls

Baby-Proof Explosions always defaults to ON upon every game launch.  
Vehicle protection defaults to ON and remembers your last setting.

**(RECOMMENDED) In-game console toggle:** 

Press F10 (or tilde key) once to open the console input field or twice to see the full console.
Selection & changes apply immediately in-game.

Available commands:

```
babyproof                  shows all commands

babyproof status           reports current protection status
babyproof on               enables safe explosions
babyproof off              restores vanilla explosions (BE CAREFUL!)

babyproof vehicles on      vehicles are safe & protected from explosives!
babyproof vehicles off     vehicles can be destroyed by attached explosives

babyproof v on/off         v can be used as alias for vehicles
```
*All commands also report current protection status.*

**Tips & notes:**
- Protection always resets to `babyproof ON` upon every game launch.
- `babyproof ON` restores full protection, and also overwrites vehicle protection status by turning `babyproof vehicles ON`. This is a safety feature!
- Vehicle protection is saved automatically when changed and carries over between sessions. Check status if unsure!

> [!IMPORTANT]  
> Please ensure the explosive is directly attached to the vehicle and not storage.  
> Due to an asset indestructible flag, rail cars and engines must be packaged with a packager first to be destroyed (same as vanilla). Attach dynamite directly to package with vehicle protection off.

![Baby-Proof Explosions Console Example](./img/babyproof-console-example.png)

## Manual Toggle for Vehicles

Optional. Deprecated, but still works.  
In-game commands are recommended.

Open `config.ini` in your mod folder:
```ini
[Explosions]
ProtectVehicles=true
```
- `true` (default): vehicles protected from all explosions
- `false`: vehicle destruction allowed

Game must be restarted for selection to apply.


---


Inspired by [Anti Grief Mod by Colson](https://atenfyr.com/ams-archive/mod?mod=WeakDynamiteMod.Colson).
