using System;
using Sedulous.Core;

namespace Sedulous.Editor.Project;

/// The player builder an export runs: each preset's player built where its Builder says, on this
/// machine (ProjectPlayerBuilder) or in the Steam Deck container (SteamDeckPlayerBuilder), both
/// through one project build service, cancelled by one token, and both made to reuse the last
/// build or not. Describe and CanBuild say the same of a preset for the Export dialog and the
/// preset tools.
class PresetPlayerBuilder : IPlayerBuilder
{
	private ProjectPlayerBuilder mHost ~ delete _;
	private SteamDeckPlayerBuilder mSteamDeck ~ delete _;

	/// Over `service` (borrowed), the engine data root `dataRoot` the SDK is found from, and
	/// `cancel` (null: nothing cancels), as ProjectPlayerBuilder takes them. With `reuseLastBuild`
	/// nothing builds: the last build of each ships.
	public this(ProjectBuildService service, StringView dataRoot, CancelToken cancel = null, bool reuseLastBuild = false)
	{
		mHost = new .(service, dataRoot, cancel, reuseLastBuild);
		mSteamDeck = new .(service, dataRoot, cancel, reuseLastBuild);
	}

	public Result<void, ErrorCode> Build(EditorProject project, ExportPreset preset, PlayerBuild outBuild, ExportProgress onProgress,
		String outRefusal)
	{
		if (preset.Builder == .SteamDeck)
			return mSteamDeck.Build(project, preset, outBuild, onProgress, outRefusal);
		return mHost.Build(project, preset, outBuild, onProgress, outRefusal);
	}

	/// What a player for `preset` of the project named `projectName` is built as, for people
	/// ("SkyHopperPlayer, ShippingRelease, Linux64", with ", Steam Deck" for the container's),
	/// into `outDescription`. False, with why in `outWhy`, when its builder refuses the preset.
	public static bool Describe(StringView projectName, ExportPreset preset, String outDescription, String outWhy)
	{
		if (preset.Builder != .SteamDeck)
			return ProjectPlayerBuilder.Describe(projectName, preset, outDescription, outWhy);
		let config = scope String();
		if (SteamDeckPlayerBuilder.Target(preset, config, outWhy) case .Err)
			return false;
		let game = ProjectBuild.GameName(projectName, .. scope .());
		let name = ProjectBuild.EntryName(game, .Player, .. scope .());
		outDescription.Set(scope $"{name}, {config}, {SteamDeckPlayerBuilder.cPlatform}, Steam Deck");
		return true;
	}

	/// Whether a player for `preset` can be built on this machine by its builder, with why not in
	/// `outWhy` (ProjectPlayerBuilder.CanBuild, SteamDeckPlayerBuilder.CanBuild).
	public static bool CanBuild(ExportPreset preset, String outWhy)
	{
		if (preset.Builder == .SteamDeck)
			return SteamDeckPlayerBuilder.CanBuild(preset, outWhy);
		return ProjectPlayerBuilder.CanBuild(preset, outWhy);
	}
}
