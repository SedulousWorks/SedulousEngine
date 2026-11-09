# The web

A game exports for the browser like any other target: a preset with `platform` `Web`. The export
builds the game's own web player (its `<Game>PlayerWeb`, in the project's generated web workspace
`Code/.generated/Web`) for the preset's config, with the game's code and the plugins it enables on
the web, and packages it. The player is a page that needs WebGPU (a recent Chrome or Edge on a
computer).

## What a web build needs

BeefBuild builds for wasm32 through Emscripten, which it finds by `EmscriptenPath` under `[Wasm]`
in its own `BeefSettings.toml`: beside BeefBuild for a build from source, under
`~/.config/beeflang/` for a packaged one. The path is the emsdk folder, holding
`upstream/emscripten/emcc`; Beef's wasm runtime must have been built with it once. An export whose
Emscripten is not found is refused before anything builds, saying what to set (`export_presets`
says so per preset, as `buildable` and `why`).

The build lands in `Code/.generated/Web/build/<Config>_wasm32/<Game>PlayerWeb/`, a folder per
config; a project's first web build compiles the engine for wasm32 and takes minutes, the rest are
incremental. A preset's `Release` is the shipping build (ShippingRelease, Release without the
profiler); `Profile` builds Release itself, with the profiler, its overlay and its capture. On a
page of a Profile build, `?profile-overlay` in the address (for example
`http://localhost:8000/?profile-overlay`) shows the profiler overlay from the start, as the
desktop player's `--profile-overlay` does; F3 toggles it either way.

## A web export

`project_export` with the Web preset stages the page (named by the preset's `playerName`; a
renamed page keeps `.html`, and `index` serves the export at its folder's root), the player's
`.js` and `.wasm`, `serve.py`, `player.xml`, `Data/Engine/Shaders/shaders.dpak` and one content pack
per texture family (`Content-bc.pak`, `Content-astc.pak`); the page fetches the one the
browser's GPU reads. The cooks behind those packs land in `<project>/Cooked-web-bc` and
`Cooked-web-astc`, generated like `Cooked/`.

## Serving it

A browser will not run a page opened as a file. From the export's folder:

```
python3 serve.py              # http://localhost:8000/
python3 serve.py 8443 --https # for another device on the network
```

WebGPU exists only in a secure context: a page from `localhost`, or over HTTPS. Opened from
another machine by this one's address over plain HTTP, the page loads and says it cannot use
WebGPU. `--https` serves it with a self-signed certificate, made once with `openssl` and kept
beside the script (`serve-cert.pem`, `serve-key.pem`); the browser warns the first time, and
accepting the warning makes the page a secure context. `--cert` and `--key` take your own.
`serve.py` prints the addresses another device can open.

## The page

Until the game runs, the page shows the game's name and what is downloading. If the browser
has no WebGPU, or cannot use it on that computer, the page says so in plain words instead of
downloading the game. When the game quits, the page comes back with Play again.

## Saves and settings

The player keeps a game's save and the user's settings in the browser's storage (IndexedDB),
so they outlive the page. That storage belongs to the page's origin: the same game served from
another address or port starts with an empty save. A private window that refuses the storage
keeps them for the page only.
