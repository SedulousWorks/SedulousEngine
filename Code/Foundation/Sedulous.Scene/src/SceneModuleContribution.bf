using System;

namespace Sedulous.Scene;

/// A module contributed at RUNTIME, by a game's native plugin.
///
/// Keyed by the installed system's type, one manager type per contribution, so a removal
/// can find it again in a live scene.
struct SceneModuleContribution
{
	/// Borrowed: the plugin's literal.
	public StringView Id = default;
	public SceneModule.InstallFunction Install = null;
	public SceneModule.RegisterReflectionFunction RegisterReflection = null;
	/// The live removal key.
	public uint64 SystemType = 0;

	public this() {}
}
