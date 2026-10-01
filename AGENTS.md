# Working on Sedulous: notes for agents

How to build, test and change this engine without breaking it. The README describes what the
engine is; this is how to work in it.

## Build

Everything is one Beef workspace under `Code/`. BeefBuild comes from a recent Beef nightly, or
the `working` branch of [the fork](https://github.com/jayrulez/Beef). Run it from `Code/`:

```
BeefBuild -proddir=. -config=Debug -platform=Linux64 -project=Sedulous.Tools.Editor
BeefBuild -proddir=. -platform=Linux64 -test -project=Sedulous.Core.Tests
```

- Outputs land in `Code/build/<Config>_<Platform>/<Project>/`.
- Build ONE project at a time, and never beside another heavy build (a second BeefBuild, the
  Steam Deck container, another engine's build). Two at once has run the machine out of memory.
- A tool built before a change does not have it: rebuild the editor, the player or
  `Sedulous.Tools.Mcp` after changing what they use. The script compiler lives in them too, so
  a stale editor fails to compile a game script that uses new script API.

## Test

- Every Foundation and Engine module has a sibling `.Tests` project; `Code/Integration/` holds
  the flows that cross collections. Run the tests of every project a change touches, and add a
  test for each behaviour you change or fix.
- On Linux a plain `BeefBuild -test` run reports NO leaks: the debug runtime is built without
  its leak checker. Check new or changed tests for leaks and memory errors with
  `python3 Code/Tools/asan-test.py <TestProject> [name filter]` after building them: exit 0 is
  clean; a nonzero exit with no test failures is a leak, its stacks printed above. A Vulkan
  backend test also reports a known leak inside libdbus; read past it for engine frames.
- Tests write `scratch_*/` directories beside the project they run from; those are ignored.

## Change

- **Verify, don't guess.** Read the source, or run it, before relying on or stating a
  constant, a count or an API's behaviour (ownership, what a call deletes, what it returns).
- **Match the code around you**: its naming (`mField` for private fields, PascalCase types and
  members), its ownership idioms (`~ delete _`, `scope`, `defer`), its comment density and
  voice (`///` on what is not obvious, saying why).
- **Keep the documents honest in the same commit.** A change to the MCP tools updates
  `Documentation/Shipping/McpGuide.md`; the engine tool count (`EngineTools.cEngineToolCount`)
  is a deliberate tripwire, bumped when a tool is added.
- **Commits**: one per piece of work, the subject `Area: what it does` with a body saying why,
  and no `Co-Authored-By` or session trailer lines. Push only when asked.
- **Third-party content**: check its licence before adding it. Nothing goes in that may not be
  published (a "free for personal use" font may not); keep the licence text beside it, and
  credit what requires it.

## Raptor

Raptor (C++) is this engine's mirror in another language; the two move together. It is the
reference for how a feature should behave. Syncs run from Raptor to Sedulous and carry code,
not transliterated idiom: Beef's way wins. `Documentation/Changes.md` lists what changed from
the previous engine, on the `v0` branch.

## Agent tooling

- `Sedulous.Tools.Mcp` is the headless MCP host; the editor serves the same tools over HTTP for
  its open project (`--mcp` or `--mcp-port <port>`), plus page and play-in-editor tools.
  `.claude/skills/engine-mcp` is the recipe to build and wire it; once connected, read
  `docs://McpGuide.md` (`Documentation/Shipping/McpGuide.md`), the operating manual.
- When an MCP tool is missing or wrong for a task, that is a finding: fix the tool in the
  engine, rather than routing around it by editing project files by hand.

## Sample projects

`Data/SampleProjects/` holds game projects: **Sky Hopper** (`PlatformerGame`), built entirely
through the MCP tools, and **PaperKid**, unfinished. Their `Cooked/`, `.cache/`, `Editor/` and
`Dist/` are generated and ignored. Sky Hopper's `CREDITS.md` and `Licenses/` must stay in step
with its assets.

## Steam Deck

`Code/Tools/SteamDeck/build-steamdeck.sh` builds a player in an Ubuntu 22.04 container (glibc
2.35, below SteamOS), Beef included, and installs it as the `sedulous-steamdeck-release-<ver>`
export template. It needs podman or docker, and nothing else building beside it.
