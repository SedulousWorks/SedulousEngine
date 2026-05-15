# Sedulous Virtual Filesystem (VFS)

Living document covering the virtual-filesystem layer that decouples byte
access from any specific backend (disk, pak archive, remote, etc.), and how
`Sedulous.Resources` builds on top of it.

The VFS lives under `Code/Foundation/` alongside `Sedulous.Resources`, which
depends on it.

---

## Why VFS Exists

The previous `IResourceRegistry` conflated two unrelated concerns:

1. **Byte access** - "give me the bytes for `primitives/cube.mesh`."
2. **Identity** - "what URI does GUID `abc-123` map to?"

Worse, the byte-access side hardcoded "the bytes live in a folder on disk."
There was no clean way to add pak archives, in-memory blobs, or remote
endpoints; every loader called `File.ReadAllText(absolutePath)` directly.

The VFS refactor splits these:

- **Byte access** becomes `IMount` (and capability sub-interfaces). The
  filesystem is just one implementation. Pak files, memory blobs, and future
  HTTP/CDN backends plug in without touching consumer code.
- **Identity** becomes `IResourceIndex` (in `Sedulous.Resources`). Indices
  map GUIDs to URIs and stack in priority order; they have no idea where the
  bytes live.

The two are glued together by `ResourceSystem`'s mount table: each scheme
(`builtin`, `project`, ...) maps to an `IMount`, and resolution flows
`URI -> (mount, locator) -> stream`.

---

## Layer Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Consumer                                                                   │
│  ResourceSystem.LoadResource<T>("project://textures/foo.tex")               │
│    1. parse scheme + locator                                                │
│    2. look up scheme in mount table                                         │
│    3. mount.Open(locator) -> Stream                                         │
│    4. hand stream to typed IResourceManager                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  Identity                                                                   │
│  IResourceIndex (Sedulous.Resources)                                        │
│    GUID  <->  URI                                                           │
│    InMemoryResourceIndex - dict-backed, serializable to text                │
├─────────────────────────────────────────────────────────────────────────────┤
│  VFS Core (Sedulous.VFS)                                                    │
│  IMount, IEnumerableMount, IWatchableMount, IWritableMount, IChangeSource   │
│  MountError                                                                 │
├──────────────────────────────────┬──────────────────────────────────────────┤
│  Disk Backend (Sedulous.VFS.Disk)│  Pak Backend (Sedulous.VFS.Pak)          │
│  FileSystemMount: R/E/W/Watch    │  PakMount: R/E only                      │
│  FileSystemChangeSource: poll    │  PakFormat: SPAK on-disk layout          │
│                                  │  ICompressor + PassthroughCompressor     │
│                                  │  PakEntryStream                          │
└──────────────────────────────────┴──────────────────────────────────────────┘
                                   │
                              Pak Tool (offline)
                              ─────────────────
                              Sedulous.VFS.Pak.Tool
                              PakBuilder: write paks from byte streams
```

---

## VFS Core (`Sedulous.VFS`)

### `IMount`

The minimum surface for "read bytes from somewhere."

```beef
interface IMount
{
    bool Exists(StringView locator);
    Result<Stream, MountError> Open(StringView locator);
}
```

A **locator** is a forward-slash, mount-relative path (`"textures/foo.tex"`).
No leading slash. No scheme - the scheme is the consumer's concern, not the
mount's. A mount could be registered under any scheme the application
chooses.

`Open` returns a `Stream` the caller owns (and must `delete`). Where the
stream's bytes come from is the mount's business - a `FileStream` for disk,
a `FixedMemoryStream` over a pak entry, a future async-readable
network stream.

### Capability Interfaces

Mounts only implement what they can actually do. Consumers do `is IXxxMount`
rather than calling and catching `NotSupported`.

| Interface | Adds |
| --- | --- |
| `IEnumerableMount` | `Enumerate(folderLocator, outEntries)` - list direct children of a folder. Entries ending in `/` are directories. |
| `IWatchableMount` | `ChangeSource` property - exposes an `IChangeSource` for hot reload. Owned by the mount. |
| `IWritableMount` | `Save(locator, stream)` and `Delete(locator)` - write and delete entries. |

### `IChangeSource`

Per-mount notifier for content changes. Polled by `ResourceSystem`.

```beef
interface IChangeSource
{
    void Track(StringView locator);
    void Untrack(StringView locator);
    bool Poll(List<String> outChangedLocators);  // appends locators that changed
}
```

Implementation is mount-specific: disk polls mtimes, a remote could push,
paks return null (immutable). The polling cadence is the implementation's
business - `ResourceSystem` calls `Poll` whenever it suits it; the mount
enforces its own min-interval if needed.

### `MountError`

```beef
public enum MountError
{
    NotFound,      // locator doesn't exist
    IOError,       // read/write/seek failure
    AccessDenied,  // permissions, sharing violation, read-only
    NotSupported   // operation not supported by this mount
}
```

---

## Disk Backend (`Sedulous.VFS.Disk`)

### `FileSystemMount`

Implements every capability: read, enumerate, watch, write. Wraps a root
directory on the local filesystem.

```beef
let mount = scope FileSystemMount("/path/to/assets");
let stream = mount.Open("textures/foo.tex").Value;
```

- `RootPath` exposed for code that needs the absolute path (e.g. the editor's
  asset browser to invoke a "show in file explorer" action). Other mounts
  don't have such a concept - code that uses `RootPath` is implicitly
  disk-only.
- Trailing slashes and `\` separators in the constructor input are
  normalized; locators always use `/` internally.
- `Save` creates intermediate directories as needed.

### `FileSystemChangeSource`

Polling mtime watcher. Configurable minimum interval (`MinPollIntervalSeconds`,
default 0.5s) - calls to `Poll` more often return `false` immediately without
hitting disk.

```beef
let cs = (mount as IWatchableMount).ChangeSource;
cs.Track("textures/foo.tex");
// ... later
let changed = scope List<String>();
if (cs.Poll(changed)) { ... }
```

Created lazily on first access, owned by the mount, destroyed with it.

---

## Pak Backend (`Sedulous.VFS.Pak`)

Custom on-disk archive format. Implements `IMount` and `IEnumerableMount`
only - paks are immutable at runtime (no `IWritableMount`, no
`IWatchableMount`).

### File Format

```
[Header: 32 bytes]
  uint32 Magic        = 'SPAK' (0x4B415053)
  uint32 Version      = 1
  uint64 EntryCount
  uint64 TocOffset    bytes from start of file
  uint64 TocSize      bytes

[Data heap]
  raw bytes, entries packed back-to-back. Each entry's bytes are written
  in their stored form (compressed if any compression was applied).

[TOC: variable, at Header.TocOffset]
  For each entry, in arbitrary order:
    uint16  LocatorLength    bytes (UTF-8)
    uint8[] Locator
    uint64  Offset           into the file
    uint64  StoredSize       bytes in the data heap
    uint64  OriginalSize     bytes after decompression
    uint16  Compression      CompressionId
```

All values little-endian. `Locator` uses forward slashes; path traversal
(`..`) is the consumer's concern - the format itself permits any byte
string up to 65535 bytes.

### `PakMount`

Loads the header + TOC into memory at construction. Entry bytes are read on
demand via fresh `FileStream` opens - the **reopen-per-Open** policy. Trades a
file handle per active stream for not needing a seek lock across threads;
fans out well across cores.

```beef
let result = PakMount.LoadFromFile("game.pak");
if (result case .Ok(let mount))
{
    defer delete mount;
    let stream = mount.Open("textures/foo.tex").Value;
    defer delete stream;
    // read from stream...
}
```

Header validation rejects bad magic, unsupported versions, truncated files,
and entries whose offsets escape the data heap.

**Reopen-per-Open trade-off:** simple, no shared seek lock, scales with cores.
If profile says we're hot-reading from a small set of paks and burning file
handles, swap to a shared `FileStream` + seek mutex. The `IMount` surface
doesn't change.

### `ICompressor` and Codec Plug-in

Codecs are pluggable per pak. Every `PakMount` has the passthrough codec
(`CompressionId.None`) preinstalled so uncompressed paks always load.
Additional codecs register via `mount.RegisterCompressor(...)`.

```beef
interface ICompressor
{
    CompressionId Id { get; }
    int MaxCompressedSize(int originalSize);
    Result<int, CompressionError> Compress(Span<uint8> src, Span<uint8> dst);
    Result<int, CompressionError> Decompress(Span<uint8> src, Span<uint8> dst);
}
```

`CompressionId` is a stable `uint16` written to TOC entries. Values are part
of the on-disk format - never reassign an existing value, only add new ones.
`None = 0` is reserved. Future codecs (zstd, LZ4) live in their own libraries
and register on the mount.

If a pak entry's `CompressionId` isn't registered, `Open` returns
`.NotSupported`. That's how a future pak built with a new codec gracefully
fails on an older reader.

### `PakEntryStream`

`FixedMemoryStream` subclass that owns its backing buffer. `PakMount.Open`
reads (and decompresses) an entry into a fresh `uint8[]` and hands it to
`PakEntryStream`. The buffer lives as long as the stream - `delete stream`
frees the bytes.

**Fast path:** when `Compression == None`, the read buffer is handed straight
to the stream without a roundtrip through `Decompress`. Avoids one copy.

---

## Pak Builder (`Sedulous.VFS.Pak.Tool`)

Offline writer. Kept in a separate library so the runtime never pulls in the
writer path.

```beef
let builder = scope PakBuilder(scope MyZstdCompressor());  // null = no compression
builder.Add("textures/foo.tex", pixelBytes);
builder.Add("textures/foo.tex.bin", sidecarBytes);
builder.Add("scenes/level1.scene", sceneBytes);
builder.Write("dist/game.pak");
```

`Add` copies the byte data immediately; the caller can free its source
buffer right after.

`Write` layout sequence:

1. Write a header stub (32 zeros).
2. Write each entry's bytes to the data heap, recording (offset, storedSize)
   per entry. Compress through `mCompressor` if non-passthrough.
3. Write the TOC at the current file position.
4. Seek to file start, patch in the real header (now that `TocOffset` and
   `TocSize` are known).

Builders are reusable - call `Write` again to produce another copy, or `Add`
more entries first.

**Locator length limit:** 65535 bytes (uint16). `Write` returns an error if
any entry exceeds this.

---

## Resources Integration

`Sedulous.Resources` consumes the VFS but doesn't know about specific
backends. It deals in URIs (`scheme://locator`) and routes through a mount
table.

### `ResourceSystem` Surface (new)

```beef
class ResourceSystem
{
    // Mount table
    public void Mount(StringView scheme, IMount mount);
    public void Unmount(StringView scheme);
    public IMount GetMount(StringView scheme);

    // Identity indices
    public void AddIndex(IResourceIndex index);
    public void RemoveIndex(IResourceIndex index);

    // Loading - URI-only
    public Result<ResourceHandle<T>, ResourceLoadError>
        LoadResource<T>(StringView uri, bool fromCache = true, bool cacheIfLoaded = true);

    public Result<ResourceHandle<T>, ResourceLoadError>
        LoadByRef<T>(ResourceRef resourceRef);

    // Managers (unchanged)
    public void AddResourceManager(IResourceManager manager);
    public void RemoveResourceManager(IResourceManager manager);

    // Hot reload via mount change sources
    public void EnableHotReload();
    public void DisableHotReload();
    public void AddChangeListener(IResourceChangeListener listener);
    public void Update();  // call from app's frame loop
}
```

### URI Format

```
scheme://locator
```

Examples: `builtin://primitives/cube.mesh`, `project://scenes/level1.scene`.

The new `LoadResource<T>` rejects URIs without a scheme. There is no
"absolute filesystem path" fallback - call sites that previously passed
absolute paths must mount the directory under some scheme and load via
`scheme://...`.

### `IResourceIndex`

GUID-to-URI map. Stacks in registration order on the `ResourceSystem`.

```beef
interface IResourceIndex
{
    bool TryResolveUri(Guid id, String outUri);
    bool TryResolveId(StringView uri, out Guid id);
    void Register(Guid id, StringView uri);
    void Unregister(Guid id);
    int Count { get; }
    void GetEntries(List<(Guid id, StringView uri)> outEntries);
    Result<void> SerializeTo(Stream stream);
    Result<void> DeserializeFrom(Stream stream);
}
```

`InMemoryResourceIndex` is the canonical implementation: dictionaries plus
stream-based persistence. The on-disk format is one `guid=uri` line per
entry (UTF-8, `\n`-terminated). Same shape as the old `.registry` files,
except entries now carry full URIs instead of just relative paths.

Persistence is stream-based, not path-based - the caller routes the stream
to wherever it wants (a writable mount, a memory buffer, a network upload):

```beef
let stream = scope MemoryStream();
index.SerializeTo(stream);
stream.Position = 0;
writableMount.Save("project.registry", stream);
```

### `IResourceManager` and `ResourceLoadContext`

Managers are byte-source-agnostic. They get a context carrying the primary
stream plus optional mount/locator for resources that need siblings (e.g.
audio clip with a PCM sidecar).

```beef
struct ResourceLoadContext
{
    public Stream Stream;        // primary input
    public IMount Mount;          // for opening siblings; null on synthetic loads
    public StringView Locator;    // mount-relative locator; empty on synthetic
}

abstract class ResourceManager<T> : IResourceManager where T : IResource
{
    protected abstract Result<T, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx);
    public abstract void Unload(T resource);
    protected virtual Result<void, ResourceLoadError>
        ReloadResource(T resource, ResourceLoadContext ctx) => .Err(.NotSupported);

    // Helpers in the base class
    protected static Result<void, ResourceLoadError> ReadAllBytes(Stream, List<uint8>);
    protected static Result<void, ResourceLoadError> ReadAllText(Stream, String);
}
```

Most managers only touch `ctx.Stream` - the `ReadAllText` / `ReadAllBytes`
helpers cover the common slurp-then-parse pattern. `AudioClipResourceManager`
and `TextureResourceManager` are the sidecar cases: they parse text metadata
from `ctx.Stream`, then `ctx.Mount.Open(ctx.Locator + "/<sidecar>")` for the
binary payload.

### Resolution Flow

```
LoadResource<T>("project://textures/foo.tex")
  └─ cache hit by URI?  ->  return cached handle
  └─ parse scheme + locator
  └─ mount = ResourceSystem.GetMount("project")
  └─ stream = mount.Open("textures/foo.tex")
  └─ manager.Load(.(stream, mount, "textures/foo.tex"))
       └─ manager.LoadFromContext(ctx)
       └─ reads ctx.Stream, optionally opens siblings via ctx.Mount
  └─ cache by URI
  └─ if mount is IWatchableMount: changeSource.Track(locator)
  └─ return handle
```

`LoadByRef` does the cache check by GUID first, walks indices to find a URI,
falls back to `ResourceRef.Path` if no index match, then delegates to
`LoadResource`.

### Hot Reload

Each `IWatchableMount` exposes an `IChangeSource`. `ResourceSystem` polls
them in `Update()` and translates changed locators back to URIs by combining
with the scheme each mount is registered under. For each changed URI,
matching cache entries are reloaded via `manager.Reload(resource, ctx)`.

Change listeners receive scheme-prefixed URIs:

```beef
interface IResourceChangeListener
{
    void OnResourceReloaded(StringView uri, Type resourceType, IResource resource);
}
```

---

## Editor Integration

The editor's asset browser drives off a `List<MountEntry>` exposed on
`EditorContext.MountEntries`. Each entry bundles `(Scheme, Mount, Index,
IndexLocator, IsLocked)`.

```beef
// In Sedulous.Editor.Core
class MountEntry
{
    public String Scheme;            // "builtin", "project", ...
    public IMount Mount;
    public IResourceIndex Index;
    public String IndexLocator;      // mount-relative, e.g. "project.registry"
    public bool IsLocked;            // builtin/project can't be unmounted
}
```

`EditorApplication` populates this list:

- **builtin** - created in `EnsureDefaultAssets`. `FileSystemMount` over the
  editor's asset directory; `InMemoryResourceIndex` loaded from
  `builtin.registry` (auto-generated on first run with default primitives,
  materials, skies).
- **project** - created/replaced in `OpenProject`. `FileSystemMount` over
  the project directory; `InMemoryResourceIndex` loaded from
  `project.registry` if present.
- **extras** - created by `AssetBrowserPanel.MountRegistry()` /
  `CreateRegistry()`. Persisted in `.sedproj` and restored on project open.

The asset browser's tree adapter (`RegistryTreeAdapter`) and content adapter
(`AssetContentAdapter`) take `MountEntry` directly. Subdirectory traversal
uses `FileSystemMount.RootPath` for disk mounts - non-disk mounts would need
`IEnumerableMount.Enumerate` to feed the tree.

### `MountResolver`

Editor code routinely has an absolute filesystem path in hand (from the OS
file dialog, the asset browser's `AbsolutePath` field, or
`SceneEditorPage.FilePath`) and needs to find the mount that owns it.
`MountResolver` is the canonical helper:

```beef
// Read access
IMount mount = null;
let locator = scope String();
if (MountResolver.TryResolveAbsolute(context.MountEntries, absolutePath, out mount, locator))
{
    let stream = mount.Open(locator).Value;
    // ...
}

// Write access (requires IWritableMount)
IWritableMount writable = null;
if (MountResolver.TryResolveAbsoluteWritable(context.MountEntries, absolutePath, out writable, locator))
{
    writable.Save(locator, stream);
}
```

Walks the entries for a `FileSystemMount` whose root prefixes the path; skips
non-disk mounts implicitly. Code that calls into this is therefore
disk-only. Used by `SceneEditorPage.Save`, `SceneEditorPageFactory`,
`PrefabEditorPageFactory`, and `ResourceRefEditor`.

### Asset Import

`IAssetImporter.Import` receives an `AssetImportContext`:

```beef
struct AssetImportContext
{
    public IWritableMount Mount;
    public StringView BaseLocator;      // mount-relative folder, e.g. "imports/"
    public IResourceIndex Index;
    public StringView UriPrefix;        // matches BaseLocator, e.g. "project://imports/"
    public ISerializerProvider Serializer;
}
```

Importers build full locators as `BaseLocator + filename` for writes, and
full URIs as `UriPrefix + filename` for index registration. They never need
to know what scheme they're under - the dialog supplies it.

Index persistence is the dialog's job, not the importer's: `ImportDialog`
serializes the index back through the mount after a successful import.

---

## Migration Notes (from old `IResourceRegistry`)

Hard cuts, no compat shims:

| Old | New |
| --- | --- |
| `ResourceRegistry("name", "/root/path")` | `FileSystemMount("/root/path")` + `InMemoryResourceIndex()` + `ResourceSystem.Mount("name", mount)` + `ResourceSystem.AddIndex(index)` |
| `registry.Register(guid, "rel/path")` | `index.Register(guid, "scheme://rel/path")` (full URI, including scheme) |
| `registry.SaveToFile(path)` | `index.SerializeTo(memStream)` + `mount.Save("name.registry", memStream)` |
| `registry.LoadFromFile(path)` | open via `mount.Open("name.registry")`, then `index.DeserializeFrom(stream)` |
| `ResourceSystem.AddRegistry / RemoveRegistry / GetRegistries` | `Mount / Unmount / GetMount` for byte access; `AddIndex / RemoveIndex` for identity |
| `ResourceSystem.TryMakeProtocolPath(absolutePath, ...)` | Removed. Editor code that needs absolute-path -> URI conversion walks `EditorContext.MountEntries` for a matching `FileSystemMount.RootPath`. |
| `IResourceManager.Load(StringView path)` | `Load(ResourceLoadContext ctx)` |
| `IResourceManager.Load(MemoryStream stream)` | `Load(ResourceLoadContext ctx)` (single entry point) |
| `IResourceManager.ReloadFromFile(resource, path)` | `Reload(resource, ResourceLoadContext ctx)` |
| `Resource.SaveToFile(path, provider)` | `Resource.WriteToStream(Stream, provider)` - caller routes the stream |
| `SceneResourceManager.SaveSceneToFile(scene, path)` | `SaveScene(scene, IWritableMount mount, StringView locator)` |
| `SceneResourceManager.InstantiateScene(resource, scene)` (re-read by SourcePath) | `InstantiateScene(resource, scene, IMount mount, StringView locator)` |
| `PrefabResourceManager.SavePrefabToFile(scene, params, path)` | `SavePrefab(scene, params, IWritableMount mount, StringView locator)` |
| `PrefabResourceManager.LoadPrefabIntoScene(resource, scene)` (re-read by SourcePath) | `LoadPrefabIntoScene(resource, scene, IMount mount, StringView locator)` |
| `FileWatcher` (in `Sedulous.Resources`) | Removed - replaced by `FileSystemChangeSource` in `Sedulous.VFS.Disk`. |

### `Resource.SourcePath`

Now stores the mount-relative locator (e.g. `"scenes/level1.scene"`), not an
absolute filesystem path. Any code that previously did
`File.ReadAllText(resource.SourcePath, ...)` is broken - open through the
resource's mount instead. (Reach the mount via `ResourceSystem.GetMount(scheme)`
where `scheme` comes from parsing `comp.PrefabRef.Path` or similar.)

The fixed example is `PrefabComponentManager.InstantiatePrefab` - it parses
`comp.PrefabRef.Path` (a URI) into `(scheme, locator)`, looks up the mount
via `ResourceSystem.GetMount(scheme)`, and reads the bytes through that mount.
See that file for the canonical pattern.

### Test Helpers

Tests that previously created a temp file and passed its absolute path to
`ResourceRef` now need to mount the temp directory and use a URI:

```beef
let mount = scope FileSystemMount(tempDir);
resSys.Mount("test", mount);

let uri = scope String()..AppendF("test://{}", locator);
var prefabRef = ResourceRef(.Empty, uri);
```

See `PrefabTests.WithTempPrefabFile` for the pattern.

---

## Workspace Layout

```
Code/Foundation/
  Sedulous.VFS/                core interfaces + MountError
    src/IMount.bf
    src/IEnumerableMount.bf
    src/IWatchableMount.bf
    src/IWritableMount.bf
    src/IChangeSource.bf
    src/MountError.bf

  Sedulous.VFS.Disk/           disk implementation
    src/FileSystemMount.bf
    src/FileSystemChangeSource.bf

  Sedulous.VFS.Pak/            pak reader + format
    src/PakFormat.bf
    src/PakMount.bf
    src/PakEntryStream.bf
    src/ICompressor.bf
    src/PassthroughCompressor.bf

  Sedulous.VFS.Pak.Tool/       pak writer (offline only)
    src/PakBuilder.bf

  Sedulous.VFS.Tests/          36 tests across the three impls
    src/FileSystemMountTests.bf
    src/ChangeSourceTests.bf
    src/PakMountTests.bf
```

Each project is registered under the `Experimental/VFS` workspace folder in
`BeefSpace.toml`. Foundation/Resources depends on `Sedulous.VFS` (the core
project only - backend choice is the application's call).

---

## Test Coverage

`Sedulous.VFS.Tests` - 36 tests.

**FileSystemMount** (14): read/write/enumerate/delete, concurrent opens,
save-replaces-existing, save-empty, intermediate directory creation, root
path normalization (trailing slash + backslashes), open-after-delete,
delete-missing, non-existent-folder enumeration, capability checks
(implements all four).

**ChangeSource** (7): detects modifications, returns false without changes,
untrack stops detection, multiple changes per poll, duplicate track is
no-op, respects min interval, lazily created singleton.

**PakMount** (15): single/multi/empty/256KiB roundtrips, missing entries,
two concurrent streams, enumerate at root + subfolders, bad magic /
truncated / missing file rejection, unknown `CompressionId` returns
`NotSupported`, custom XOR codec end-to-end roundtrip, unregistered codec
returns `NotSupported`, locator backslash normalization, capability checks
(no `IWritableMount`/`IWatchableMount`).

Gaps worth filling later if the experiment continues:

- Concurrent change-source modifications.
- Path traversal hardening (`../escape`).
- `Enumerate` on a non-existent mount root for `FileSystemMount`.
- Behavior when the underlying pak file is deleted mid-mount.
- Multi-threaded `Open` against a pak (would shake out the reopen-per-Open
  policy in earnest).

---

## Worth Knowing (Architecture Quirks)

**`ResourceSystem.LoadResource` strictly requires a scheme.** No
absolute-path fallback. This is intentional - the old behavior of accepting
either confused the boundary between identity and location. If you need to
load an arbitrary file, mount its directory under a scheme first.

**Editor code with an absolute path in hand** (page factories, save flows,
the file-picker callback in `ResourceRefEditor`) routes through
`MountResolver.TryResolveAbsolute` / `TryResolveAbsoluteWritable` to find
the owning mount. Files outside any mount are refused - they couldn't load
later anyway.

**Disk-only editor code is implicit.** `MountResolver` only matches
`FileSystemMount` entries; the moment a non-disk mount (pak, remote) is in
play, code that calls `MountResolver` simply won't find it and will refuse
to open. That's the right behavior - non-disk mounts have no absolute path
to resolve from.

**Reopen-per-Open** on `PakMount` is fine for typical asset loads but burns
file handles under heavy concurrent read. If profiles show that's hot, swap
to a shared FileStream + seek lock - the `IMount` surface doesn't change.

**`Resource.SourcePath`** is now the mount-relative locator, not an absolute
filesystem path. Anything reading `resource.SourcePath` and feeding it to
`File.*` is broken - use the mount the resource was loaded from instead.
`PrefabComponentManager.InstantiatePrefab` shows the canonical pattern:
parse the URI from `comp.PrefabRef.Path`, look up the mount via
`ResourceSystem.GetMount(scheme)`, and read through it.

---

## Open Items / Future Work

- **Real codecs.** Zstd, LZ4, or whatever wins. Each lives in its own
  library and registers on `PakMount` via `RegisterCompressor`. The format
  reserves `CompressionId` values for them.
- **Memory mounting (`MemoryMount`).** Useful for tests, embedded blobs, and
  scripting-generated resources. Should be trivial - same `IMount` surface,
  back the bytes with a `List<uint8>` or a static array.
- **Pak alignment / mmap.** The current format packs entries back-to-back
  with no alignment. Memory-mapping the pak file and returning
  `FixedMemoryStream` slices would avoid the copy in `PakMount.Open` -
  worth a look once the engine is asset-heavy.
- **Pak CRC.** Optional per-entry CRC32 in the TOC for corruption detection.
  Not on by default - adds bytes to every entry.
- **Async `Open`.** Synchronous today. The day a real `HttpMount` exists,
  add an `OpenAsync` overload that returns a `Job<Stream>` rather than
  blocking the worker thread.
- **Index reverse lookup helpers.** Currently the editor walks
  `MountEntries` linearly to map absolute paths back to URIs. If this gets
  hot (e.g. an asset browser refresh that does it per item), a dedicated
  reverse table or trie would help.
- **Graduate from `Experimental`.** Once the VFS has been used through one
  or two real shipping milestones and the on-disk pak format hasn't needed
  to change, move it to `Foundation/`.
