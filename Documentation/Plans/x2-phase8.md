# x2 phase 8: hot reload, studied

**Status:** study, 2026-11-10 (phase 8 item 1). Nothing here is built or run. The spike (item 2) and
the decision (item 3) are below for the user to rule on.

This note covers two existing hot reload mechanisms for Beef:
- **Tallow's**, which an engine drives itself: `~/Dev/Beef/Tallow`, and `~/Dev/Beef/Tallow-ecs`,
  which differs in one file.
- **The Beef IDE's hot compile**, which the IDE's compiler and debugger drive: `~/Dev/Beef/Beef`, a
  checkout of the fork's `working` branch.

It then says what each would mean for Sedulous's x2 model, sets out the alternative (a faster
relaunch that keeps the editor's state), proposes the spike, and makes a recommendation.

Paths are relative to the root of the tree named: `Tallow/`, `Beef/`, or this repository.

## Recommendation (first)

1. **Build the fast relaunch now, whatever else is decided.** It is the fallback in every case:
   Tallow and the Beef IDE both refuse some changes and fall back to a restart. Most of the
   state it needs to keep is already saved: open pages, and each scene page's camera, selection
   and panes. The work left is:
   - one action that builds and then relaunches;
   - unsaved scenes kept in a stash rather than prompting;
   - the Game tab reopened and set playing again.

   It is engine-side work in code we own, with no dependence on Beef internals.
2. **Next, spike the Beef IDE's hot compile on a project's own editor (Linux, through LLDB).**
   - For method bodies it is the strongest mechanism of the two. It patches the entry of each old
     function, so every caller reaches the new code, including old delegates, vtables and
     function pointers.
   - It needs no engine code at all: the developer runs `<Game>Editor` under the IDE.
   - It refuses a field change to a type that has live instances, which is the common case for a
     Behaviour. The fast relaunch covers that.
   - If the spike passes, it becomes the documented loop for a person at the keyboard: edit,
     hot compile, keep playing.
3. **Do not adopt Tallow's mechanism yet.** It is the only one of the two that takes a field
   change on live components without a restart. It does so by rewriting reflection metadata in
   place, patching machine code and editing ELF objects, against Beef's private runtime layout.
   Sedulous's game code also leans on engine generics specialized over game types
   (`BehaviourManager<T>`, `InstallManager<T>`, `CreateGame<T>`), which Tallow's design avoids.
   Spike it only if the relaunch and the IDE's hot compile both prove too slow in practice.
   Step 6 of the spike measures what it would cost on SkyHopper.

## Tallow: how its reload works

There are three parts:
- the editor, `Editor/src/Scripts/ScriptReloadEditor.bf`;
- a build tool, `tools/reload_scripts.py`;
- the engine side, `Engine/src/Scripting/ScriptReload.bf`, `ScriptReloadStructural.bf`,
  `ScriptStateMigration.bf`, and `ScriptReloadWindows.bf` for Windows.

The user guide is `docs/script-hot-reload.md`.

In Tallow, as in x2, the game's project is the editor executable: the generated BeefProj has the
startup object `<Game>.Program` and depends on `Tallow` and `TallowEditor`
(`Editor/src/Project/Project.bf:311-322`).

### 1. The host is prepared (once per session)

- **Linux.** The Debug editor is linked with `-rdynamic`, so every symbol in it is visible to a
  library loaded later (`Project.bf:323`; `docs/script-hot-reload.md:35`). Release is linked
  without it.
- **Windows.** The editor is linked with `/MAP` (`Project.bf:335-336`). At startup it reserves an
  address range just below its own image for script libraries (`ScriptReloadWindows.bf:31-52`).
- **The baseline.** `InitializeScriptReload` runs `reload_scripts.py --snapshot`
  (`ScriptReloadEditor.bf:22-61`). The snapshot records:
  - a digest of the resident code: the engine's and editor's `.bf` files, the native sources,
    `BeefSpace.toml`, `BeefProj.toml` and every other library in the workspace
    (`reload_scripts.py:59-78`);
  - on Linux, every defined symbol of the built editor with its size (`nm -g -S`; 605-611 and
    131-138).

### 2. A change is noticed and compiled

- **Watching.** The editor polls the project folder every 500 ms and debounces changes for
  350 ms. The script build then runs on a worker thread (`ScriptReloadEditor.bf:69-112`). Saving
  in the Scripts tab, or Rebuild & Reload, also queues one (`EditorBuild.bf:12-21`).
- **Refusals.** The tool refuses with exit 3 if the resident digest changed: "Engine, editor,
  build configuration or resident library changed. Use File > Full Rebuild & Restart"
  (`reload_scripts.py:612-615`).
- **The shadow workspace.** It builds a shadow workspace,
  `.tallow-reload/<session>-workspace` (619-633):
  - its `src` is a symlink to the project's `src`;
  - its `BeefSpace.toml` lists the same projects by absolute path;
  - its `BeefProj.toml` is the project's own with `BuildKind = "DynamicLib"` added to
    `[Configs.Debug.Linux64]`.

  BeefBuild compiles it in Debug. This is a **whole-workspace compile in a build directory of its
  own**: the engine's objects are built there too, from scratch the first time and incrementally
  after that.
- **Edits during the compile.** If the sources changed while it compiled, the tool refuses with
  exit 4, so a mixed revision is never activated (636-639).

### 3. The library is linked against the running host (Linux)

- **The objects.** The tool reads BeefBuild's `ObjectArgs.txt`. It keeps only the `.o` files
  (`libBeefRT.a` and the other archives are left out) and tells the game's own objects from the
  engine's (640-646).
- **Classes.** The game's classes are the `sBfClassVData` symbols in `vdata.o` whose type lives
  in a game object file (647-657).
- **Static fields.** A game static that the host already has (in its exports, with a size above
  zero) is "shared". If its size changed, the reload is refused: "Static field layout changed;
  change its name or full rebuild" (659-663).
- **Aliasing** (`alias_host_globals`, 94-128, applied at 664-672). Every object is rewritten so
  that symbols the host already has become *undefined*. Where that symbol was a function, its
  body is filled with NOPs and its relocations zeroed.
  - In engine objects this covers every resident symbol. Only code the host lacks stays defined,
    such as a generic specialization new to the game (comment at 669-670).
  - In game objects it covers only the shared statics, so the game's new code stays defined.
- **Metadata renames.** In `vdata.o`, every resident `sBfTypeData` (the reflection `Type` objects)
  and every resident `sBfClassVData` that is not a game class is renamed to
  `reload_private_<name>` with `objcopy --redefine-syms` (673-683). So the library carries its
  **own private copy of the type table** and is not bound to the host's.
- **The link.** `c++ -shared -Wl,-Bsymbolic` (684). `-Bsymbolic` binds the library's calls to
  its own new definitions. Its undefined symbols (the engine, the Beef runtime, the shared
  statics) bind to the editor through `-rdynamic` when it is loaded.
- **The library never initializes a Beef runtime of its own.** None is linked in, so it runs on
  the host's. That is why it works where our DynLib spike failed:
  `~/Dev/Beef/Spikes/DynLib/FINDINGS.md`, finding 3, found that a plugin's own startup never runs.
- **The manifest.** It names the library, `mode structural`, each class with its size, and each
  shared static (685-692).

### 4. The library is applied at a frame boundary

`FinishScriptReload` calls `ScriptReload.Apply(manifest, error, scene)`
(`ScriptReloadEditor.bf:114-128`). It clears the component field cache and dispatches to
`ApplyStructural` (`ScriptReload.bf:345-357`). The structural path
(`ScriptReloadStructural.bf:238-385`) runs these steps:

1. **Open the library.** `dlopen(path, RTLD_NOW|RTLD_GLOBAL)` (258), and look up the library's
   own `Type.sTypes` and `sTypeCount`, and the host's `Type.GetType(TypeId)` and `Type.GetType_`
   (`ScriptReload.bf:175-204`).
2. **Hook type lookup.** Once per session, the first 12 bytes of the host's two `GetType`
   functions are overwritten with `mov rax, imm64; jmp rax`. The jump goes to
   `ResolveReloadType`, which indexes `sCanonicalTypes`, a list that can grow
   (`ScriptReloadStructural.bf:78-122`; the list, 46-64).
   - From then on the host resolves type ids through that list, so new types get ids.
   - Engine code that enumerates types has to walk `ScriptReload.ReflectedTypes` rather than
     `Type.Types`: `DataAsset.bf:187,200` and `TerrainGenerator.bf:123,136` do.
3. **Name the library's types.** The library's metadata objects are of its own reflection
   classes, so the host cannot cast them. For a moment the resident `System.Reflection` classes
   take the library's inheritance ranges (`BorrowReflectionRanges`, 449-477). Each library type's
   key is read (full name, metadata kind, and parameter count for an open generic; 388-447), and
   the ranges are put back (294-310).
4. **Match by name.** Each library type is matched to the resident type of the same key, or gets
   a new id after the last one (312-345).
   - A specialization whose generic argument prints as `???` (a lambda's `Sorter`, say) is told
     apart by its size (401-418).
   - A resident type that is **not** a game class but whose instance size changed is refused:
     "Resident layout changed ... Full rebuild required" (337-341).
5. **Capture the scene** (`ScriptStateMigration.Capture`, `ScriptStateMigration.bf:42-84`):
   - every component's object-reference fields, so references can be remapped;
   - for each instance of a game class: its owner, its index, its enabled, Awake and Start flags,
     and every supported field as text through `SceneSerializer.WriteValue`, private fields
     included (`ComponentRegistry.GetFields(..., true)`).

   Tallow-ecs also writes each object's data components as text first and reads them back last
   (`Tallow-ecs/Engine/src/Scripting/ScriptReloadStructural.bf:347-367, 393, 401-403`).
6. **Remap the library's metadata into the host's ids** (`RemapType`, 159-235; called at 353-362):
   - the type id, boxed id, base, underlying and outer types;
   - generic arguments, field types and method return and parameter types;
   - interface entries and attribute blobs (144-157);
   - the type ids in each ClassVData header.

   The pages are first made writable with `mprotect`, after their protection is read from
   `/proc/self/maps` (`ScriptReload.bf:117-173`; `MakeModuleDataWritable`, 513-533).
7. **Commit** (`CommitUpdates`, 535-560):
   - **A game class:** the resident `TypeInstance` is overwritten whole with the library's
     (`MemCpy` of `TypeInstance.InstanceSize`, 545-548). Its instance size, ClassVData (vtable),
     fields, methods and constructor are now the new ones, under the old `Type` identity.
   - **Any other type:** it takes only the library's inheritance range, which `is` casts compare,
     written into the type and into its ClassVData at offset 8 (550-557).
   - New types are appended to `sCanonicalTypes` (365-372).
8. **Refresh the registry.** `ComponentRegistry.Refresh()` rebuilds the list of component types
   and drops the data asset cache (`ComponentRegistry.bf:98-107`).
9. **Replace the instances** (`ScriptStateMigration.Restore`, `ScriptStateMigration.bf:96-173`):
   - A fresh instance of each captured component is made through
     `ComponentRegistry.Create(type)`, that is `type.CreateObject()` on the overwritten resident
     type (`ComponentRegistry.bf:131-140`).
   - It takes the old one's flags and slot, so Awake and Start do not run again.
   - Fields are restored when name, kind and type name all match.
   - References are remapped to the replacements, and `OnValidate` runs.
   - **The old instance is retired, not deleted** (`ScriptReload.Retire`,
     `ScriptReloadStructural.bf:37-41`), because old delegates may still point at it.
10. **Record the generation.** The library stays loaded: it is kept in `mModules` and never
    closed (`ScriptReload.bf:8-9, 406`; `ScriptReloadStructural.bf:375-377`). Then
    `reload_scripts.py --commit` adds its exports to the baseline, so the next generation binds
    to them (`reload_scripts.py:599-604`; `ScriptReloadEditor.bf:129-142`).

**About "the vtables copied over".** That describes the older, non-structural path in `Apply`
(`ScriptReload.bf:358-409`):
- it requires an identical type set and identical layouts (`ValidateTypes`, 63-115;
  `ValidateClass`, 213-251);
- it then copies each class's new ClassVData over the host's and repoints each `MethodData`
  function pointer (397-405).

The Linux tool now always writes `mode structural` (`reload_scripts.py:685`), and so does the
Windows tool (530), so that path is reached only by a manifest without that line.

### What happens to each kind of thing (Linux, structural)

- **Live game components** are replaced by new instances with migrated fields (step 9).
- **Other live objects of game classes** (a plain class held in a list or a static, say) are not
  migrated. Their object header still points at the old ClassVData, so virtual calls run the old
  code. But the type id in that header now resolves to the overwritten `Type`, which describes
  the new layout (steps 2 and 7), so reflection over such an object reads the wrong layout. The
  reload code has no step for them: `Capture` walks only `scene.Components`
  (`ScriptStateMigration.bf:45`).
- **Statics** that existed before keep the host's storage and their values; a size change is
  refused (`reload_scripts.py:659-663, 671`). New statics live in the library. Nothing in the
  reload code runs a static constructor, and our DynLib spike found that a Beef library's
  startup does not run (`FINDINGS.md`, 3). So whether a *new* static's initializer runs is
  **unknown**: the spike checks it (step 4).
- **Delegates and function pointers** created before the reload still point at old code, in the
  host or in an older library. Libraries are never unloaded and retired components never deleted,
  so those calls do not crash, but they run old code against old objects
  (`ScriptReload.bf:8-9`; `ScriptStateMigration.bf:165-172`).
- **Strings and corlib state.** Corlib's objects are among the engine objects whose resident
  symbols are aliased to the host's (`reload_scripts.py:669-671`), so corlib's statics, including
  any intern table, are the host's. The library's string literals are its own objects. Their
  `String` ClassVData is the library's private renamed copy, whose type ids are remapped (step 6)
  and whose methods are aliased to the host's. The reload code has no step of its own for
  literals.
- **Generics.**
  - A specialization the host already has keeps the host's code: engine objects alias every
    resident symbol (`reload_scripts.py:669-671`).
  - A new one is compiled into the library.
  - Type matching handles `???` arguments by size (`ScriptReloadStructural.bf:401-418`).
  - A game struct (no ClassVData, so not a "script" class) whose size changes is refused at
    337-341, which keeps the host's generic code over it consistent.
- **New types, methods and fields** in game classes are taken: the whole `TypeInstance` and its
  vtable are the library's (step 7), and new types get new ids (step 4). New virtual methods work
  for the *replaced* component instances only.
- **Comptime and reflection data** are compiled fresh in the library and remapped (step 6).
  Attribute changes such as `HideInInspector` take effect because the field cache is cleared
  (`ScriptReload.bf:347-350`; `docs/script-hot-reload.md:19`).

### Tallow's limits, and how it fails

- **Debug, x86-64, Linux and Windows only** (`#if (BF_PLATFORM_LINUX || BF_PLATFORM_WINDOWS) &&
  BF_64_BIT`, `ScriptReloadStructural.bf:77, 240, 381-383`).
  - The `GetType` hook is x86-64 machine code (110-119).
  - Windows is a second linker scheme: `lld-link` at a fixed address against a stand-in object
    built from the `/MAP` file, with the editor copying the sections in itself
    (`reload_scripts.py:141-553`; `ScriptReloadWindows.bf`). Its reserved range can fill up and
    then demands a restart (`reload_scripts.py:515-516`).
- **Resident changes are refused:**
  - an engine, editor, native, workspace or project file, or any other library (exit 3);
  - a static whose size changed;
  - a non-game type whose size changed (above).
- **State migration covers only the supported field kinds** on scene components. Private
  containers, arbitrary object graphs, coroutines and tasks, native delegates and custom
  registration lifecycles get nothing, and references outside the supported fields are not
  retargeted (`docs/script-hot-reload.md:25`).
- **Memory grows with each reload.** Old libraries and retired components stay for the session
  (`docs/script-hot-reload.md:25`).
- **Beef internals.** It depends on Beef's private layout: `[Friend]` fields of `TypeInstance`,
  `MethodData` and `FieldData`, ClassVData header offsets, `sTypes`, and mangled names
  (`ScriptReload.bf:65-68`; `ScriptReloadStructural.bf:124-131, 556`). A Beef update can break it
  silently.
- **How it fails.**
  - A compile failure, a refused change or a validation error leaves the previous code running,
    with the reason in the console and status bar (`ScriptReloadEditor.bf:114-128`;
    `docs/script-hot-reload.md:27`).
  - Validation all runs before the first write to the running program, but `CommitUpdates` can
    still fail on `mprotect` after earlier types were overwritten (`ScriptReloadStructural.bf:537-560`),
    and that would leave a mixed state.
  - The docs mention a six-generation fixture (`docs/script-hot-reload.md:29`), but I found no
    such test in this Tallow tree.

## The Beef IDE's hot compile

### What triggers it, and what it needs

- **The trigger.** A compile while the IDE's debugger runs the program compiled by that IDE is a
  hot compile ("Hot Compiling...", `IDE/src/IDEApp.bf:4966-4972`).
- **The compiler state.** It needs the IDE's own long-lived compiler, which keeps `HotData`
  between compiles: method versions, type versions and data hashes
  (`IDEHelper/Compiler/BfCompiler.cpp:7211-7232`). A hot compile fails unless the program was
  built with hot swapping allowed: "Hot Compilation is not enabled" (7226-7231).
- **The setting.** Hot swapping is the workspace option `AllowHotSwapping`. It defaults on for
  Windows Debug and **off on every other platform**, but a workspace can set it
  (`IDE/src/Workspace.bf:1124-1135, 906, 1250`). Turning it on also changes the build:
  - classes get a vtable extension slot (`mHasVDataExtender = mAllowHotSwapping`,
    `BfCompiler.cpp:11379`; `BfModuleTypeUtils.cpp:6789-6797`);
  - dynamic casts take a slower checking path (`BfModule.cpp:11389`).
- **BeefBuild has no hot compile:** nothing in `BeefBuild/src` names it.

### How it reloads

- **The compile.** The compiler emits objects for the changed modules only. The IDE hands them
  to the debugger (`mDebugger.HotLoad(entries, hotIdx)`), then commits the compile
  (`HotCommit`, `IDEApp.bf:12401-12425`).
- **Windows.** `WinDebugger::HotLoad` handles it (`IDEHelper/WinDebugger.cpp:986`).
- **Linux, in this fork.** `LLDBDebugger` implements it (`IDEHelper/LLDBDebugger.cpp:7576-7591`,
  the design comment):
  - It maps an RWX region in the target within rel32 reach of the executable (8002-8005).
  - It loads the ELF relocatable objects into that region and applies their relocations.
  - It writes a `jmp` over the entry of each replaced function's *canonical* definition (the
    executable's).
  - Code references therefore always enter through the old entry and reach the newest version,
    and data references keep the original storage, "so static state survives the swap".
  - The batch is journaled and undone on failure (`HotLoadBatch`, 9579-9694).
  - `GDBDebugger`'s hot load is an empty stub (`GDBDebugger.cpp:2927-2933`).
  - Whether upstream Beef carries the LLDB path I did not check: this checkout is the fork's
    `working` branch.
- **Type tables and vtables** are updated in place (`HotApplyDataFixups`, `LLDBDebugger.cpp:9357-9430`,
  following `DbgModule::ProcessHotSwapVariables`):
  - A vtable is merged word by word: "the table can't grow in place (new virtuals go through
    extension tables)".
  - Type data is copied only when its size is unchanged.
  - String literal tables are chained.
- **New virtual methods** get slots in the extension table
  (`BfModule.cpp:8271-8285`; slot reuse by mangled name, `BfModule.cpp:26862-26914`).
- **Statics** keep their address when their type is unchanged; otherwise they get new zeroed
  storage (`DbgModule.cpp:7252-7253`).
- **Lambdas.** A lambda whose captures changed is replaced only if the old captures are a prefix
  of the new ones; otherwise calling it is trapped as an error (`LLDBDebugger.cpp:7686-7690`).
- **Old images** are freed once nothing can reach them, found by scanning the threads' registers
  and stacks conservatively (8133-8138).
- **The base module** need not be the executable: it can be "a Beef shared library loaded by a
  host program" (8780-8783).

### Field changes

- **Detection.** The compiler hashes each type's data members. A changed hash is a pending data
  change, with the warning "Hot compile detected data changes in '<type>'"
  (`BfModuleTypeUtils.cpp:6444-6479`). A changed type gets a new ClassVData symbol, suffixed with
  its data hash (`BfModule.cpp:5769-5777`).
- **The check.** Before loading, the IDE asks the debugger which types have live heap
  allocations and which methods are active or held by delegates (`IDEApp.bf:12340-12366`;
  `FinishPendingHotResolve`, 14326-14390; `BfCompiler::HotResolve_ReportType`,
  `BfCompiler.cpp:6584-6614`).
  - If a changed type is in use, the compile fails: "Hot type data changes cannot be applied
    because of the following types ... Revert changes or put the program into a state where the
    type is not actively being used" (`IDEApp.bf:14365-14377`).
  - On Linux the live counts come from the runtime's `gBfLiveTypeCounts`. Without them **every
    type is reported in use**, so every layout change is refused (`LLDBDebugger.cpp:9844-9887`).
- **So the IDE never migrates live objects.** It takes a field change only for a type with no
  instances.

### Could an engine use it without the IDE?

Not as shipped. The version state lives in the IDE's compiler instance and the patching in its
debugger, and BeefBuild has neither. There are two ways it could work:
- **Run `<Game>Editor` under the Beef IDE**, with the project's `Code/BeefSpace.toml` open, its
  `<Game>Editor` as the startup project, and `AllowHotSwapping` on. This needs no engine code; it
  is a developer workflow.
- **Embed IDEHelper**: a long-lived process that drives the compiler's hot API and the LLDB
  debugger. That is a large undertaking against an unexported surface, and it is not recommended.

## Tallow and the Beef IDE side by side

| | Tallow | Beef IDE hot compile |
|---|---|---|
| Driven by | the engine (dlopen and metadata rewrite) | the IDE (compiler versions and debugger patching) |
| Needs | `-rdynamic` Debug editor, python, nm, objcopy, c++ | the editor started by the IDE under its debugger, `AllowHotSwapping` |
| Compile | whole workspace in a shadow build dir, then a link | only the changed modules; no link (the debugger places objects) |
| Method bodies | new code reached through replaced types and instances; old delegates and objects run old code | every caller reaches new code (entry jumps) |
| New virtuals | via the replaced TypeInstance, on replaced instances | extension vtables, on all instances |
| Field changes on live objects | **yes**, on scene components, by migrating by name | **no**: refused while instances live |
| New types | yes (canonical type list, `GetType` hook) | yes (compiler versions) |
| Statics | kept; a size change is refused | kept when the type is unchanged, else new zeroed |
| Platforms | Linux and Windows x86-64 Debug | Windows; Linux through LLDB in this fork (off by default) |
| Depends on | Beef's private runtime layout, from outside | Beef's own compiler and debugger |

## What maps onto Sedulous's x2 model

| Sedulous | What it is | Reload consequence |
|---|---|---|
| The game package (`Code/<Game>` and parts) compiled into `<Game>Editor` (`ProjectBuild.bf:584`; GameCode.md "Where it lives") | the same shape as Tallow: the game is the editor executable | Tallow's "game objects vs engine objects" split applies; the parts and `Plugins/` packages are game code too |
| Generated `<Game>Editor` Debug config | no link flags (`ProjectBuild.bf:160-191`; the stock post-build steps only, `Tools/Sedulous.Tools.Editor/BeefProj.toml:14-15`) | Tallow's route needs `-rdynamic` added to the Debug Linux64 link |
| Behaviour (`Behaviour.bf:26-60`) | instances **owned by** `BehaviourManager<T>`, a scene system specialized per game class (`BehaviourManager.bf:33`) | the manager's code is a specialization over a game type, with `new T()` and comptime-baked tick lists (`BehaviourManager.bf:70-73, 128-160, 179-200`). After a layout change the manager's code is stale too, so **the manager must be replaced**, not just the instances |
| Registration (`GameplayServices.bf:31-115`) | contributions hold function pointers `=> InstallManager<T>`, `=> InstallLevel<T>`, and `GameRunner(=> CreateGame<T>)` | old pointers build old types: a reload must undo the part's `Load` and run the new one's |
| Unload and reload seams | `SceneModuleContributions.Remove` takes systems out of live scenes first (`SceneModuleContributions.bf:75-77`); a contribution that installs into a live scene resolves records preserved for it (24-26); systems are keyed by full name, not by Beef type id (`Scene.bf:673-692, 819-832, 1015-1019`) | the part's own unload/load is the natural migration path: write each instance's record, remove, load the new part, read the records back. Name keys survive a reload |
| Serialization | `[Behaviour]` generates `Serialize` over public fields, base first, "FIELD ORDER IS THE BINARY FORMAT" (`BehaviourAttribute.bf:13-15, 45-61`); scenes are keyed XML on disk (`Data/SampleProjects/SkyHopper/Content/FX/FxStompStars.scene.data`); "a keyed reader FAILS a section on a missing key" (`SceneViewPref.bf:105-106`) | migrating through our own serializer moves only public fields. A new field without a data version bump may fail a keyed read; a binary read is positional. Private runtime state is lost, as it already is on any re-read ("A read replaces the instance", GameCode.md "Rules that bite"; `BehaviourManager.bf:276-312`) |
| Reflection-driven tools | FieldPropertySource, the settings dialog, page registry and MCP reflection enumerate `Type.Types` (`FieldPropertySource.bf:1207,1281`; `SettingsDialog.bf:207`; `EditorPageRegistry.bf:76`; `ReflectionTools.bf:56,85`) | under Tallow's scheme these miss new types unless moved to a canonical list. Under the IDE's they are fine |
| Static registration | `[Behaviour]` registers enum cases in a static initializer, `sEnumCasesRegistered = EnumCases.Register(...)` (`EnumCases.bf:111-157`) | in a Tallow-style library this static is shared with the host and never re-run (and a new one's initializer may never run), so new enum cases go unnamed until a relaunch |
| Level and Game | a scene system per scene, and one game per session (`GameplayServices.bf:56-90`) | a Level is replaced like a manager. A Game holds `Listen` closures (GameCode.md, "Game"), so it is simplest to restart the session |
| Struct components (`SerializableComponentManager<T>`) | engine generics over game structs | under Tallow a size change is refused (resident layout); under the IDE it is refused while instances live |

**What does not map.**
- Tallow migrates any supported field *by name*, private ones included. Our record is public
  fields in order.
- Tallow components are created by reflection (`CreateObject`), which picks up new metadata. Ours
  are created by generic code compiled for one layout.
- Tallow's engine walks `ReflectedTypes`. Ours walks `Type.Types` in six places.
- A Sedulous workspace is far larger than Tallow's. A shadow-workspace compile means a second full
  engine build directory, and our full builds take about 16-17 GB of memory.

## The alternative: a fast relaunch that keeps the state

### What happens today

- **The loop.** Edit; Project > Build Project (or `project_build`); then Project > Open With This
  Build (or `editor_relaunch`). Open With This Build:
  - starts `Code/build/Debug_<Host>/<Game>Editor/<Game>Editor` with `--project`, `--data-root`
    and the MCP port (`EditorApplication.bf:988-1022`; `RelaunchArguments`,
    `EditorBuildTools.bf:131-145`);
  - then exits through `ConfirmExit`, which asks about unsaved pages.
- **For an agent**, `editor_relaunch` refuses when:
  - the editor is not built, or is stale;
  - a build is running;
  - pages are unsaved, unless it passes `discardUnsaved` (`EditorBuildTools.bf:350-418`).
- **Timing.** An incremental build of SkyHopperEditor took about 35 s (the coordinator's figure,
  not re-measured here). The relaunch itself (process start, project open, scene load) has **not
  been measured**. Spike step 0 measures both.

### What the editor already restores

- **Open pages and the active one**, a per-project section (`EditorOpenPagesSettings.bf:7-13`;
  `ProjectEditorSettings.bf:103-123`; `EditorPages.bf:446, 459`).
- **Each scene page's view**: overlays, camera, selection by persistent id, panes and the tool
  panel's place (`SceneViewPref.bf:26-67`). It is saved on every toggle and when the page closes
  (`SceneViewState.bf:9-16`; `SceneEditorPage.bf:767-769, 958-969`).
- **The MCP port**, carried over so an agent reconnects (`EditorBuildTools.bf:131-145`).

### What is lost, and what restoring it would take

- **Unsaved scene and asset edits.** They are prompted for (a person) or refused (an agent).
  - *Fix:* stash each dirty page's content to `Editor/relaunch/` before exiting, and reopen it
    dirty from the stash.
- **The Game tab's run.** The tab plays the project's default scene through its own game
  instance (`GameEditorPage.bf:34-45`), and a relaunch ends it.
  - *Cheap fix:* record "tab open, was playing" and press Play again after the relaunch, so the
    run starts over from its first scene.
  - *Mid-run:* restoring the run where it was means saving the running scenes and the Game's
    state. That is a save-game feature, and behaviours' private fields would still be lost by
    design.
- **The scene page's Simulate state** and the undo stack: not kept. That is acceptable.
- **Two steps.** Build, then relaunch.
  - *Fix:* a "Build and Relaunch" action and MCP flag. It builds, and on success stashes,
    relaunches and restores; on failure it shows the diagnostics and keeps running.
- **Build time.** Most of the 35 s is the compile and the link of a large executable; how it
  splits is unknown. The spike measures it before any work aimed at it. An option to weigh then:
  build only `<Game>Editor`'s changed projects (BeefBuild already does that), and look at the
  link.

## The spike plan (item 2)

The spike lives in `~/Dev/Beef/Spikes/HotReload`:
- `Engine`: a mini engine with `Behaviour`, `BehaviourManager<T>`, a scene with name-keyed systems,
  contributions with `Install` function pointers, and a reflection-driven field dump;
- `Game`: `Bob : Behaviour` with a field and `OnUpdate`, registered from a `Load`;
- `Host`: a console loop that ticks once a frame and prints `Bob`'s state;
- `reload.py`: Tallow's Linux `main()` cut down.

Each step proves one thing, and each is run for leaks with ASan where it can be.

0. **Baseline numbers, on the real thing (in a build window).** Time SkyHopperEditor's
   incremental build after a one-line Behaviour change, split into compile and link (BeefBuild's
   timing output). Then time a relaunch from process start to the scene drawn.
   *Proves:* what the relaunch costs and where the time goes.
1. **Beef IDE hot compile on Linux.** Build `Host` from the Beef IDE with `AllowHotSwapping` on,
   run it under the IDE, and change `Bob.OnUpdate`'s body.
   *Proves:* the LLDB path works on this machine, live instances run the new body, and a
   delegate made before the change runs the new code.
   Then add a field to `Bob` while instances live.
   *Proves:* the refusal and its message, and whether `gBfLiveTypeCounts` is present (the
   runtime's live counts) or every type reads as in use.
   Then the same on **SkyHopperEditor** itself, opened in the IDE.
   *Proves:* it scales to our workspace and to its memory, and how long a hot compile takes
   there.
2. **Tallow's pipeline, method body only.** Debug `Host` with `-rdynamic`; the shadow workspace,
   aliasing, renames, `c++ -shared -Bsymbolic`, `dlopen`. Change `Bob.OnUpdate` and apply by
   (a) the legacy vtable copy and (b) the structural replace.
   *Proves:* the pipeline works with today's Beef nightly; the library uses the host's runtime
   (a `String` made in new code freed by host code); and statics are shared.
3. **Engine generics over game types.** Find where `BehaviourManager<Bob>`'s code lands (the
   game's objects or the engine's) and whether, after a field is added to `Bob`, the old
   manager's `new T()` makes objects of the old size.
   *Proves or disproves:* that the manager has to be replaced; this is the risk most specific
   to Sedulous.
4. **Field layout change with migration, the Sedulous way.**
   - Write each `Bob`'s record.
   - Run the part's unload, which removes the contributions from live scenes.
   - Load the new part from the library: find its `Load` through reflection on the new type
     table, and run it so it registers new `Install` pointers.
   - Read the records back into fresh instances.
   - Repeat with a field renamed, a field added with and without a data version bump, and a
     private field.
   - Also add a new static with an initializer and a new enum case.

   *Proves:* our own seams (contributions, name-keyed systems, versioned records) are enough for
   migration, and whether new statics are initialized.
5. **Failure modes and growth.** A compile error, a resident type changed, an engine file
   touched, 20 reloads in a row (memory and time each), and a reflection walk of `Type.Types`
   after a new type is added (the six editor sites).
   *Proves:* the refusals are clean and the cost of a long session.
6. **Scale (only if steps 2 to 5 pass).** Point the pipeline at SkyHopper:
   - the shadow workspace's first full build (time and peak memory);
   - an incremental reload after a one-line change, set against step 0's relaunch.

   *Proves:* whether Tallow's route is worth its upkeep here.

## Open questions for the user

1. Is the fast relaunch the primary path for now: one Build and Relaunch, a stash for unsaved
   pages, and the Game tab played again from its start?
2. Must a running Play session survive a code change mid-run, or is starting the run over
   acceptable? Only Tallow's route keeps a live session across a field change, and even then
   only the supported fields of scene components.
3. Should running `<Game>Editor` under the Beef IDE with hot compile become a documented
   workflow, if spike step 1 passes on Linux? (Decided 2026-11-11: yes. GameCode.md documents it,
   and the build writes the editor entry's debug launch.) It is a developer setup (the IDE, a workspace
   setting) rather than something the project manager ships.
4. The spike's step 0, step 1 on SkyHopperEditor, and step 6 need build windows for heavy
   builds. Run them, or stop at the small host?
5. If Tallow's route is ever taken: is Linux-only acceptable at first (Windows needs its own
   `lld-link` scheme), and is a dependence on Beef's private runtime layout acceptable, tied to
   the pinned toolchain (`EngineVersion.Beef`)?
6. Unsaved pages on a relaunch: stash and restore them silently, or keep the prompt for a person
   and stash only for an agent's relaunch?

## Decided (2026-11-10)

- The fast relaunch first; then the Beef IDE's hot compile on Linux, first on a small host, then on SkyHopperEditor, as the documented loop for method-body edits if it works. Tallow's route is held.
- Unsaved pages on a relaunch: a person is asked as at an exit; an agent's are kept aside. `RelaunchPolicy.Unsaved` is the one place that says so.
- A later study: the editor and the runtime as separate processes (the ezEngine way), with the game's code only in the runtime process, restarted on a change. It is much larger than either path here, is decided together with Raptor's engine, and leads toward remote play (Android among the devices), a later topic. Its questions are listed under Phase 8 in `x2.md`.

## Done: the fast relaunch (2026-11-10)

- **One action.** Project > Build and Relaunch (Ctrl+Shift+B, and the palette) builds
  `<Game>Editor` when it needs it (missing, older than the code, or over an SDK that moved:
  `ProjectBuild.IsStale` with the SDK), shows the build on the status line and in the Console, and
  on a failure says the first errors and stays. On success it relaunches (`BuildAndRelaunch`,
  `EditorRelaunch.bf`). For an agent, `editor_relaunch` takes `build: true` and waits for the build
  the way `project_build` does.
- **What is kept.** The open pages, the active page and the dock come from the per-project store,
  which the relaunch writes before it starts the next editor and then freezes
  (`EditorSession.FreezeStore`), so the closing editor does not write it again. Each scene page
  writes its view (camera, selection, panes) on demand (`EditorPage.CaptureViewState`) rather than
  only when it closes. The rest is in `<project>/Editor/relaunch/relaunch.json` (`RelaunchState`),
  which the next editor is given by `--relaunch`: the Game tabs and whether each ran, the active
  panel, the pages kept aside and the times so far.
- **Unsaved pages.** `RelaunchPolicy.Unsaved` is the seam. A person is asked (Save All and
  Relaunch, Relaunch Without Saving, Cancel). An agent's pages are kept aside: each page's content
  goes to `Editor/relaunch/<guid>.bin` (`EditorPage.KeepAside`; scene pages write their scene's
  text, asset pages their object snapshot), never over the asset. The next editor gives it back
  (`EditorPage.TakeBack`), marked unsaved and with no history. A page that cannot be kept aside
  (a source file's page, a generic asset page, a clip held by a scene's animation panel) refuses the
  agent's relaunch and is named.
- **The Game tab** (`IRelaunchRun`) reopens, and plays again from its start if it was running or
  waiting on the cook.
- **Timings.** The next editor logs `Editor: relaunched (...): build, save, start, restore, total
  (ms)`. Start runs from the launch to the next editor's application being made; restore runs
  from then until the pages and tabs are back. The run itself starts after the cook, outside that
  time. These are still to be measured on SkyHopper (spike step 0).

Measured by hand (2026-11-10, SkyHopper on x2, `editor_relaunch {"build": true}` with Level1 unsaved and the Game tab playing): the relaunched editor came back with Level1 unsaved (the new entity in it, the scene file on disk untouched) and the Game tab active and playing again. Its log: `Editor: relaunched (1 page(s) kept aside, 1 Game tab(s)): build 24255, save 27, start 510, restore 1340, total 26132 (ms)`. The relaunch itself costs under 2 s beyond the build (save 27 ms, start 0.5 s, restore 1.3 s); the build of `<Game>Editor` is the rest.

## The Beef IDE's hot compile on Linux, tried (2026-11-10)

- The IDE needs LLDB: built without `liblldb-22-dev` it debugs through GDB, which cannot hot swap. Built with it (`bin/build.sh ide`, the fork's master aef00047), the IDE's own test suite ran headless under weston and all 21 Test1 hot-swap scripts passed (method bodies, data changes refused, virtuals, lambdas, interfaces, base changes). The suite stopped later at BugW003, a link failure of that test's program, unrelated to hot swap.
- A workspace must turn hot swapping on itself on Linux: `AllowHotSwapping = true` under `[Configs.Debug.Linux64]` (the IDE's default is on only for Windows Debug).
- SkyHopper, driven over the IDE's MCP server (`BeefIDE -workspace=<project>/Code -mcp=<port>`, headless weston): the IDE built SkyHopperEditor with hot swapping on in 36 s (peak about 3 GB) and ran it under LLDB (`DebugCommandArguments` `--project … --data-root … --null-gpu`). A probe method returned 1; after `edit_document` and `build` the IDE reported "hot swap: replaced 1 method" in 1.0 s and the running editor's probe returned 2; the editor ran on normally after. The same change through Build and Relaunch costs about 26 s.
- A field added to a live behaviour (`Coin`) did not come back: the IDE sat at about 93% CPU and stopped answering MCP for over 10 minutes, and was killed. Whether it was stuck on the refusal, a dialog a headless session cannot answer, or a hang is not known; it needs a run on a real display.
- So for method bodies the IDE loop works today on Linux, about 25 times faster than a relaunch; a layout change needs the relaunch, and the IDE must not hang on one.

## The field change, on a real display (2026-11-11)

- **The hang was the demangler.** After a data change the IDE demangles every hot method's name for
  its log, and Beef's demangler looped forever on the short names methods in a type's extensions
  get (`<index>$`, unlengthed) and crashed on a tuple's vendor types (`u3int`). Both are fixed on
  the fork (`fix/demangle-hang`, `fix/demangle-tuple`) and merged upstream; the IDE's own test
  covers an extension method.
- **The program showed as paused while it ran.** Interrupting it for the swap leaves LLDB a stop it
  resumes from itself; the IDE took that stop as a pause, so the debugger said Paused while the
  editor kept running. Fixed on the fork (`fix/lldb-restarted-stop`), a pull request to make.
- **A field added to a live type is refused**, as Beef's hot swap means it to be: with Level1 open
  and coins in it, adding a field to `Coin` gave "Hot type data changes cannot be applied ...
  'SkyHopper.Coin' allocated on the heap". Method bodies swap (1335 methods replaced in one compile,
  in about 70 s for the 161 modules a data change rebuilds). A layout change on a type in use needs
  Build and Relaunch. One earlier run (Level1 open, null GPU) did apply the same change, for a
  reason not traced.
- **Found on the way:**
  - The IDE's MCP `build` answered "succeeded" for a refused swap: the refusal never marked the
    compile failed, and the wait ended before the swap was resolved. Fixed on the fork
    (`fix/hot-refusal-fails`), with the IDE's live-types test asserting both outcomes.
  - The IDE's compiler crashed (in `BfModule::GetModuleOptions`, running comptime code) building
    over the folder several data-change hot compiles had left; a fresh build of the same code was
    fine. The folder is kept locally to reproduce it; not yet looked into.
  - `DebugCommandArguments` with `--null-gpu`, left from the headless runs, left the editor with
    no window when a person started it from the IDE. A person's setup has no GPU flag.
- **The setup, for a person:** the fork's IDE built with LLDB; in `Code/BeefSpace.toml`,
  `AllowHotSwapping = true` under `[Configs.Debug.Linux64]`; in the generated editor project,
  `DebugCommandArguments = "--project <project> --data-root <data>"`; then Debug > Start
  Debugging, edit a method body, Build.
