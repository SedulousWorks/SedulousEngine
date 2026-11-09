using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Editor.Project;

/// The player an export ships, built for one (platform, config): its folder, its binary, and the
/// files that go beside it, each named relative to the folder.
class PlayerBuild
{
	/// The share of a whole export's progress the player's build reports across, before the cook.
	public const float cProgressStart = 0.02f;
	public const float cProgressEnd = 0.40f;

	/// Where the build put it.
	public String Directory = new .() ~ delete _;
	/// <Game>Player (with .exe on Windows), or the web player's page, <Game>PlayerWeb.html.
	public String Binary = new .() ~ delete _;
	/// What ships beside it: the shared libraries less the shader compiler's, and the third-party
	/// notices; or the web page's parts.
	public List<String> Files = new .() ~ DeleteContainerAndItems!(_);
	/// Its symbol files, which ship only when a preset asks: the .pdb on Windows, none elsewhere.
	public List<String> Symbols = new .() ~ DeleteContainerAndItems!(_);
	/// What was built, for people: "SkyHopperPlayer, ShippingRelease, Linux64".
	public String Description = new .() ~ delete _;

	/// Back to nothing built.
	public void Clear()
	{
		Directory.Clear();
		Binary.Clear();
		ClearAndDeleteItems!(Files);
		ClearAndDeleteItems!(Symbols);
		Description.Clear();
	}

	/// `other` made the same as this.
	public void CopyTo(PlayerBuild other)
	{
		other.Clear();
		other.Directory.Set(Directory);
		other.Binary.Set(Binary);
		for (let file in Files)
			other.Files.Add(new .(file));
		for (let symbol in Symbols)
			other.Symbols.Add(new .(symbol));
		other.Description.Set(Description);
	}
}

/// Makes the player an export ships for a preset.
interface IPlayerBuilder
{
	/// Builds the player `preset` exports (its platform, its config) for `project` into
	/// `outBuild`, `onProgress` (may be null) told as it goes. Refused with why in `outRefusal`:
	/// no SDK, no BeefBuild, no Emscripten, another host's platform, a config no player is built
	/// in, a compile error; a build's diagnostics stay on its job.
	Result<void, ErrorCode> Build(EditorProject project, ExportPreset preset, PlayerBuild outBuild, ExportProgress onProgress, String outRefusal);
}
