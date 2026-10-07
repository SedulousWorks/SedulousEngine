# Samples

Low-level Beef samples: each one exercises a part of the engine directly, without a project or
the editor. Games made the usual way, as projects in the editor, are under
`Data/SampleProjects/`. Every sample is a project in the `Code/` workspace
(`BeefBuild -project=Samples.<Name>`) and lands in `Code/build/<Config>_<Platform>/<Project>/`.

## Engine

| Sample | What it shows |
|---|---|
| `HelloWindow` | The smallest application: a window, a frame loop and a cleared backbuffer, through the core, the runtime's context and subsystems, the shell and the host. |
| `MultiWindow` | Two OS windows sharing one graphics device, each with its own render loop and clear colour: the host's per window loop a detachable panel uses. |
| `Sandbox` | The development harness: as much of the renderer as fits in one scene, drawn split screen through an offscreen target (the shape an editor viewport has), with a debug panel for the renderer's settings and a state machine cycling a model's clips. |
| `RenderStressTest` | A deliberate worst case for the renderer: a grid of spheres the camera sees all at once, with unique materials to defeat batching, every transform rewritten each frame, and a MultiMesh mode drawing the grid as one instanced set. |
| `AnimStressTest` | A skinning benchmark: a grid of one cooked character, each with its own animation player over one shared skeleton, mesh and clip set. |
| `AnimatedCrowd` | A crowd drawn as instanced sets rather than entities: one instanced mesh per clip group, the character's parts merged into one mesh, and a shared pose pool animating all of it, the pose chosen per instance by policy. |
| `ParticleFX` | Sixteen particle systems on a 4x4 grid, one per cell, with the authoring pipeline running live in front of it: mesh particles, soft particles, local against world space, a flipbook explosion generated on the CPU, and more. |
| `PhysicsPlayground` | The physics stack under a scene: a crate wall, a cooked ramp and boulder, a kinematic sweeper, a motorised hinge, a character, a trigger volume and raycast shoving, with UI on all three tiers proving a click the UI took does not reach the world. |
| `AudioPlayground` | The audio stack from a component to a speaker: a looping bed on the music bus, four spatial emitters playing one clip at four pitches, a reverb zone, and one shots fired through a cue. |
| `InputActions` | The whole input stack: named actions over keys, pads and touch, an exclusive menu set, the smoothing processors, the time scale, and a rebind overlay saved to the user settings. |
| `TerrainPlayground` | A heightfield built in code, with no cook behind it, drawn by the chunked terrain renderer: rolling hills, a dome, a ripple and a plateau, each stressing a different part of it. |
| `GameUiSandbox` | The game UI kit on screen: a HUD screen and a pause menu pushed over it on the UI subsystem's screen stack, driven by keys or a pad. |
| `NetEcho` | The network stack end to end with no graphics: a reliable server and client over real localhost sockets, the server echoing each line back. |

## Web

| Sample | What it shows |
|---|---|
| `WebTriangle` | The smallest proof the browser stack is wired: a canvas shell, a WebGPU device, a swap chain and one WGSL triangle, made without the content pipeline so it tells "WGSL does not reach the browser" from "the shader pack does not load". |
| `WebScene` | One procedurally built scene touching every renderer feature (an analytic sky baked to IBL, shadowed sun, spot and point lights, a material sphere grid, SSR, TAA, a parallax reflection probe, instancing, decals and sprites), for comparing Vulkan, desktop WebGPU and the browser side by side. The scene is `WebScene.App`; `WebScene` is the desktop entry (`--webgpu` for WebGPU) and `WebScene.Web` the browser's. From before the editor could export a web build, when it was the way to test the web. |

## UI and vector graphics

| Sample | What it shows |
|---|---|
| `VGSandbox` | The vector graphics stack end to end (paths, strokes, gradients, SVG, text), in the style of NanoVG's demo. |
| `UISandbox` | The whole UI stack in one tabbed window: the core's controls, layouts, text input, data views, overlays, drag and drop and animation, the toolkit's bars, property grid, curve editor and node graph, and a viewport and docking demo putting panels into OS windows. |

## RHI

`RHI.Sample001_Triangle` to `RHI.Sample030_RenderBundles` each exercise one feature of the
rendering hardware interface on its own (textures, compute, MSAA, MRT, queries, bindless, mesh
shaders, ray tracing, render bundles and more). They take `--vulkan`, `--webgpu` or `--dx12`.
`RHI.Smoketest` creates one of everything the RHI offers, prints what came back and destroys it:
what to run first on a new machine or after a backend change. `Framework` is the small app base
the numbered samples share, and `Common` the fly camera and data root lookup several samples use.
