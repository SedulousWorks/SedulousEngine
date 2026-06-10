# Rendering

Sedulous uses a forward PBR renderer with a multi-pass pipeline. `RenderSubsystem` handles scene rendering and is automatically registered when you use `EngineApplication`.

## Cameras

Every scene needs at least one active camera to render. Cameras are components on entities -- the entity's transform determines the camera's position and orientation.

```beef
let cameraEntity = scene.CreateEntity("Camera");
scene.SetLocalTransform(cameraEntity, Transform.CreateLookAt(
    .(0, 5, 10), .(0, 0, 0)
));

let cameraMgr = scene.GetModule<CameraComponentManager>();
if (let cam = cameraMgr.Get(cameraMgr.CreateComponent(cameraEntity)))
{
    cam.IsActive = true;
    cam.FieldOfView = 60.0f;
    cam.NearPlane = 0.1f;
    cam.FarPlane = 1000.0f;
}
```

Only one camera can be active at a time. The active camera is used for the main view render.

## Lights

Three light types are supported:

### Directional Light

Simulates sunlight -- parallel rays with no falloff. The entity's orientation determines the light direction.

```beef
let sun = scene.CreateEntity("Sun");
scene.SetLocalTransform(sun, .() {
    Position = .Zero,
    Rotation = Quaternion.CreateFromYawPitchRoll(0.3f, -0.8f, 0),
    Scale = .One
});

let lightMgr = scene.GetModule<LightComponentManager>();
if (let light = lightMgr.Get(lightMgr.CreateComponent(sun)))
{
    light.Type = .Directional;
    light.Color = .(1, 0.95f, 0.9f);
    light.Intensity = 2.0f;
    light.CastsShadows = true;
    light.ShadowBias = 0.002f;
}
```

### Point Light

Emits light in all directions from the entity's position, with distance attenuation.

```beef
light.Type = .Point;
light.Range = 10.0f;
light.Intensity = 5.0f;
```

### Spot Light

Directional cone of light from the entity's position along its forward axis.

```beef
light.Type = .Spot;
light.Range = 15.0f;
light.InnerConeAngle = 20.0f;
light.OuterConeAngle = 35.0f;
```

## Meshes

Static meshes are the primary way to display 3D geometry. Attach a `MeshComponent` to an entity and set its mesh resource reference.

```beef
let meshMgr = scene.GetModule<MeshComponentManager>();
if (let mesh = meshMgr.Get(meshMgr.CreateComponent(entity)))
{
    var meshRef = ResourceRef(.Empty, "project://models/building.mesh");
    defer meshRef.Dispose();
    mesh.SetMeshRef(meshRef);

    // Optionally set per-slot materials
    var matRef = ResourceRef(.Empty, "project://materials/brick.material");
    defer matRef.Dispose();
    mesh.SetMaterialRef(0, matRef);
}
```

### Skinned Meshes

For animated characters, use `SkinnedMeshComponent` with a skeleton and animation:

```beef
let skinnedMgr = scene.GetModule<SkinnedMeshComponentManager>();
if (let mesh = skinnedMgr.Get(skinnedMgr.CreateComponent(entity)))
{
    var meshRef = ResourceRef(.Empty, "project://models/character.mesh");
    defer meshRef.Dispose();
    mesh.SetMeshRef(meshRef);
}
```

## Materials

Materials use a PBR metallic-roughness workflow. The default shader (`forward`) supports:

| Property | Type | Description |
|----------|------|-------------|
| `BaseColor` | Color | Albedo color multiplied with texture |
| `Roughness` | Float | Surface roughness (0 = mirror, 1 = diffuse) |
| `Metallic` | Float | Metalness (0 = dielectric, 1 = metal) |
| `AlphaCutoff` | Float | Alpha test threshold (for masked materials) |
| `AlbedoMap` | Texture | Base color texture |
| `NormalMap` | Texture | Normal map |
| `MetallicRoughnessMap` | Texture | R = metallic, G = roughness |
| `EmissiveMap` | Texture | Emissive glow texture |

Materials are typically created by the import pipeline or the editor. For programmatic creation:

```beef
let mat = Materials.CreatePBR("RedPlastic", "forward");
mat.SetColor("BaseColor", .(0.8f, 0.1f, 0.1f, 1));
mat.SetFloat("Roughness", 0.4f);
mat.SetFloat("Metallic", 0.0f);

let matRes = new MaterialResource(mat, true);
ResourceSystem.AddResource<MaterialResource>(matRes);
```

### Blend Modes

```beef
mat.SetBlendMode(.Opaque);       // Default, no transparency
mat.SetBlendMode(.Masked);       // Alpha test with AlphaCutoff
mat.SetBlendMode(.AlphaBlend);   // Transparent blending
mat.SetBlendMode(.Additive);     // Additive blending (particles, glow)
```

## Render Settings

Scene-level rendering parameters are stored on `RenderSceneModule`, automatically injected into every scene.

```beef
if (let rs = scene.GetModule<RenderSceneModule>())
{
    // Sky
    var skyRef = ResourceRef(.Empty, "builtin://skies/realistic_sky.texture");
    defer skyRef.Dispose();
    rs.SetSkyTextureRef(skyRef);
    rs.SkyIntensity = 1.2f;

    // Ambient
    rs.AmbientColor = .(0.1f, 0.1f, 0.15f);

    // Post-processing
    rs.Exposure = 1.0f;
}
```

These values are serialized with the scene and editable in the editor inspector when no entity is selected.

## Shadows

Shadows are automatic for lights with `CastsShadows = true`. The renderer supports:

- **Cascaded shadow maps** for directional lights (4 cascades)
- **Cubemap shadows** for point lights (6 faces)
- **Perspective shadows** for spot lights

Shadow quality is controlled per-light:

```beef
light.CastsShadows = true;
light.ShadowBias = 0.002f;
light.ShadowNormalBias = 0.5f;
```

## Sprites

Textured billboard quads for in-world effects, icons, or 2D elements.

```beef
let spriteMgr = scene.GetModule<SpriteComponentManager>();
if (let sprite = spriteMgr.Get(spriteMgr.CreateComponent(entity)))
{
    var texRef = ResourceRef(.Empty, "project://textures/icon.texture");
    defer texRef.Dispose();
    sprite.SetTextureRef(texRef);
    sprite.Size = .(1, 1);
    sprite.Orientation = .CameraFacing;  // Also: .CameraFacingY, .WorldAligned
}
```

## Decals

Projected textures onto surfaces using depth reconstruction.

```beef
let decalMgr = scene.GetModule<DecalComponentManager>();
if (let decal = decalMgr.Get(decalMgr.CreateComponent(entity)))
{
    var texRef = ResourceRef(.Empty, "project://textures/scorch.texture");
    defer texRef.Dispose();
    decal.SetTextureRef(texRef);
    decal.Size = .(2, 2, 0.5f);  // Width, height, depth of projection box
}
```

## Post-Processing

The renderer includes a post-processing stack with the following effects (in order):

| Effect | Description |
|--------|-------------|
| **SSAO** | Screen-space ambient occlusion. Darkens crevices and contact areas. |
| **Bloom** | Bright areas glow. Downsample/upsample chain composited in HDR before tonemapping. |
| **TAA** | Temporal anti-aliasing. Jittered sampling with motion-vector reprojection. |
| **Tonemap** | ACES filmic tone mapping. Composites AO and bloom. Configurable exposure. |
| **FXAA** | Fast approximate anti-aliasing on the final LDR image. |

Post-processing is configured programmatically on the pipeline's `PostProcessStack`. `RenderSceneModule.Exposure` controls the tonemap exposure.

## Debug Drawing

`DebugDraw` provides immediate-mode 3D and 2D debug visualization:

```beef
let dbg = renderSub.DebugDraw;

// 3D (depth-tested)
dbg.DrawLine(.(0, 0, 0), .(5, 5, 0), .(1, 0, 0, 1));
dbg.DrawWireBox(bounds.Min, bounds.Max, .(0, 1, 0, 1));
dbg.DrawWireSphere(center, radius, .(0, 0, 1, 1));

// 2D screen overlay
dbg.DrawScreenText(10, 10, "FPS: 60", .(1, 1, 1));
dbg.DrawScreenRect(5, 5, 200, 30, .(0, 0, 0, 180));
```

Debug geometry is cleared each frame. Call draw methods during `OnUpdate()`.

## Render Pipeline

The rendering pipeline executes these passes in order:

1. **Compute Skinning** -- pre-skins animated meshes via compute shader
2. **Depth Prepass** -- writes depth for opaque geometry (early-Z)
3. **Forward Opaque** -- PBR lighting for opaque + masked geometry, writes mini G-buffer (normals, motion vectors)
4. **Decals** -- depth-reconstructed projected textures
5. **Sky** -- equirectangular or cubemap sky at depth == far
6. **Forward Transparent** -- alpha-blended geometry (sprites, particles, transparent meshes)
7. **Particles** -- soft particle rendering with depth fade
8. **Debug** -- debug lines and wireframes (depth-tested)
9. **Overlay** -- 2D screen-space text and rectangles
10. **Post-Processing** -- SSAO, Bloom, TAA, Tonemap, FXAA

## Next Steps

- [Input](04_Input.md) -- keyboard, mouse, gamepad
- [Audio](05_Audio.md) -- sounds and music
