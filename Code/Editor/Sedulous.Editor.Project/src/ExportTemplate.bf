using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// A prebuilt per platform export bundle: a player binary, its runtime sidecars and a
/// template.xml. Templates live in a machine local templates root, not committed, importable
/// and removable, decoupled from any one machine's paths; a preset names one by id or by
/// platform and config. The HOST implicit template is synthesized from the running tool's
/// own build, so a dev export for the current platform needs no setup.
[Serializable(2)]
class ExportTemplate
{
	/// "sedulous-linux64-release-0.1.0", unique within the templates root.
	public String Id = new .() ~ delete _;
	/// "Linux64 Release 0.1.0"
	public String Name = new .() ~ delete _;
	/// "Win64" / "Linux64" / "Web"
	public String Platform = new .() ~ delete _;
	/// The engine this was built against; soft matched, a mismatch warns.
	public String EngineVersion = new .() ~ delete _;
	/// The player file within the template directory.
	public String PlayerBinary = new .() ~ delete _;
	/// The required runtime files, relative to the template directory, always staged.
	public List<String> Sidecars = new .() ~ DeleteContainerAndItems!(_);
	public String Notes = new .() ~ delete _;
	/// "Debug" / "Release" / "Test", the identity; empty reads as Release.
	public String Config = new .() ~ delete _;
	/// Metadata, not a selector.
	public String Compiler = new .() ~ delete _;
	/// Optional symbol files, staged only when the preset opts in.
	public List<String> Symbols = new .() ~ DeleteContainerAndItems!(_);

	/// The absolute directory the bundle lives in; the host's build directory for the
	/// synthesized one. Set by the registry.
	[NotSerialized] public String Directory = new .() ~ delete _;
	/// The synthesized host template, against one imported from disk.
	[NotSerialized] public bool IsHost = false;

	public StringView EffectiveConfig => Config.IsEmpty ? "Release" : StringView(Config);
}
