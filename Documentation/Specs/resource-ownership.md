# Resource ownership: what holds a loaded resource

Status: built (2026-11-19). Releasing unheld resources (Raptor 1ab3dd0f1, with its material fix
cdcc6b1a5 and e5f2cf164) is ported on top and on in the player and the editor.

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

Unheld for N collections (600 in the player and the editor), it is released: its product parked in the graveyard
for the frames in flight, then deleted, and its handle kept for the next bind. N = 0, a
manager's own default, never releases. The holders are asked each time it comes due, so a
resource a scene stops naming goes within N collections.

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

| Holder | Kept | Held by (built) |
|---|---|---|
| `MaterialFactory` / `ModelFactory` → `Material.SetDefaultTexture` | a texture's GPU view | a `ResourceHold` on the texture, kept by the material and its clones |
| `SoundCueFactory` → `SoundCueVariant.Clip` | the clip product | the dependency edge the cue's build records (rule 2) |
| `AnimationGraphSource.ResolveClip` → clip state nodes, blend tree entries | the clip product | the dependency edge the graph's build records |
| `BehaviorClassFactory` → `BehaviorClass.Assembly` | the assembly product | the dependency edge the class's build records |
| `ApplicationRun.mGameClass` | the game's script class | nothing: it is written and never read |
| `ScriptBehavior.BoundClass`, `ScriptSceneSystem.mLevelClass` | script classes | a hold per binding until it stops; the behaviours list and override assets are named by the script component and system |
| `GuiSubsystem` default and other fonts → font service | font products, atlases | an owner per font the service keeps (`SetFonts`) |
| `AudioEngine` registered and stream clips, voice slots, dying voices | clip products, encoded data | keyed by the clip's instance id; a played clip being destroyed stops its voices and drops its entries |
| `AudioSubsystem` voices by id or path, an audio source's voice | clip and cue products | a hold per voice until it ends |
| `AudioSubsystem.mCueOneShotState` | keyed by a cue's address | keyed by the cue's instance id |
| Skeletal and graph animation players, one-shot pose overlays | skeletons, clips, graphs | holds the component keeps beside its player, shifted on a cross-fade |
| IK links | the animator's player skeleton | read from the animator each frame, which holds it |
| `ParticleEffectComponent.AttachedResource` | the effect product | a hold until another attaches or the component goes |
| Mesh and material thumbnail generators | the product the stage draws | a hold while it is staged |
| `ModelInstance.Instantiate` | mesh, material, skeleton, clip products | no engine caller |

The editor's thumbnail generators and the pages that `SetDirect` a cooked product hold their
proxies for a page's life; they retain them already or are moved to.

### 3. Release

Ported on top: `ReleaseUnused` in the manager's collection, the material holding its textures'
owners, and the player collecting once a frame as the editor does. The player's and the editor's
managers release after `ResourceManager.cApplicationUnusedFrames` (600) collections and register
the live scenes as a holder (`Scene.HoldResources`); the editor's private managers (the model
library, an import preview) keep the default and never release.

## Tests

- Each holder: a resource it uses survives N + 1 collections with nothing else holding it.
- A scene's resources survive N + 1 collections while the scene is loaded, and are released within
  N collections after it unloads.
- A released resource bound again builds again.
- ASan over the release tests: a use-after-free in any holder is what this guards against.
