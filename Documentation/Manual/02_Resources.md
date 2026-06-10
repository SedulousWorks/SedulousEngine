# Resources

Resources are engine assets -- meshes, textures, materials, animations, audio clips, and more. The resource system manages loading, caching, reference counting, and hot-reload, and routes byte access through a virtual filesystem so the same code works against directories on disk, packed archives, or other backends.

## Resource System Overview

`ResourceSystem` is the central hub, owned by the application and shared across all subsystems. It coordinates:

- **Mounts** -- byte sources, keyed by URI scheme (`builtin://`, `project://`, ...). Provided by the `Sedulous.VFS` layer.
- **Indices** -- GUID -> URI maps. Stack in priority order; multiple indices can coexist.
- **Managers** -- type-specific loaders (`TextureResourceManager`, `StaticMeshResourceManager`, etc.).
- **Cache** -- prevents duplicate loads of the same URI.
- **Hot-reload** -- watches mounts that support it and reloads resources when their bytes change.

Subsystems register their resource managers during initialization. You don't create the resource system yourself -- `EngineApplication` (or the editor) sets it up and mounts `builtin://` for built-in assets and `project://` when a project is opened.

## URIs

Every resource is identified by a URI of the form `scheme://locator`:

```
builtin://primitives/cube.mesh
project://models/hero.mesh
project://scenes/level1.scene
```

The scheme selects which mount provides the bytes; the locator is the path within that mount (forward-slash separated, no leading slash). The same locator under different schemes is two different resources -- the scheme part is meaningful.

There is no bare-path fallback. `ResourceSystem.LoadResource<T>(uri)` requires a scheme; passing a raw filesystem path will fail with `NotFound`. To load an arbitrary file, mount its directory under a scheme first.

## Mounts and Indices

A mount is anything that can serve bytes for a locator. The standard backend is a directory on disk (`FileSystemMount`); the engine also ships a packed-archive backend (`PakMount`). Both implement the same `IMount` interface, so loaders don't care which one is behind a URI.

`EngineApplication` mounts the engine's asset directory under `"builtin://"` automatically. The editor mounts the open project directory under `"project://"`. Additional mounts can be added at runtime:

```beef
using Sedulous.VFS.Disk;

let extra = new FileSystemMount("/path/to/shared/assets");
ResourceSystem.Mount("shared", extra);

// Later
ResourceSystem.Unmount("shared");
delete extra;
```

An **index** maps GUIDs to URIs and serves as the identity layer. The default `InMemoryResourceIndex` is a dictionary with a simple `guid=uri` text persistence format. Each scheme typically has a paired index file (e.g. `project.registry` inside the project mount). The engine loads the builtin index automatically; the editor loads the project index on project open.

```beef
// Manual setup, equivalent to what EngineApplication does for builtin://
let mount = new FileSystemMount("/path/to/assets");
ResourceSystem.Mount("custom", mount);

let index = new InMemoryResourceIndex();
let stream = mount.Open("custom.registry");
if (stream case .Ok(let s))
{
    defer delete s;
    index.DeserializeFrom(s);
}
ResourceSystem.AddIndex(index);
```

Most users never write this code -- it's handled by the engine and the editor's "Mount Registry" / "Create Registry" buttons.

## ResourceRef

A `ResourceRef` is a serializable reference to a resource -- a GUID plus a URI. Components store these to reference assets.

```beef
// Create a resource ref by URI
var meshRef = ResourceRef(.Empty, "builtin://primitives/cube.mesh");
defer meshRef.Dispose();  // ResourceRef owns a String, must be disposed

// Check if valid
if (meshRef.IsValid)
{
    // Has either a GUID or a URI
}
```

> **Important**: `ResourceRef` is a struct that owns a heap-allocated `String`. Always dispose it when done, or use `defer`. When storing in a class field, use a field destructor: `private ResourceRef mRef ~ _.Dispose();`

### Setting Resource Refs on Components

Components that reference resources follow a setter pattern that deep-copies the ref:

```beef
var meshRef = ResourceRef(.Empty, "project://models/hero.mesh");
defer meshRef.Dispose();
meshComponent.SetMeshRef(meshRef);
```

The component makes its own copy, so the original can be disposed immediately.

## Loading Resources

Resources are typically loaded implicitly when components resolve their `ResourceRef` during the update loop. You can also load explicitly:

```beef
// Load by URI
if (ResourceSystem.LoadResource<TextureResource>("project://textures/wood.texture") case .Ok(let handle))
{
    let texture = handle.Resource;
    // Use texture...
    handle.Release();  // Release when done
}

// Load by ResourceRef (resolves GUID via indices first, then URI)
if (ResourceSystem.LoadByRef<StaticMeshResource>(meshRef) case .Ok(let handle))
{
    let mesh = handle.Resource;
    handle.Release();
}
```

`LoadByRef` is preferred over `LoadResource(path)` when you have a `ResourceRef` because it can resolve through the index even if the URI in the ref is stale (renamed or moved assets). When the URI in the ref no longer exists, the index can still resolve the GUID to a current URI.

### Adding Programmatic Resources

Resources created in code (procedural meshes, generated textures) are added directly:

```beef
let cubeRes = StaticMeshResource.CreateCube();
ResourceSystem.AddResource<StaticMeshResource>(cubeRes);
```

After adding, reference the resource by its GUID:

```beef
var meshRef = ResourceRef(cubeRes.Id, .());
defer meshRef.Dispose();
```

## Resource Types

### Meshes

Static meshes (`.mesh`) and skinned meshes (`.skinnedmesh`) have their own resource types and managers.

**Procedural creation:**

```beef
let plane = StaticMeshResource.CreatePlane(10, 10, 1, 1);
let cube = StaticMeshResource.CreateCube();
let sphere = StaticMeshResource.CreateSphere(0.5f, 32, 16);
```

**Loading from model files:**

Model files (`.gltf`, `.glb`, `.fbx`) are imported by the editor or programmatically. The import pipeline converts them into `.mesh`, `.texture`, `.material`, `.skeleton`, and `.animation` files written through a writable mount.

```beef
using Sedulous.Models;
using Sedulous.Models.GLTF;

GltfModels.Initialize();  // Register the GLTF loader

if (ModelLoaderFactory.Load(gltfPath) case .Ok(let model))
{
    defer delete model;
    let importer = scope ModelImporter();
    if (importer.Import(model, .Default()) case .Ok(let result))
    {
        // result contains meshes, textures, materials, skeletons, animations
        // Save them through a writable mount and register their URIs in an index
    }
}
```

### Textures

Textures (`.texture`) wrap an image with sampling parameters (filter, wrap, mipmaps). Pixel data lives in a binary sidecar (`.texture.bin`) right next to the metadata file -- both files share the same mount and are opened together by the loader.

**Import via TextureImporter:**

```beef
using Sedulous.Textures.Importer;

// Standard 2D texture
if (TextureImporter.Import2D(imagePath) case .Ok(let texRes))
{
    ResourceSystem.AddResource<TextureResource>(texRes);
}

// Equirectangular HDR sky
if (TextureImporter.ImportEquirectangular(hdrPath) case .Ok(let texRes))
{
    ResourceSystem.AddResource<TextureResource>(texRes);
}
```

**Texture shapes:**

The `TextureShape` enum describes how pixel data is interpreted:

| Shape | Description |
|-------|-------------|
| `Texture2D` | Standard 2D image |
| `Texture2DArray` | Multiple layers, same dimensions |
| `Texture3D` | Volume texture |
| `Cubemap` | 6 square faces |
| `CubemapArray` | Array of cubemaps |

**Setup presets:**

```beef
texRes.SetupFor3D();                     // Mipmaps, linear, repeat, aniso 16
texRes.SetupForSprite();                 // Nearest, clamp, no mipmaps
texRes.SetupForUI();                     // Linear, clamp, no mipmaps
texRes.SetupForEquirectangularSkybox();  // Linear, clamp, Texture2D
texRes.SetupForCubemapSkybox();          // Linear, clamp, Cubemap
```

### Materials

Materials (`.material`) define surface appearance. The engine uses a PBR metallic-roughness workflow.

```beef
using Sedulous.Materials;

let mat = Materials.CreatePBR("MyMaterial", "forward");
mat.SetColor("BaseColor", .(0.8f, 0.2f, 0.2f, 1));
mat.SetFloat("Roughness", 0.5f);
mat.SetFloat("Metallic", 0.0f);
```

Material instances can override properties from a base material:

```beef
let instance = new MaterialInstance(baseMaterial);
instance.SetColor("BaseColor", .(1, 0, 0, 1));
```

### Animations

- **AnimationClipResource** (`.animation`) -- skeletal animation clips (bone keyframes)
- **SkeletonResource** (`.skeleton`) -- bone hierarchy
- **AnimationGraphResource** (`.animgraph`) -- blend trees and state machines
- **PropertyAnimationClipResource** (`.propanim`) -- property keyframe tracks (position, color, etc.)

### Audio

- **AudioClipResource** (`.audioclip`) -- decoded audio data plus a binary PCM sidecar
- **SoundCueResource** (`.soundcue`) -- audio playback configuration

Like textures, audio clips split text metadata (sample rate, channels, sidecar filename) from raw PCM bytes; both files live in the same mount and load together.

### Particles

- **ParticleEffectResource** (`.particle`) -- particle system configuration (emitters, behaviors, initializers)

### Scenes and Prefabs

- **SceneResource** (`.scene`) -- a serialized scene (entities + components)
- **PrefabResource** (`.prefab`) -- an entity subtree, instantiable into any scene

Both are loaded through `ResourceSystem.LoadResource<T>(uri)` like any other resource. For runtime instantiation, prefabs are pulled in via `PrefabReferenceComponent`:

```beef
let prefabMgr = scene.GetModule<PrefabComponentManager>();
let entity = scene.CreateEntity("Tower");
let h = prefabMgr.CreateComponent(entity);
if (let refComp = prefabMgr.Get(h))
{
    var prefabRef = ResourceRef(.Empty, "project://prefabs/tower_cannon.prefab");
    defer prefabRef.Dispose();
    refComp.SetPrefabRef(prefabRef);
}
```

`PrefabComponentManager` resolves the URI through the mount table on the next update, reads the prefab's bytes, and instantiates its entities under the component's owning entity.

## Serialization

Resources use the `Sedulous.Serialization` framework (OpenDDL format). Each resource file has a header with type, GUID, name, and source path, followed by resource-specific data.

```
ResourceHeader {
    _type = "texture"
    _id = "a1b2c3d4-..."
    _name = "wood_diffuse"
    _sourcePath = "textures/wood_diffuse.texture"
}
// ... resource-specific data
```

`_sourcePath` is the mount-relative locator the resource was last saved at -- it's not an absolute filesystem path and not a URI either. Loaders that need to reopen siblings (texture pixel sidecar, audio PCM sidecar) compute them by combining the locator's directory with the sidecar filename recorded in the resource.

## Async Loading

Resources can be loaded asynchronously to avoid stalling the main thread. `LoadResourceAsync` returns a `Job<>` that runs on a worker thread:

```beef
// With completion callback (fires on main thread during ResourceSystem.Update)
let job = ResourceSystem.LoadResourceAsync<TextureResource>("project://textures/wood.texture",
    onCompleted: new (result) => {
        if (result case .Ok(let handle))
        {
            let texture = handle.Resource;
            // Use texture on main thread
        }
    });
```

You can also block for the result when you need it:

```beef
let job = ResourceSystem.LoadResourceAsync<StaticMeshResource>("project://models/hero.mesh");

// ... do other work ...

// Block until loaded and get the result
let result = job.WaitForResult();
if (result case .Ok(let handle))
{
    let mesh = handle.Resource;
}
```

Or check completion without blocking:

```beef
if (job.IsCompleted())
{
    let result = job.Result;
}
```

The completion callback fires on the main thread during `ResourceSystem.Update()` (called automatically each frame by `EngineApplication`). For bulk loading, fire multiple async loads -- the resource system processes completions each frame as they finish.

## Hot-Reload

When `ResourceSystem.EnableHotReload()` is called (done by default in `EngineApplication`), the system polls every mount that supports change notifications. Disk mounts watch file modification times; packed-archive mounts don't change at runtime and report no events.

When a tracked locator changes, the resource at that URI is reloaded in place -- components holding refs to it pick up the new contents on the next frame. Listeners can subscribe to reload events:

```beef
class MyListener : IResourceChangeListener
{
    public void OnResourceReloaded(StringView uri, Type resourceType, IResource resource)
    {
        // Reacted to a hot-reload
    }
}

ResourceSystem.AddChangeListener(scope MyListener());
```

## Next Steps

- [Rendering](03_Rendering.md) -- cameras, lights, materials, sky, post-processing
- [Audio](05_Audio.md) -- playing sounds and music
