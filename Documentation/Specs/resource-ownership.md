# Resource ownership: what holds a loaded resource

Status: approved (2026-11-18), being built. Blocks releasing unheld resources (Raptor 1ab3dd0f1, with its material
fix cdcc6b1a5 and e5f2cf164), which stays unported until this lands.

## Why

The resource manager keeps every product it builds for its whole life, so a game that moves
between levels keeps every level's assets. Releasing what nothing holds needs a definition of
"held" that the engine actually maintains. Today it does not:

- A `Proxy<T>` holds a `WeakRef<ResourceHandle>`; `Retain` / `Forget` only move the weak count.
  Nothing outside the manager takes a strong reference, so a handle's strong count is always 1.
- The manager already reads "held" as `Control.WeakCount > 1` (`Purge`, `PurgeUnreferenced`,
  `ReportLiveProducts`), but no engine component calls `Retain` on the `Ref<T>` it stores (about
  45 fields across mesh, sprite, decal, camera, environment, post process, particles, the
  animators, one-shots, audio sources, script behaviours, colliders, navigation, terrain,
  vegetation and the GUI components). By that rule every resource a scene uses is unheld.
- Releasing a handle deletes its control block when the weak count reaches zero, so an
  unretained proxy then reads freed memory rather than null.
- Products and runtime systems keep raw pointers to other products, or to what those own.

## The rule

A resource is held while any of these is true:

1. Something outside the manager retains a proxy to it (`Control.WeakCount > 1`).
2. A loaded resource depends on it (an edge in the manager's dependents map).
3. It is pending (a load or a decode is in flight).
4. A holder registered with the manager names it (a loaded scene's components), asked when it
   would be released.

Unheld for N collections (600 by default), it is released: its product parked in the graveyard
for the frames in flight, then deleted, and its handle kept for the next bind. N = 0 never
releases.

## The pass

### 1. Holders say what they use

`Ref<T>` is a struct that is copied (a duplicated entity, a paste, a prefab, an undo step) and has
no destructor, so a retain inside it would be forgotten twice by two copies, or never. Component
references are not retained. Instead the manager asks at release time (ruling 2026-11-18):

- `ResourceManager.AddHolder` registers a holder; before a batch is released, each holder adds the
  ids it uses to a set, and an id in the set stays. A scene answers with the ids its components'
  `Ref<T>` fields name (lists of them too), read by reflection, so whatever re-pointed a reference
  (a script, an agent's `component_set`, the inspector, an undo) is seen without being told.
- A released resource's handle is KEPT, empty and Unloaded, and the next bind builds into it, so a
  reference that still points at it reads null, never freed memory.
- A proxy a product stores (a model's meshes, a terrain's layers) is held by the dependency edge its
  build recorded, rule 2; one stored elsewhere retains as before (rule 1).

### 2. Raw holders hold the owner, not the innards

Each keeps a retained proxy to the resource it reads (or is dropped and rebuilt when the
resource goes):

| Holder | Keeps today |
|---|---|
| `MaterialFactory` / `ModelFactory` → `Material.SetDefaultTexture` | a texture's GPU view |
| `SoundCueFactory` → `SoundCueVariant.Clip` | the clip product |
| `AnimationGraphSource.ResolveClip` → clip state nodes, blend tree entries | the clip product |
| `ScriptClassFactory` → `ScriptClass.Assembly` | the assembly product |
| `GameInstance.mGameClass` (set by the player and the editor's run) | the game's script class |
| `ScriptBehavior.BoundClass`, `ScriptSceneSystem.mLevelClass` | script classes |
| `GuiSubsystem` default and other fonts → font service, `CachedFont` and its users | font products, atlases |
| `AudioEngine` registered and stream clips, voice slots, dying voices; music clips | clip products, encoded data |
| `AudioSubsystem.mCueOneShotState` | keyed by a cue's address |
| Skeletal and graph animation players, IK links, one-shot pose overlays | skeletons, clips, graphs |
| `ParticleEffectComponent.AttachedResource` | the effect product |
| `ModelInstance.Instantiate` (no engine caller) | mesh, material, skeleton, clip products |

The editor's thumbnail generators and the pages that `SetDirect` a cooked product hold their
proxies for a page's life; they retain them already or are moved to.

### 3. Release

Port the release on top: `ReleaseUnused` in the manager's collection, the player collecting
once a frame as the editor does, and the material holding its textures' owners.

## Tests

- Each holder: a resource it uses survives N + 1 collections with nothing else holding it.
- A scene's resources survive N + 1 collections while the scene is loaded, and are released N
  collections after it unloads.
- A released resource bound again builds again.
- ASan over the release tests: a use-after-free in any holder is what this guards against.
