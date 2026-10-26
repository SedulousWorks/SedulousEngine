# RaptorCode: the GUI port ledger

Raptor's GUI, copied verbatim so it can be ported to Beef by striking: each port commit adds the
Beef code with its tests and, in the same commit, deletes from here exactly the C++ it ported, so
the diff shows the C++ removed beside the Beef added. A partly ported file keeps what is still to
do. What remains here is what is left to port. Nothing in this folder is built.

## Source

Raptor branch `vg` at **4fe177db2** ("Samples: WebScene draws its UI through the engine GUI"),
on top of master 287ddc135. Copied with `git archive`, so only committed files are here.

A later Raptor change to a file not yet ported means copying that file again. A change to a file
already ported is ported as a normal sync commit.

## Layout

The port is complete: every file below has been struck, and this README is all that is left.
The paths were Raptor's.

- `Code/Foundation/GUI*`: the GUI libraries and their tests (the core, Code, Docking, Gamekit,
  Hosting, Inspector, Resources, Shell, Testing, Toolkit, VFS, Viewport, Fuzz). In Sedulous they
  become `Foundation/Sedulous.GUI.*`.
- `Code/Engine/Engine.GUI*`, `Code/Editor/Editor.GUI*`, `Code/Pipeline/GUI.Pipeline*`: the engine
  hosting and script facade, the editor's GUI pages, and the cook.
- `Code/Samples/GUISandbox`: the sandbox sample.
- `Code/Integration/Integration.GuiScript`: the GUI script integration tests.
- `Data/Assets/ui/sandbox`, `Data/Assets/ui/showcase`: what the sandbox loads. `Data/Tests/GUI`:
  the reference images and the fuzz input. Ported by moving them to the same place in `Data/`.
- `Hunks/<path>.diff`: changes the GUI makes to files outside its own projects, as
  `git diff 287ddc135 4fe177db2 -- <path>`. Struck hunk by hunk as each one is ported.
- `CMakeLists.txt`: each project's dependencies. Struck when the project's BeefProj.toml lands.

## Left out on purpose

- `Code/Experimental/*`: the lab's old location, deleted by the move.
- Comment-only renames ("the GUI lab" -> "the GUI") in `Foundation/UI.Shell/UiInputBridge.cppm`,
  `Foundation/UI/Core/Transform2D.cppm`, `Foundation/UI/Styling/StyleValue.cppm` and
  `Foundation/I18N.Tests/StringTableTests.cpp`.
- `Foundation/Core.Tests/allocator-allowlist.txt`: Raptor's C++ allocator check, no counterpart
  here.
- The root and directory CMakeLists, the READMEs, and the specs and plans
  (`Documentation/Specs/gui-lab-evolution*.md`, `vg-and-gui-lab.md`, `Systems/gui-port.md`,
  `Plans/backlog-0.2.md`): read them in Raptor.
- Struck while porting, with no Beef counterpart:
  - `GUI.Tests/TestsMain.cpp`: the doctest main, whose one job was to install HarfBuzz before
    any test; Sedulous.GUI.Tests' text fixtures install it.
  - `GUI.Fuzz.Tests/LibFuzzer.cpp`: the optional libFuzzer entry, which the spec leaves out
    (Beef has no libFuzzer); the targets are FuzzTargets.FuzzOne.
  - `GUISandbox/lsan.supp`: asan-test.py runs only test projects.
  - The Luau half of every Integration.GuiScript story: Sedulous has AngelScript only.
