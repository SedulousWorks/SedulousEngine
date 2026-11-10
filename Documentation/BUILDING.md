# Building Sedulous

## Requirements

- Beef, for BeefBuild and the IDE: the engine is built and tested with the Beef it pins,
  `Beef` in `Code/Engine/Sedulous.Engine.Project/src/EngineVersion.bf` (Beef's version and the
  commit of the `working` branch of [our fork](https://github.com/jayrulez/Beef) it is built
  from), which each release also ships for Linux. A
  [Beef nightly](https://nightly.beeflang.org/index.html) of the same version builds it too.
- On Linux, the system's linker and archiver, which BeefBuild links with: `clang++` or `c++`,
  and `ar`.
- Linux x64 or Windows x64. Prebuilt native libraries for both are in the tree under
  `Dependencies/*/dist`, except SDL3 on Linux, which links the system's: install SDL 3.4
  (`libsdl3-dev` or your distribution's equivalent). The dependencies built from source carry a
  `build-native.sh` / `build-native.ps1` to rebuild them.
- A Vulkan 1.3 or D3D12 capable GPU to run anything that draws.
- For web builds, [emsdk](https://emscripten.org/) on the path.

## Building

Everything is one Beef workspace under `Code/`:

```
cd Code
BeefBuild -project=Samples.HelloWindow          # the smallest sample
BeefBuild -project=Sedulous.Tools.Editor         # the editor
BeefBuild -project=Samples.Sandbox               # the engine sandbox
BeefBuild -test -project=Sedulous.Core.Tests     # one test project
```

Outputs land in `Code/build/<Config>_<Platform>/<Project>/`. Executables find the engine's data
by walking up to the `.dataroot` marker in `Data/`, so they run from the build directory, the
project directory or the repository root alike.

## Running the editor

```
Code/build/Debug_Linux64/Sedulous.Tools.ProjectManager/Sedulous.Tools.ProjectManager  # project manager
Code/build/Debug_Linux64/Sedulous.Tools.Editor/Sedulous.Tools.Editor <projectDir>      # open a project
```

Add `--mcp` to serve the project to an agent over MCP while you work in the editor.
`Sedulous.Tools.Mcp` serves MCP without the editor.

## The old editor and UI

The editor is on the GUI: its shell (the dock, menus, assets browser and
dialogs), the scene page, the Game tab, the asset pages and the Profiler page. The old editor on
Sedulous.UI is gone; it last builds at commit e293ee1f. The old UI framework and its UISandbox stay
under `Code/Deprecated/UI`, disabled in every build config.
