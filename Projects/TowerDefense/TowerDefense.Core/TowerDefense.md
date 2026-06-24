# Tower Defense Game - Implementation Plan

A full tower defense game built on the Sedulous engine using the Kenney Tower Defense Kit assets. Multiple tower types with upgrades, multiple enemy types, wave system, currency, UI, audio, particles, menus, and multiple maps.

## References
- **Engine patterns:** Code/Samples/EngineSandbox/src/SandboxApp.bf
- **FBX model loading:** Code/Samples/Showcase/src/ShowcaseApp.bf
- **GUI patterns:** Code/Samples/UI/LegacyUISandbox/src/
- **Messaging API:** Code/Foundation/Sedulous.Messaging/src/MessageBus.bf
- **Component pattern:** Code/Engine/Sedulous.Engine.Core/src/ComponentManager.bf
- **Assets:** Assets/samples/models/kenney_tower-defense-kit/

## File Structure

```
Code/Projects/TowerDefense/src/
  Program.bf
  TowerDefenseApp.bf

  Game/
    GamePhase.bf
    GameSubsystem.bf           -- ISceneAware: game state + injects all ComponentManagers
    MapSystem.bf               -- grid, tile entities, path (owned by GameSubsystem)
    WaveSystem.bf              -- spawn timer, wave progression (owned by GameSubsystem)
    TowerPlacement.bf          -- input utility for placing towers

  Messages/
    GameMessages.bf

  Map/
    MapCellType.bf
    MapData.bf

  Enemies/
    EnemyType.bf
    EnemyComponent.bf
    EnemyComponentManager.bf

  Towers/
    TowerType.bf
    TowerComponent.bf
    TowerComponentManager.bf

  Projectiles/
    ProjectileComponent.bf
    ProjectileComponentManager.bf

  Waves/
    WaveDefinition.bf

  Camera/
    TDCameraController.bf

  UI/
    HUDManager.bf
    TowerSelectionPanel.bf
    MainMenuUI.bf
    GameOverUI.bf

  Audio/
    GameAudioManager.bf

  Assets/
    ModelRegistry.bf
    ParticleEffects.bf
```

## Architecture

### Subsystems (2 total)
- **MessagingSubsystem** (-500) - drains message queue each frame (already exists in engine)
- **GameSubsystem** (-200) - ISceneAware. Owns game state (gold, lives, phase, wave tracking). Injects EnemyComponentManager + TowerComponentManager + ProjectileComponentManager into scenes. Owns MapSystem and WaveSystem. Subscribes to game messages, publishes state changes.

### ComponentManagers (per-scene, injected by GameSubsystem)
- **EnemyComponentManager** - waypoint movement, health, death/reach-end detection
- **TowerComponentManager** - targeting, weapon rotation, fire cooldown
- **ProjectileComponentManager** - homing movement, collision, damage application

### Plain classes (owned by GameSubsystem or TowerDefenseApp)
- **MapSystem** - builds tile entities from MapData, grid-to-world conversion, cell occupancy
- **WaveSystem** - wave definitions, spawn timer, wave progression
- **TowerPlacement** - mouse ray -> grid -> validate -> place tower
- **TDCameraController** - top-down camera with pan/zoom
- **ModelRegistry** - loads/caches Kenney FBX models
- **HUDManager / TowerSelectionPanel / MainMenuUI / GameOverUI** - UI screens
- **GameAudioManager** - loads clips, creates SoundCues, subscribes to messages
- **ParticleEffects** - defines and spawns particle effects

---

## Phase 1 - Dependencies & Foundations

Get the window open, assets loaded, map rendered, camera working.

- [x] **Program.bf** - entry point, instantiate TowerDefenseApp, call Run()
- [x] **TowerDefenseApp.bf** - inherit EngineApplication, OnStartup/OnUpdate/OnShutdown stubs
- [x] **BeefProj.toml** - add all engine dependencies
- [x] **GameMessages.bf** - define all IMessage structs (EnemyKilledMsg, WaveStartedMsg, TowerPlacedMsg, ResourceChangedMsg, GameOverMsg, ProjectileHitMsg, TowerShotMsg, GamePhaseChangedMsg, EnemyReachedEndMsg)
- [x] **GamePhase.bf** - enum: MainMenu, Playing, Paused, GameOver, Victory
- [x] **GameSubsystem.bf** - subsystem + ISceneAware. Game state (gold, lives, phase). OnSceneCreated injects EnemyComponentManager + TowerComponentManager + ProjectileComponentManager. Owns MapSystem and WaveSystem. Subscribes to EnemyKilledMsg (add gold), EnemyReachedEndMsg (lose lives), WaveCompletedMsg (advance wave). Publishes ResourceChangedMsg, GameOverMsg, GamePhaseChangedMsg. Public API: SpendGold(), AddGold(), Gold, Lives, Phase.
- [x] **ModelRegistry.bf** - load all Kenney FBX models at startup via ModelLoaderFactory, cache as StaticMeshResources, load colormap.png as shared PBR material
- [x] **MapCellType.bf** - enum: Empty, Path, TowerSlot, Blocked, Spawn, End
- [x] **MapData.bf** - grid definition (width, height, cell array), waypoints list, spawn/end positions. Static factories: CreateMap1(), CreateMap2()
- [x] **MapSystem.bf** - builds tile entities from MapData (tile model per cell type, rotated for path direction), GridToWorld/WorldToGrid conversion, CanPlaceTower/OccupyCell/FreeCell
- [x] **TDCameraController.bf** - top-down camera: WASD pan, scroll zoom, ~55 degree viewing angle
- [x] Wire up in TowerDefenseApp: register MessagingSubsystem + GameSubsystem, create scene, build Map 1, set up camera + directional light + sky
- [x] Verify: window opens, tiles render, camera pans and zooms

## Phase 2 - Enemies & Waves

Enemies walk the path, waves spawn them, they reach the end and cost lives.

- [x] **EnemyType.bf** - enum (UfoA, UfoB, UfoC, UfoD) + static stats table (health, speed, reward, model name)
- [x] **EnemyComponent.bf** - component: type, maxHealth, currentHealth, speed, reward, waypointIndex, distanceAlongPath
- [x] **EnemyComponentManager.bf** - update function: move toward next waypoint, advance index on arrival, publish EnemyReachedEndMsg at final waypoint, publish EnemyKilledMsg when health <= 0, destroy entity on death/arrival
- [x] **WaveDefinition.bf** - data: wave number -> list of (EnemyType, count, spawnInterval, delayBefore). Static definitions for 10+ waves with scaling difficulty.
- [x] **WaveSystem.bf** - owned by GameSubsystem. Spawn timer, tracks enemies alive (subscribes to EnemyKilledMsg/EnemyReachedEndMsg), publishes WaveStartedMsg/WaveCompletedMsg. Public API: StartWave(), IsWaveActive().
- [x] Verify GameSubsystem message subscriptions work with enemy/wave events
- [x] Test: enemies spawn at Spawn tile, walk path, reach End, lives decrease, waves advance

## Phase 3 - Towers & Combat

Place towers, they target and shoot enemies with projectiles.

- [x] **TowerType.bf** - enum (Ballista, Cannon, Catapult, Turret) + static data per level 1-3 (damage, range, fireRate, cost, upgradeCost, base/weapon/ammo model names)
- [x] **TowerComponent.bf** - component: type, level, damage, range, fireRate, cooldown, targetEntity, gridX, gridZ, weaponEntity
- [x] **TowerComponentManager.bf** - update: decrement cooldown, scan enemies for target (in range, pick furthest along path), rotate weapon toward target, fire when ready (publish TowerShotMsg, spawn projectile)
- [x] **ProjectileComponent.bf** - component: damage, speed, targetEntity, lifetime, age
- [x] **ProjectileComponentManager.bf** - update: home toward target, distance check for hit (apply damage, publish ProjectileHitMsg), self-destruct on lifetime or target lost (continue straight)
- [x] **TowerPlacement.bf** - mouse ray -> Y=0 plane intersection -> WorldToGrid -> validate CanPlaceTower -> SpendGold -> create tower entity hierarchy (base + body + weapon child entities) -> OccupyCell -> publish TowerPlacedMsg. Preview mesh follows cursor.
- [x] Wire TowerPlacement into TowerDefenseApp.OnUpdate
- [x] Test: place towers, they shoot enemies, enemies die, gold increases

## Phase 4 - UI

HUD, tower selection, menus. Reference LegacyUISandbox for widget composition patterns.

- [ ] **HUDManager.bf** - top bar panel: gold label, lives label, wave label. Subscribes to ResourceChangedMsg/EnemyReachedEndMsg/WaveStartedMsg to update. Uses LinearLayout with Labels.
- [ ] **TowerSelectionPanel.bf** - bottom panel: tower buy buttons (type name + cost), upgrade button, sell button. Sets selected tower type for TowerPlacement. Disables buttons when gold insufficient. Uses LinearLayout with Buttons.
- [ ] **MainMenuUI.bf** - fullscreen overlay: title label, "Start Game" button, map select buttons. Sets GamePhase to Playing on start.
- [ ] **GameOverUI.bf** - overlay: win/lose label, "Play Again" button, "Main Menu" button. Subscribes to GameOverMsg.
- [ ] Wire UI into TowerDefenseApp: create HUD on game start, show MainMenuUI initially, show GameOverUI on game over

## Phase 5 - Audio & Particles

Sound effects, music, visual polish.

- [ ] **GameAudioManager.bf** - loads audio clips, creates SoundCues with variation (shoot: shuffle + pitch 0.9-1.1, impact: random, placement, death, wave complete). Subscribes to TowerShotMsg/ProjectileHitMsg/TowerPlacedMsg/EnemyKilledMsg/WaveCompletedMsg, plays cues with 3D positioning.
- [ ] Background music via AudioSubsystem.PlayMusic() with looping
- [ ] **ParticleEffects.bf** - defines effects: explosion (enemy death), impact (projectile hit), build dust (tower placed), muzzle flash (tower shot). Spawns temporary particle entities at event positions.
- [ ] Wire particle spawning to messages

## Phase 6 - Second Map & Polish

- [ ] **MapData.CreateMap2()** - "Crystal Canyon" (14x10), winding path, crystal tile decorations
- [ ] Map selection in MainMenuUI
- [ ] Detail entities: scatter trees, rocks, crystals on empty tiles
- [ ] Tower upgrade: click placed tower to show upgrade/sell panel, swap weapon mesh on upgrade
- [ ] Wave countdown between waves ("Next wave in 5...")
- [ ] Enemy health bars (scaled quad or world UI above enemy)
- [ ] Balance pass: tower costs, damage, enemy health, wave composition
- [ ] Victory screen with stats (enemies killed, gold earned, waves survived)

---

## Message Flow

```
TowerComponentManager fires
  -> Queue(TowerShotMsg) + spawn projectile

ProjectileComponentManager hits enemy
  -> Publish(ProjectileHitMsg), apply damage to EnemyComponent

EnemyComponentManager detects health <= 0
  -> Queue(EnemyKilledMsg), destroy entity
  -> GameSubsystem: gold += reward, publish ResourceChangedMsg
  -> GameAudioManager: PlayCue3D(deathCue)
  -> ParticleEffects: spawn explosion

EnemyComponentManager detects reached end
  -> Queue(EnemyReachedEndMsg), destroy entity
  -> GameSubsystem: lives -= 1, check game over
  -> GameSubsystem.WaveSystem: decrement alive count

GameSubsystem.WaveSystem: all spawned + all dead
  -> Queue(WaveCompletedMsg)
  -> GameSubsystem: advance wave or victory
  -> GameAudioManager: PlayCue(waveCompleteCue)
```

## Design Decisions
- **Waypoint following** over NavMesh - deterministic paths fit tower defense
- **2 subsystems total** - MessagingSubsystem (engine), GameSubsystem (game state + ISceneAware, injects all ComponentManagers, owns MapSystem + WaveSystem)
- **ComponentManager per domain** - follows engine pattern, per-scene lifecycle
- **MessageBus for cross-system events** - decouples audio, UI, game state from gameplay
- **Tower entity hierarchy** - base + body + weapon as parent-child using transform hierarchy
- **Colormap.png shared material** - all Kenney models use one PBR material
