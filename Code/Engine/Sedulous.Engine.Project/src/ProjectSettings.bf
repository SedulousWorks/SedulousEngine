using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;

namespace Sedulous.Engine.Project;

/// The shared, committed part of a project: the Project.xml payload.
///
/// Also the distribution manifest, which is the same shape without the editor's concerns.
/// It lives in the runtime rather than the editor so a shipping binary carries no editor
/// code to read the project it was built from.
///
/// A guid is the AUTHORITATIVE reference in every pair below and survives a rename or a
/// move; the string beside it is the readable mirror, and the fallback for a manifest
/// written before its guid existed.
///
/// A field marked [Setting] is one the Project Settings dialog and the MCP tools offer, on the
/// tab its category names (General, Startup, Audio, UI, Display, in the order first named).
///
/// FIELD ORDER IS THE WIRE: the generator walks the declaration, so inserting a field in the
/// middle changes what existing manifests mean. Append, and bump the version when the shape
/// has to change. Version 10 dropped the old UI's theme and loading document (Engine.UI,
/// deleted); a version 9 manifest still reads, its keyed reader passing the two by. A field
/// dropped without a version bump is passed by the same way: nativeModule, the library path
/// of a game's native module, went when a game's native code became a package of the
/// project's (Plugins/<Name>), and a manifest that names one reads with the path dropped.
/// Version 11 dropped the startup script (startupScript and startupScriptId) when a game's code
/// became native and scripts stopped running; a version 9 or 10 manifest still reads, the
/// keyed reader passing the two by.
[Serializable(11, false, 9)]
class ProjectSettings
{
	[Setting("Name", "General")]
	public String Name = new .() ~ delete _;
	/// The engine that last saved this project. Re-stamped on every save. Named for the WIRE
	/// KEY, which the generator derives from the field name.
	public String EngineVersion = new .() ~ delete _;

	[Setting("Default scene", "SceneDocument", "(none)", "Startup"), SettingSummary("Default scene")]
	public Guid DefaultSceneId;
	/// The default scene's source database path.
	public String DefaultScene = new .() ~ delete _;

	/// The input map bound at startup. Nil for none.
	[Setting("Default input map", "InputMapAsset", "(none)", "Startup"), SettingSummary("Input map")]
	public Guid DefaultInputMapId;
	/// The mixer layout applied at startup. Nil for the built in one.
	[Setting("Default bus layout", "AudioBusLayoutAsset", "(built-in)", "Audio")]
	public Guid DefaultBusLayoutId;
	/// The cooked font the game UI defaults to. Nil for the development fallback.
	[Setting("Default UI font", "FontAsset", "(built-in)", "UI"), SettingSummary("UI font")]
	public Guid DefaultUiFontId;

	/// The scene pass sample count: one is off. Clamped to what the device can do at
	/// runtime, so a project asking for more than the hardware has still runs.
	[Setting("MSAA", "Display")]
	public uint32 RenderMsaaSamples = 1;

	/// Cooked fonts the game UI loads BESIDE the default one, each its own family, which a
	/// label picks by `font-family` (a title face beside the body text). [Appended], so a
	/// manifest saved before it reads as none.
	[Appended, Setting("Other UI fonts", "FontAsset", "(none)", "UI")]
	public List<Guid> UiFontIds = new .() ~ delete _;

	/// The resolution the game DRAWS at, fitted into whatever shows it (the player's window,
	/// the editor's Game tab) by RenderFit. Nought on either axis draws at the output's own
	/// size, which is what a game that adapts to any size wants.
	[Appended, Setting("Render width", "Display"), Range(0, 16384, 1)]
	public uint32 RenderWidth = 0;
	[Appended, Setting("Render height", "Display"), Range(0, 16384, 1)]
	public uint32 RenderHeight = 0;
	/// How a fixed render resolution maps onto an output of another shape.
	[Appended, Setting("Render fit", "Display")]
	public FitMode RenderFit = .Letterbox;

	/// The player's window: its size (ignored by Borderless, which takes the display's), how
	/// it takes the screen, and whether the user may resize it. An export preset overrides
	/// these per platform.
	[Appended, Setting("Window width", "Display"), Range(1, 16384, 1)]
	public uint32 WindowWidth = 1280;
	[Appended, Setting("Window height", "Display"), Range(1, 16384, 1)]
	public uint32 WindowHeight = 720;
	[Appended, Setting("Window mode", "Display")]
	public WindowMode WindowMode = .Windowed;
	[Appended, Setting("Window resizable", "Display")]
	public bool WindowResizable = true;
	/// The shape the game is made for: Any takes the window's; Landscape or Portrait is
	/// presented turned on a window of the other shape (a landscape game on a phone held
	/// upright). An export preset overrides it per platform.
	[Appended, Setting("Orientation", "Display")]
	public ScreenOrientation Orientation = .Any;

	/// The engine GUI's cooked sheets, in order over its built in theme, each over those before
	/// it (a game's own over a shared one). Its fonts are the UI's. [Appended], so a manifest
	/// saved before it reads as none.
	[Appended, Setting("GUI sheets", "GuiStyleSheetAsset", "(none)", "UI")]
	public List<Guid> GuiStyleSheetIds = new .() ~ delete _;
	/// The cooked GUI document the player's boot splash shows through the engine GUI while the
	/// default scene loads, its progress the GUI's data value `bootProgress` (0 to 1). Nil for
	/// the engine's own loading screen. [Appended].
	[Appended, Setting("Loading screen", "GuiDocumentAsset", "(built-in)", "Startup")]
	public Guid GuiLoadingDocumentId;
	/// The plugins the project enables, in order, each with its platforms and settings. An entry
	/// whose plugin is missing is kept as read and written back unchanged. [Appended], so a
	/// manifest saved before it reads none.
	[Appended]
	public List<EnabledPlugin> Plugins = new .() ~ DeleteContainerAndItems!(_);

	/// The project's entry for plugin `id`, or null when it enables no such plugin. BORROWED.
	public EnabledPlugin FindPlugin(StringView id)
	{
		for (let entry in Plugins)
		{
			if (entry.Id == id)
				return entry;
		}
		return null;
	}

	/// Whether the game draws at a fixed resolution rather than at its output's size.
	public bool HasRenderResolution => (RenderWidth > 0) && (RenderHeight > 0);

	/// The player's window in a few words, appended: "1280 × 720, windowed", "1280 × 720,
	/// fullscreen", or "borderless, the display's size".
	public void WindowSummary(String outText)
	{
		if (WindowMode == .Borderless)
			outText.Append("borderless, the display's size");
		else
			outText.AppendF("{} × {}, {}", WindowWidth, WindowHeight, (WindowMode == .Fullscreen) ? "fullscreen" : "windowed");
	}

	/// Rewrites the readable path mirror (the default scene's) from its guid, after a settings
	/// editor changed the guid. `pathOf` appends an asset's path, or nothing for a guid that
	/// names none.
	public void RefreshPathMirrors(delegate void(Guid id, String outPath) pathOf)
	{
		DefaultScene.Clear();
		if (DefaultSceneId.IsSet)
			pathOf(DefaultSceneId, DefaultScene);
	}
}
