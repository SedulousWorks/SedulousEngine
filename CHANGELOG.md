# Changelog

What changed in SedulousEngine between releases, newest first. A change that someone using the
engine, the editor or a game made with it would notice gets a line under **Unreleased** in the
commit that makes it; a release turns Unreleased into its version and date. The steps are in
[AGENTS.md](AGENTS.md), under Releases.

## Unreleased

### Changed

- Editor: a scene's Simulate runs on its own, apart from every other page: its scripts' screens
  draw over the page's viewport while it simulates and go when it stops.

### Fixed

- Editor: importing an asset no longer freezes the editor for seconds in a large project: each
  import read every asset in the project to check one file name.
- Editor: context menus open at the pointer under a UI scale other than 100%, and a tab's Move to
  opens below its tab.
- Editor: the UI scale preference shows its percentage while its slider is dragged.
- Editor: Add Component is disabled while a scene simulates, as the rest of the inspector is.
- Cook: GUI documents and style sheets no longer lose elements, or leak, when several cook at once.
