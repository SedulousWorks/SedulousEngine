# Sedulous Engine Documentation

Sedulous is a code-first game engine written in [Beeflang](https://www.beeflang.org/)
with Vulkan / DX12 rendering backends and an ECS-style scene system.
Everything is driven by code — scenes, entities, components, and
resources are all created and configured programmatically. An optional
editor is available for visual scene authoring and asset management,
but it is not required.

This directory holds three kinds of documentation:

- **[Manual/](Manual/)** — usage-facing guides. Start here if you're
  building a game on the engine.
- **[Developer/](Developer/)** — technical reference for engine
  internals. Read this if you're contributing to the engine itself,
  designing an editor extension, or trying to understand architectural
  decisions.
- **[Roadmap/](Roadmap/)** — design / planning docs for in-flight
  work, shipped milestones, and deferred ideas.

## Manual

Step-by-step guides for building with the engine.

| Chapter | Topic |
|---------|-------|
| [00 - Getting Started](Manual/00_GettingStarted.md) | Project setup, first app, minimal scene with camera / light / mesh |
| [01 - Scenes and Entities](Manual/01_ScenesAndEntities.md) | Scene lifecycle, entities, transforms, hierarchy, components, update phases |
| [02 - Resources](Manual/02_Resources.md) | Resource system, registries, loading, async loading, hot-reload |
| [03 - Rendering](Manual/03_Rendering.md) | Cameras, lights, meshes, materials, shadows, sprites, decals, post-processing |
| [04 - Input](Manual/04_Input.md) | Keyboard, mouse, gamepad, action / binding system, input contexts |
| [05 - Audio](Manual/05_Audio.md) | Clips, sources, 3D spatialization, bus system, effects, sound cues |
| [06 - Animation](Manual/06_Animation.md) | Skeletal animation, property animation, animation graphs |
| [07 - User Interface](Manual/07_UI.md) | View hierarchy, layouts, controls, styling, drag-drop, screen / world-space UI |
| [08 - Physics](Manual/08_Physics.md) | Rigid bodies, collision shapes, body types |
| [09 - Particles](Manual/09_Particles.md) | Particle effects, emitters, behaviors, emission shapes, soft particles |
| [10 - Navigation](Manual/10_Navigation.md) | NavMesh agents, obstacles, pathfinding |
| [11 - Engine Architecture](Manual/11_EngineArchitecture.md) | Context, subsystems, custom gameplay systems, messaging, update loop |
| [12 - Editor](Manual/12_Editor.md) | Scene editor, asset browser, inspector, prefabs, layout persistence |

## Developer

Technical reference for engine internals.

| Document | Topic |
|---|---|
| [Architecture.md](Developer/Architecture.md) | Module map, dependency layering, subsystem responsibilities |
| [UI.md](Developer/UI.md) | UI framework guide: View hierarchy, markup, styling cascade, drawables, custom controls |
| [VFS.md](Developer/VFS.md) | Virtual filesystem design, mounts, paths, pak files |
| [DebuggingTip.txt](Developer/DebuggingTip.txt) | Misc debugging notes |

## Roadmap

Design + planning docs live in [Roadmap/](Roadmap/). Shipped work
carries a `_DONE` suffix; not-started work is `_TODO`; everything
else is in flight. `UI_DEFERRED.md` consolidates items intentionally
postponed from shipped tracks.

## Plans

[Plans/](Plans/) holds longer-form design exploration that hasn't yet
been promoted to the roadmap.
