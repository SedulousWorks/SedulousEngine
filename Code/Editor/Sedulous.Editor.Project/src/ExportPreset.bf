using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// One export target: which template, the player and its runtime sidecars, plus the game
/// specific extras and the output naming. References a template by id or platform, never
/// an absolute path, so a preset is portable and committable. The CLI and the editor's
/// Export menu both drive the export from these, so a preset produces the SAME dist
/// whichever surface triggers it.
///
/// Each field a preset editor sets is a [Setting]: the MCP preset tools read and set them
/// through its reflection.
[Serializable(1)]
class ExportPreset
{
	/// "Linux64 Desktop"
	[Setting("Name")]
	public String Name = new .() ~ delete _;
	/// "Win64" / "Linux64" / "Web": the build platform tag.
	[Setting("Platform")]
	public String Platform = new .() ~ delete _;
	/// Which template; empty resolves by platform and config.
	[Setting("Template")]
	public String TemplateId = new .() ~ delete _;
	/// The output executable name; empty is the template's player basename.
	[Setting("Player name")]
	public String PlayerName = new .() ~ delete _;
	/// The export root relative output directory; empty is the sanitised Name.
	[Setting("Output subdir")]
	public String OutputSubdir = new .() ~ delete _;
	/// Game specific extra files, beyond the template's sidecars, project relative.
	[Setting("Extra files")]
	public List<String> AdditionalFiles = new .() ~ DeleteContainerAndItems!(_);
	/// "Debug" / "Release" / "Test"; empty is Release.
	[Setting("Config")]
	public String Config = new .() ~ delete _;
	/// Stage the template's symbol files into the dist; the default ships stripped.
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

	public void CopyTo(ExportPreset other)
	{
		other.Name.Set(Name);
		other.Platform.Set(Platform);
		other.TemplateId.Set(TemplateId);
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
	}

	/// The config for resolution: empty reads as Release.
	public StringView EffectiveConfig => Config.IsEmpty ? "Release" : StringView(Config);
}
