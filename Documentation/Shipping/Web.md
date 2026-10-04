# The web

A game exports for the browser like any other target: a preset with `platform` `Web` on a web
template. The player is a page that needs WebGPU (a recent Chrome or Edge on a computer).

## The web template

A web template is the browser player's build, packaged. From a checkout's `Code/`, with
emscripten's environment set (`source <emsdk>/emsdk_env.sh`):

```
BeefBuild -proddir=. -config=Release -platform=wasm32 -project=Sedulous.Engine.Player.Web
Sedulous.Tools.Export --template create Engine/Sedulous.Engine.Player.Web/dist --install
```

The build writes the page, its script, its module and `serve.py` to the project's `dist/`; the
second line installs them as `sedulous-web-release-<engine version>`. A player rebuilt after an
engine change reaches a game only once its template is created and installed again.

## A web export

`project_export` with the Web preset stages the page (named by the preset's `playerName`; a
renamed page keeps `.html`, and `index` serves the export at its folder's root), the player's
`.js` and `.wasm`, `serve.py`, `player.xml`, `Data/Shaders/shaders.dpak` and one content pack
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
