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
[Serializable(1)]
class ExportPreset
{
	/// "Linux64 Desktop"
	public String Name = new .() ~ delete _;
	/// "Win64" / "Linux64" / "Web": the build platform tag.
	public String Platform = new .() ~ delete _;
	/// Which template; empty resolves by platform and config.
	public String TemplateId = new .() ~ delete _;
	/// The output executable name; empty is the template's player basename.
	public String PlayerName = new .() ~ delete _;
	/// The export root relative output directory; empty is the sanitised Name.
	public String OutputSubdir = new .() ~ delete _;
	/// Game specific extra files, beyond the template's sidecars, project relative.
	public List<String> AdditionalFiles = new .() ~ DeleteContainerAndItems!(_);
	/// "Debug" / "Release" / "Test"; empty is Release.
	public String Config = new .() ~ delete _;
	/// Stage the template's symbol files into the dist; the default ships stripped.
	public bool StageSymbols = false;
	/// Ship only the closure of the entry points; the default packs everything, the escape
	/// hatch for a team not managing reachability.
	public bool PruneToReachable = false;

	/// This platform draws at its own resolution rather than the project's (a handheld's
	/// native panel, say): the dist carries these instead.
	[Appended]
	public bool OverridesRender = false;
	[Appended]
	public uint32 RenderWidth = 0;
	[Appended]
	public uint32 RenderHeight = 0;
	[Appended]
	public FitMode RenderFit = .Letterbox;

	/// This platform's window differs from the project's (fullscreen on a console-like
	/// device, say): the dist carries these instead.
	[Appended]
	public bool OverridesWindow = false;
	[Appended]
	public uint32 WindowWidth = 1280;
	[Appended]
	public uint32 WindowHeight = 720;
	[Appended]
	public WindowMode WindowMode = .Windowed;
	[Appended]
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
