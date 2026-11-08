# Prefabs as loadable resources

> Status: DESIGN AGREED 2026-11-08, commit plan awaiting review. Rulings: prefabs become loadable resources (a reference to a prefab
> binds to a real prefab, and spawns stop re-reading it from disk), chosen over skipping documents
> when binding and over an id-only prefab reference; the editor's document and the runtime prefab
> are separate types; the cache never serves what is no longer on disk. The design was reviewed
> with Raptor's session, which found two more problems and seven changes, all agreed (2026-11-08).

## Today (master fb489b71e)

- `Ref<T>.Bind` goes through `ResourceManager.Bind<T>`/`BindAsync<T>`
  (`Foundation/Sedulous.Resource/src/Ref.bf:66-77`), which looks the id up in the manager's one
  database and builds through the factory for its product type ("no content instance",
  `ResourceManager.bf:568`; "no factory registered", `:578`). `Proxy<T>.Get` casts the product to
  `T`, so a `Ref<PrefabDocument>` needs a `PrefabDocument` product. `Reload(id)` rebuilds a handle
  and its dependants; nothing purges.
- The cook skips scenes and prefabs: no builder, counted `Unbuildable`
  (`Pipeline/Sedulous.Pipeline.Cook/src/CookDriver.bf:189-193`); a builder needs an `Asset`, and
  `PrefabDocument` is not one.
- Every spawn reads the prefab, and every nested one, from the content database and parses it
  (`Foundation/Sedulous.Scene.Resource/src/PrefabSpawnSystem.bf:62-91`, `PrefabSpawn.bf:37-40`).
- Where each host reads:
  - Editor: the resource manager reads `CookedDb` (`Editor/Sedulous.Editor.App/src/EditorSession.bf:447`),
    the spawners `SourceDb` (`:215`, `DefaultApplication.bf:295,981`): a prefab spawns by id, a
    `Ref<PrefabDocument>` fails ("no content instance").
  - Exported player: everything reads the pak, which holds each prefab as a binary
    `PrefabDocument` record (`ExportStaging.StageScene`); a ref fails ("no factory").
  - Player run from a project folder: the spawners are given the cooked database
    (`DefaultApplication.bf:295` with `Engine/Sedulous.Engine.Player/src/PlayerApplication.bf:99`),
    which has no prefabs, so script `Spawn`, `Net.Spawn` and the network's spawn resolver find
    nothing. Placed prefabs work because scene loads read the sources (`:183`). A bug (read, not
    run).
  - Export: prefabs transcoded to binary (`SceneExportSupport.CollectSceneStreams`); reachability
    already follows `Ref` fields, behaviours' included (`SceneExportSupport.bf:58-71`).
- Prefab writes (apply-to-prefab, model regeneration, MCP `prefab_write`/`asset_data_write`) end in
  `EditorContext.NotifyAssetExternallyModified` (`EditorContext.bf:573`); a prefab page's `Save`
  (`SceneEditorPage.bf:838`) notifies nothing. Only `Sources/` is watched for outside changes.

### The problems

- (a) A reference to a prefab cannot bind: no factory makes a prefab, and the editor's resource
  manager does not see prefab records.
- (b) Every spawn reads and parses the prefab and its nested prefabs again, and so does every scene
  load, once per placed instance: `ScenePrefabs.ResolveScenePrefabs` calls its resolver for each
  pending instance with no reuse (`ScenePrefabs.bf:23-45`), so a level with 50 of one prefab reads
  it 50 times.
- (c) A game run from its project folder cannot spawn prefabs: its spawners read the cooked database.
  Its scene loads read the sources (`DefaultApplication.bf:300-301` with `PlayerApplication.bf:183`).
- (d) Outside edits are not seen: the editor watches only `Sources/`, and a `ContentDatabase` scans its
  mount once, at construction (`ContentDatabase.bf:52`), so a pulled new prefab or scene is not in
  it, a pulled delete still is, and an open page stays stale; a later save overwrites the pull.
- (e) A pruned export follows what a scene binds and the prefabs it places
  (`ExportDriver.ExpandReachableRoots`), not a script's asset properties
  (`ScriptSceneSystem.ResolveResources` binds only the level script, `:116-119`), so a prefab named
  only by a script property can be left out. By reading; not run.

## Decisions

### 1. Where a prefab comes from: a resource factory over a layered database, not a cook builder

A `PrefabFactory` in `Sedulous.Scene.Resource` (declared in `SceneResources.Module`): its stored
type is the `PrefabDocument` record, its product a separate runtime `PrefabResource` (decision 2),
read from the instance's `scene` stream, as `TerrainFactory` makes a `TerrainResource` from a
stored `TerrainSource`. Not a cook builder: that
would make the document an `Asset`, collide in the pak with the copy the export stages, cook on
every save, and could not transcode (the cook does not link every scene manager).

- Editor (edit, Simulate, Play): the manager reads a new `LayeredContentDatabase(CookedDb,
  SourceDb)`: cooked products first; a record falls through to the sources only when the factory
  registered for its stored type declares that type an authored record (a capability on
  `IResourceFactory`, which `PrefabFactory` declares). The view names no type: the next authored
  record type joins by declaring it, and a source texture envelope never reaches the texture
  factory. `EditorProject` owns it.
- Exported player: unchanged (the pak already holds binary prefab records).
- Project-folder player: builds the layered view once and gives it to everything (the resource
  manager, the spawners, the scene loads) in place of its split source and cooked databases. This
  fixes (c).
- Cook, export, headless tools: unchanged; prefabs and scenes stay `Unbuildable` in the counts.

### 2. The runtime resource

- The product is `PrefabResource`, a runtime type of its own (ruling: the editor's document and
  the runtime stay separate): its `Id`, its name and the `Payload` bytes (the binary stream), with
  `OpenPayload()`. `PrefabDocument` stays the authoring record, unchanged; nothing at runtime holds
  one. A field naming a prefab is a `Ref<PrefabResource>`, its picker offering prefab documents
  (commit 7 maps the product to its stored type). No data version moves: a field stores the guid
  either way.
- Its effect on x2: the samples' prefab fields (Lamplight's `Thief.Pebble`, Snowline's
  `Board.TrackMark`) change type from `Ref<PrefabDocument>` to `Ref<PrefabResource>`; their stored
  guids read unchanged.
- Bytes, not a parsed form: a spawn still assigns fresh ids, remaps references and records each
  instance's baseline (`PrefabSpawn.bf:254-300,389-410`); the costs were the disk and the XML. The
  type stays opaque (`OpenPayload()`), so a parsed template later (records split, the id map
  precomputed) changes no caller; measured first with Snowline's track marks.
- Nested prefabs stay references, each its own cached handle, resolved through the manager, so an
  edit of the inner prefab reaches every placement with no dependency link. A depth limit refuses
  a prefab that nests itself (a bad edit) instead of recursing.
- The factory loads asynchronously: decode on a worker (the stream's bytes), finalize on the main
  thread, where a text stream is transcoded to binary when the host offers a `SceneComposer`
  service (registered by `DefaultApplicationFactories` with every scene manager); without it the
  text is kept. The transcode keeps a record whose manager is absent (a plugin not loaded)
  verbatim, as a scene load does.
- Spawning never waits on an async load: a spawn (by id or by reference) of a prefab not yet loaded
  binds it synchronously, so the first spawn arrives in its own frame. The replicated-spawn
  resolver depends on it: the entity must exist in the frame its message arrives, or the next
  replication state names nothing.
- Scripts keep spawning by guid: `Spawn(Guid)` binds through the manager; no script API changes.
- Memory: a few KB per prefab used, owned by the manager, gone with it; a reload swaps it. Two spawns
  of one prefab may differ across a reload during Play (the docs say so). Releasing unreferenced
  prefab handles on a level change: later, if a game needs it.
- `PrefabSpawnSystem`: `SetSource(ResourceManager)`; `Spawn(Guid, ...)` keeps its signature
  (script `Spawn`, `Net.Spawn` and x2 compile unchanged) and binds through the manager;
  `Spawn(Ref<PrefabResource>, ...)` uses the bound prefab or binds it at once; one recipe,
  `SpawnInto`, spawning from the loaded payload and resolving nested prefabs through
  `PrefabPayloads.Resolver(resources)`, which runtime scene loads use too. Editor authoring
  (pages, thumbnails, apply, rebuild, MCP `prefab_spawn`) keeps reading the sources.

### 3. The cache never serves what is no longer on disk

Ruling: a prefab changed or deleted outside the editor must not keep spawning from the cache.

- The database first: a `ContentDatabase` refreshes a changed, added or removed record (re-read,
  add, drop) before anything is told, so a pulled new prefab exists and a pulled delete is gone.
- The watcher: `Content/` is watched beside `Sources/`, through the operating system's change
  notification where the mount has one, else a stat sweep about once a second and on the window
  regaining focus (a pull nearly always happens while the editor is unfocused). `Content/` is far
  bigger than `Sources/`, so never a sweep per tick.
- Settled and batched: a file is read only once it is stable (the same size and time over two
  looks), and a sweep's changes go out as one notification per asset, so a pull of hundreds of files
  neither reads half-written XML nor reloads a page hundreds of times.
- The editor's own writes are not outside changes: what the editor wrote (size and time) is
  recorded and a matching change skipped. Otherwise every save would come back and reload its
  clean page, clearing its undo history (`SceneEditorPage.bf:866`).
- Then the notifications: a changed record through `NotifyAssetExternallyModified` (its open page
  reloads, or warns with unsaved edits; its cached prefab reloads), a removed one through a new
  deleted-asset notification (its open page says so; its cached prefab is evicted). Edits made in
  the editor already notify; a prefab page's own `Save` reloads its cached prefab.
- Evict: `ResourceManager.Evict(id)` marks the handle Failed and frees the product after the frames
  in flight, keeping the handle registered, so a held reference reads unbound and a record that
  comes back under the same id revives that handle through `Reload`. A spawn of an evicted prefab
  refuses with the warning a missing prefab gives today.
- The project-folder player reads its files once at start, as today; it is not an editor.

### 4. Scenes: never loaded through a reference

A scene is read once per level load, so caching its bytes saves nothing and would hold whole
levels in memory. A field naming a scene (a level exit) is its own kind of reference, an id typed
for scenes that never binds (not a `Ref<T>`), which `LoadScene` takes. The binder needs no special
case, and the picker and the export still see what it names. Scene pages get the watcher of
decision 3.

### 5. Script asset properties are export references

A script property holding an asset id (a prefab, a clip) is followed by a pruned export like a
bound reference, fixing (e). On master; on x2 the native fields are references already.

## Commits

Each builds and passes its tests; every new test also under `Code/Tools/asan-test.py`. No new MCP
tool and no data version change.

First, the fixes that stand alone:

A. `Player: a game run from its project folder spawns prefabs`: its spawners read the database its
   scenes load from; fixes (c) (DefaultApp.Tests or Player tests; CHANGELOG Fixed). Commit 4 then
   gives it the layered view for everything.
B1. `Content: a database refreshes a changed, added or removed record`, settling a half-written
   file (Content.Tests: add, change, delete, a file not read until settled).
B2. `Editor: Content/ is watched, so an open scene or prefab follows its file`: OS notification or
   a slow sweep plus focus-in, batched, the editor's own writes skipped, the deleted-asset
   notification (Editor.Project.Tests, Editor.Scene.Tests; CHANGELOG Fixed).
C. `Export: a script's asset properties are references`: fixes (e) (Integration.Mcp or
   Editor.Project.Tests: a prefab named only by a script property is in a pruned export).

Then the resources:

1. `Content, Resource: a layered database, and a factory that reads an authored record`:
   `LayeredContentDatabase` and the capability on `IResourceFactory` it follows (Content.Tests,
   Resource.Tests).
2. `Scene.Resource: a prefab is a resource`: `PrefabResource`, `PrefabFactory`, `PrefabPayloads`,
   the depth limit (Scene.Resource.Tests `PrefabResourceTests`; Engine.Composition.Tests factory
   counts 30 to 31 and 28 to 29).
3. `Resource: an evicted resource reads unbound` (`ResourceManager.Evict`; Resource.Tests).
4. `Editor, Player: resources see the prefabs, and an edit or a delete reaches them`: the layered
   view in the editor and, for everything, in the project-folder player; `Reload` and `Evict` from
   the notifications and a prefab page's save (Editor.Core.Tests, Editor.Scene.Tests,
   DefaultApp.Tests).
5. `Scene: spawns come from the loaded prefab`: the spawn API, a synchronous first bind, its callers
   (Scene.Resource, GameInstance, GameScript and DefaultApp.Integration tests: a disk overwrite
   after the first spawn changes nothing until a reload; a delete refuses the next spawn; the
   replicated spawn arrives in its frame); Assets.md, Scenes.md, McpGuide.md; CHANGELOG.
6. `Scene loads place prefabs from the loaded prefab`, one read per prefab however many are placed
   (GameInstance.Tests, Editor.Play.Tests).
7. `Scene.Resource: a text prefab loads in the binary format`, keeping a record whose manager is
   absent (Scene.Resource.Tests, DefaultApp.Tests).
8. `Editor.Mcp: a prefab field picks prefab documents` (`SceneReference.SourceAssetTypesFor` maps a
   product no builder makes to the type its factory reads; Integration.Mcp SceneReferenceTests).
9. `Scene: a scene reference is an id that never loads` (the scene id type, its picker and export
   edge; Scene.Tests, Integration.Mcp).
10. On x2: the samples' prefab fields become `Ref<PrefabResource>` (Gameplay.Tests, Integration.Mcp).

## Open questions

1. The editor's prefabs from a layered database view (recommended) or from a cook builder. - should be okay
   **Ruled: the layered view.**
2. The product: runtime fields on `PrefabDocument` (recommended) or a runtime subclass. - editor and runtime must stay separate. Discuss how this impacts.
   **Ruled: separate.** A runtime `PrefabResource` built from the `PrefabDocument` record, as
   terrain does (decision 2). The impact: prefab fields are `Ref<PrefabResource>` (two x2 sample
   fields change type, their data unchanged); the picker maps the product to its stored type
   (commit 7); `PrefabDocument` is untouched.
3. Transcode a text prefab to binary when it loads in the editor (recommended: Snowline drops a
   track mark every 1.5 m), or keep the text. - sure. **Ruled: transcode.**
4. Outside edits to `Content/` while a project is open (a git pull) leave a stale prefab until it
   is saved again or the project reopens. Recommended: accept, note it in KnownIssues.  - not really acceptable.
   **Ruled: not acceptable.** `Content/` is watched (decision 3), which also reloads stale open
   pages.
5. A deleted prefab still spawns from the cache until the project closes. Recommended: accept. - not really acceptable.
   **Ruled: not acceptable.** A delete evicts it (decision 3).
6. Loading a prefab's own meshes and materials when it binds, against a first-spawn hitch.
   Recommended: not now; measure after the samples use it. - sure. **Ruled: not now.**
7. Editor authoring keeps reading the sources. Recommended: yes. **Ruled: yes.**
8. The project-folder player's spawn bug fixed here. Recommended: yes. **Ruled: yes** (commit A).
9. Raptor: the design is Sedulous-first; Raptor mirrors it, as it did the editor lists. - discuss the problem and design with Raptor and let's come up with the best solutions.
   **Done 2026-11-08:** reviewed with Raptor's session over the whole design; its two added
   problems (b's scene loads, e) and seven changes are folded in above and agreed. Raptor has all
   five problems ((c) wider there: its scripted scene loads read the cooked database too).
