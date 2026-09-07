namespace Sedulous.Shaders;

/// How the host chooses between a cooked pack and compiling on demand.
enum ShaderPackPolicy
{
	/// Development when possible, the pack otherwise.
	Automatic,
	/// The pack, even where development would work. For testing a shipped configuration on
	/// a desktop.
	ForcePack,
	/// Development, even where a pack is present.
	ForceDev
}
