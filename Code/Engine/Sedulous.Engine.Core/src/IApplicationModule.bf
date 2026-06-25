namespace Sedulous.Engine;

using System;
using Sedulous.Runtime;
using Sedulous.Resources;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Engine.Core;

/// Services the application host exposes to its IApplicationModule.
///
/// Both EngineApplication (standalone game exe) and the editor (when it
/// loads a project module against its runtime context) implement this.
/// Keeping the surface narrow to what's actually needed for module
/// configuration / startup avoids dragging RHI or shader types into
/// Engine.Core - subsystems registered by the module reach those through
/// Context.GetSubsystem<>.
public interface IApplicationHost
{
	/// The Context this module is being hosted in. Modules register their
	/// subsystems here during Configure and resolve other subsystems via
	/// Context.GetSubsystem<> during OnStartup.
	Context Context { get; }

	/// Shared resource system. Modules can register additional
	/// IResourceManager / IResourceIndex during Configure or load initial
	/// content during OnStartup.
	ResourceSystem ResourceSystem { get; }

	/// Platform shell - exposes InputManager, clipboard, etc. Needed by
	/// project-level OnUpdate logic that hasn't been factored into a
	/// Subsystem yet (transitional).
	IShell Shell { get; }

	/// Mouse the module should consume during OnUpdate. Standalone hosts
	/// passthrough to `Shell.InputManager.Mouse`. The editor's
	/// `GameEditorPage` returns a viewport-scoped adapter so cursor
	/// coords are in the page-viewport's local space and click events
	/// match the rendered scene - the page texture is a sub-rect of the
	/// editor window, so polling shell directly would put clicks in
	/// the wrong coordinate space.
	IMouse Mouse { get; }

	/// Keyboard the module should consume during OnUpdate. Standalone
	/// hosts passthrough to `Shell.InputManager.Keyboard`. The editor's
	/// `GameEditorPage` returns a focus-gated adapter that reports
	/// "nothing pressed" while the game viewport is not focused, so
	/// gameplay hotkeys (P / Escape / Space / etc.) don't fire while
	/// the user is typing in another panel.
	IKeyboard Keyboard { get; }

	/// Returns a gamepad the module can consume during OnUpdate.
	/// Standalone passes through to `Shell.InputManager.GetGamepad`.
	/// Editor returns a focus-gated adapter (passthrough when game
	/// viewport focused, no-input otherwise) so controller input is
	/// scoped to the game tab. Returns null if `index` is out of range.
	IGamepad GetGamepad(int32 index);

	/// Main application window (single-window for now). Modules that need
	/// window dimensions or DPI for one-time setup read it here.
	IWindow Window { get; }

	/// Discovered Assets directory (the engine's Assets/, with the
	/// .assets marker file). Absolute path; valid for the lifetime of the
	/// host.
	StringView AssetDirectory { get; }

	/// Cache directory under Assets (e.g. compiled shader cache).
	StringView AssetCacheDirectory { get; }

	/// Per-project assets directory. For standalone, derived from
	/// RuntimeDirectory via the standard "exe under project root with
	/// sibling assets/ folder" convention. For the editor's hosted
	/// module, the currently-open project's assets path. Distinct from
	/// AssetDirectory (engine-shipped Assets root). May be empty if the
	/// convention doesn't apply.
	StringView ProjectAssetDirectory { get; }

	/// Process working directory at startup. For standalone games, the
	/// project's runtime root. For the editor's hosted module, the
	/// loaded project's root.
	StringView RuntimeDirectory { get; }

	/// Combines a relative path under AssetDirectory into outPath. Helper
	/// for modules loading per-project assets.
	void GetAssetPath(StringView relativePath, String outPath);
}

/// Composition contract for the payload an application hosts.
///
/// An IApplicationModule describes what an application "is" without saying
/// how it runs - it registers subsystems and performs lifecycle hooks against
/// a Context, but does not itself tick. Per-frame logic lives in the Subsystems
/// the module registers (gated by Subsystem update phase + SceneModule
/// simulationOnly when applicable).
///
/// Hosts:
///   - EngineApplication (standalone game exe) invokes a single module's
///     lifecycle around its main loop.
///   - Editor (in a later phase) instantiates a project's module at project
///     load time so the project's component types and subsystems are visible
///     in the inspector and on scenes during edit mode. Play / Simulate
///     buttons drive Scene.Start() / Scene.Stop(); the module itself does
///     not have a Play lifecycle - simulation gating belongs to the scene.
public interface IApplicationModule
{
	/// Register subsystems and component types with the host's context.
	/// Called once after the host registers its default subsystems and before
	/// Context.Startup() runs. The module may add Subsystems, set application-
	/// wide configuration, or hook ResourceSystem extensions here.
	void Configure(IApplicationHost host);

	/// One-time setup hook fired after Context.Startup() completes. Always
	/// runs - in standalone hosts before the main loop, in embedded hosts
	/// (like the editor) at host startup. Subsystems are initialized at this
	/// point; use this for module-persistent state such as registering
	/// message handlers or resolving subsystem references that the module
	/// retains for its lifetime.
	void OnStartup(IApplicationHost host);

	/// Host is entering its runtime / play mode. For standalone hosts fires
	/// once after OnStartup, before the main loop begins. For embedded hosts
	/// (editor) fires when the user explicitly launches a play session - at
	/// edit time it does NOT fire. Use for work that only makes sense when
	/// the runtime is actually about to run: loading the initial scene,
	/// spawning the player, hooking input, initialising gameplay UI.
	void OnLaunch(IApplicationHost host);

	/// Per-frame tick fired between OnLaunch and OnExit. Hosts call this
	/// after Context.Update and OnPostUpdate so subsystems have already
	/// run their phase. Use for module-glue logic that doesn't naturally
	/// fit in a Subsystem - polling shell input that drives gameplay
	/// (camera, tower placement), debug-draw passes that need access to
	/// the module's owned objects, particle-effect lifetime sweeps, etc.
	///
	/// Default implementation is a no-op so modules that don't need
	/// per-frame work don't have to override.
	void OnUpdate(IApplicationHost host, float deltaTime) { }

	/// Fixed-timestep tick fired between OnLaunch and OnExit alongside
	/// Context.FixedUpdate (once per accumulator step). Use for
	/// deterministic gameplay logic that needs a fixed dt: rollback,
	/// network-style state advancement, or anything that pairs with
	/// physics-rate subsystems. Skip this when per-frame timing is fine -
	/// OnUpdate is cheaper.
	///
	/// Default implementation is a no-op.
	void OnFixedUpdate(IApplicationHost host, float fixedDeltaTime) { }

	/// Mirrors OnLaunch - host is leaving its runtime / play mode. In
	/// standalone hosts fires after the main loop and before OnShutdown.
	/// In embedded hosts fires when the user stops a play session. Use for
	/// tearing down anything OnLaunch set up.
	void OnExit(IApplicationHost host);

	/// Symmetric teardown hook fired before Context.Shutdown(). Always
	/// runs - mirror of OnStartup. Subsystems are still alive at this point
	/// so the module can publish final state or release references it owns.
	void OnShutdown(IApplicationHost host);

	/// Scene the host should treat as the module's "active" runtime scene
	/// while OnLaunch's lifecycle is in effect. Null when no scene exists
	/// (between OnExit and the next OnLaunch, or for modules that don't
	/// expose a single primary scene). The editor's GameEditorPage reads
	/// this to know which scene to render into its viewport.
	Scene RuntimeScene { get; }
}
