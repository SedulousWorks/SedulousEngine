using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// One export target: the platform and config its player is built for, the player's name, the
/// game specific extras and the output naming. Nothing in it is an absolute path, so a preset
/// is portable and committable. The CLI and the editor's Export menu both drive the export from
/// these, so a preset produces the SAME dist whichever surface triggers it.
///
/// Each field a preset editor sets is a [Setting]: the MCP preset tools read and set them
/// through its reflection.
[Serializable(1, true)] // afterRead: the legacy template id dropped
class ExportPreset
{
	/// "Linux64 Desktop"
	[Setting("Name")]
	public String Name = new .() ~ delete _;
	/// "Win64" / "Linux64" / "Web": the build platform tag.
	[Setting("Platform")]
	public String Platform = new .() ~ delete _;
	/// Legacy: the export template a preset named before an export built its player. Kept only
	/// as the slot a stored preset has here (the binary form is positional), read and dropped
	/// (AfterRead), so it is always written empty; no [Setting], so no tool shows or sets it.
	public String TemplateId = new .() ~ delete _;
	/// The output executable name; empty is the game's name.
	[Setting("Player name")]
	public String PlayerName = new .() ~ delete _;
	/// The export root relative output directory; empty is the sanitised Name.
	[Setting("Output subdir")]
	public String OutputSubdir = new .() ~ delete _;
	/// Game specific extra files, beyond what the player's build leaves beside it, project
	/// relative.
	[Setting("Extra files")]
	public List<String> AdditionalFiles = new .() ~ DeleteContainerAndItems!(_);
	/// "Debug" / "Release" / "Test"; empty is Release.
	[Setting("Config")]
	public String Config = new .() ~ delete _;
	/// Stage the player's symbol files into the dist (its .pdb on Windows); the default ships
	/// none.
	[Setting("Stage debug symbols")]
	public bool StageSymbols = false;
	/// Ship only the closure of the entry points; the default packs everything, the escape
	/// hatch for a team not managing reachability.
	[Setting("Prune to reachable content")]
	public bool PruneToReachable = false;

	/// This platform draws at its own resolution rather than the project's (a handheld's
	/// native panel, say): the dist carries these instead.
	[Appended, Setting("Own render size")]
	public bool OverridesRender = false;
	[Appended, Setting("Render width"), Range(0, 16384, 1)]
	public uint32 RenderWidth = 0;
	[Appended, Setting("Render height"), Range(0, 16384, 1)]
	public uint32 RenderHeight = 0;
	[Appended, Setting("Render fit")]
	public FitMode RenderFit = .Letterbox;

	/// This platform's window differs from the project's (fullscreen on a console-like
	/// device, say): the dist carries these instead.
	[Appended, Setting("Own window")]
	public bool OverridesWindow = false;
	[Appended, Setting("Window width"), Range(1, 16384, 1)]
	public uint32 WindowWidth = 1280;
	[Appended, Setting("Window height"), Range(1, 16384, 1)]
	public uint32 WindowHeight = 720;
	[Appended, Setting("Window mode")]
	public WindowMode WindowMode = .Windowed;
	[Appended, Setting("Window resizable")]
	public bool WindowResizable = true;

	/// This platform is held its own way (a phone-facing Web preset says Landscape, so a game
	/// that takes any shape on a desktop is presented turned on a phone held upright).
	[Appended, Setting("Own orientation")]
	public bool OverridesOrientation = false;
	[Appended, Setting("Orientation")]
	public ScreenOrientation Orientation = .Any;

	/// The dist keeps its custom shaders' HLSL (a game that wants modders to read them). Off:
	/// the pack carries the shaders as bytecode and the dist ships no shader source, as the
	/// engine's own ship none.
	[Appended, Setting("Include shader source")]
	public bool IncludeShaderSource = false;

	public void CopyTo(ExportPreset other)
	{
		other.Name.Set(Name);
		other.Platform.Set(Platform);
		other.PlayerName.Set(PlayerName);
		other.OutputSubdir.Set(OutputSubdir);
		ClearAndDeleteItems(other.AdditionalFiles);
		for (let file in AdditionalFiles)
			other.AdditionalFiles.Add(new String(file));
		other.Config.Set(Config);
		other.StageSymbols = StageSymbols;
		other.PruneToReachable = PruneToReachable;
		other.OverridesRender = OverridesRender;
		other.RenderWidth = RenderWidth;
		other.RenderHeight = RenderHeight;
		other.RenderFit = RenderFit;
		other.OverridesWindow = OverridesWindow;
		other.WindowWidth = WindowWidth;
		other.WindowHeight = WindowHeight;
		other.WindowMode = WindowMode;
		other.WindowResizable = WindowResizable;
		other.OverridesOrientation = OverridesOrientation;
		other.Orientation = Orientation;
		other.IncludeShaderSource = IncludeShaderSource;
	}

	/// Once read (the [Serializable] hook): a template id stored before an export built its
	/// player is dropped, so the next save writes the slot empty.
	public void AfterRead()
	{
		TemplateId.Clear();
	}

	/// The config for resolution: empty reads as Release.
	public StringView EffectiveConfig => Config.IsEmpty ? "Release" : StringView(Config);
}
