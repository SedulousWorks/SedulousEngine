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

## The two rules that live here

- After rebuilding the engine, compare `host_info`'s `buildStamp` (the executable's write
  time): a host started before the rebuild serves yesterday's engine. Restart it.
- Do NOT point the host at a project an open editor is actively editing: files are truth,
  and two writers share one set of files.

## First action after connecting

`resources/read` -> `docs://McpGuide.md`, then follow it. Keep BOTH documents honest: when
tools change, the guide (and this skill, if the wiring changed) updates in the same commit.
