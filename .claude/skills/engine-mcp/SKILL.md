---
name: engine-mcp
description: Launch and operate the engine's MCP server (Sedulous.Tools.Mcp) from the engine checkout - the build and wiring recipe here, then the operating manual served by the host itself. Use when working on a game project through the engine headlessly.
---

# The engine MCP server (in checkout launch)

`Sedulous.Tools.Mcp` is the engine's headless MCP host. This skill covers what only makes
sense INSIDE the engine checkout: building and wiring the host. The operating manual
(workflows, validation loops, per tool gotchas) is a SHIPPING doc the host serves to any
connected agent: read `docs://McpGuide.md` via `resources/read` right after connecting
(on disk: `Documentation/Shipping/McpGuide.md`).

## Build and wire

- Build: `cd Code && ~/Dev/BeefFork/IDE/dist/BeefBuild -workspace=. -config=Debug
  -platform=Linux64 -project=Sedulous.Tools.Mcp` (binary:
  `Code/build/Debug_Linux64/Sedulous.Tools.Mcp/Sedulous.Tools.Mcp`).
- Wire: `claude mcp add engine -- <repo>/Code/build/Debug_Linux64/Sedulous.Tools.Mcp/Sedulous.Tools.Mcp`
  (stdio; the server identifies as `engine-mcp`).
- Run it from inside the checkout, or with the cwd in it: the `docs://` resources and
  `known_issues` resolve `Documentation/Shipping/` by walking up from the executable, then
  the cwd.
- STDOUT is the wire; engine logs go to stderr.

## The editor host (the same surface, the LIVE project)

The editor serves the same engine tools over HTTP for the project it has open (server name
`engine-editor-mcp`; `host_info.host.kind` = `editor`), so an agent works on what the user is
looking at: one content database, one writer. Enable it in Preferences (MCP: enabled, port,
token), or for one run: `Sedulous.Tools.Editor <project> --mcp [--mcp-port <n>]`. The default
port is 7405; the token is minted on first enable and written to `<user-data>/mcp-token`
(`~/.local/share/Sedulous/mcp-token` on Linux).

- Wire: `claude mcp add --transport http engine-editor http://127.0.0.1:7405/mcp --header
  "Authorization: Bearer $(cat ~/.local/share/Sedulous/mcp-token)"`.
- The host lives with the project: it starts when a project opens and stops when it closes.
  Calls are answered once per frame on the editor's main thread; a tool that waits on the
  editor (a cook) keeps the call open until it finishes.
- `project_create` and `project_open` are the stdio host's alone: the editor's project is the
  editor's.
- The action bridge (`action_list`, `action_state`, `action_execute`) is everything a user
  can do by menu, chord, toolbar or context menu, over the ACTIVE page: list them first (the
  `enabled` flag is the answer over the active page; `page_open` the page an action needs),
  then execute by id. `action_execute` runs unattended: a dialog the action would open is
  closed as cancelled and named under `suppressedDialogs`. The action then most likely did
  nothing, so use a dedicated tool for that step or ask the user; never retry it blind.
- The page tools (`page_list`, `page_open`, `page_reload`, `page_close`) are the editor host's
  alone, and so are the scene page's live tools (`selection_get`, `selection_set`,
  `simulate_start`, `simulate_stop`, `entity_inspect`, `component_set`, each addressed by the
  page's asset guid). `entity_inspect` is the inspector's view of one entity (hierarchy,
  transform, every component's fields, asset references as guids, enums by name), the
  primary selection by default. `component_set` is the write half: ONE field of one
  component through the editor's undo path, one step per call labelled `mcp`, the page dirty
  after (nothing saves until the page's Save or `file.save`); `value` takes the shape
  `entity_inspect` shows: numbers, booleans, strings, guids, vectors, colours, quaternions, an
  enum case by name or number, an asset guid (or null) for a reference, an entity guid (or
  null) for an entity reference. Refused while the page simulates, on a read-only field, on a list or
  structure, on a wrong shape: nothing changes then. Read, write, read again.
  `viewport_camera_get` / `viewport_camera_set` read and move the viewport's editor camera
  (position, yaw and pitch in degrees, or a `lookAt` point; editor state only, no undo step),
  and `viewport_screenshot` writes what the viewport renders to a PNG (default under
  `<user-data>/screenshots`) and returns the path and size. It brings the page to front (a
  hidden viewport never renders) and waits for the frame, so give it a few seconds. The image
  has the grid, the markers and the selection's gizmo (`selection_set` an empty list first for
  a clean shot), not the panels over the viewport. To look at something: `viewport_camera_set`
  with `lookAt`, then `viewport_screenshot`, then read the file. A `scene_write`
  or `prefab_write` over an asset the user has open reaches its page at once: a clean page
  reloads in place, a page with unsaved edits keeps them and warns the user. Never write over
  it again hoping to win; ask, or `page_reload` with `force` only when the user said to
  discard.

## The two rules that live here

- After rebuilding the engine, compare `host_info`'s `buildStamp` (the executable's write
  time): a host started before the rebuild serves yesterday's engine. Restart it.
- Do NOT point the host at a project an open editor is actively editing: files are truth,
  and two writers share one set of files.

## First action after connecting

`resources/read` -> `docs://McpGuide.md`, then follow it. Keep BOTH documents honest: when
tools change, the guide (and this skill, if the wiring changed) updates in the same commit.
