namespace Sedulous.Editor.Terrain;

/// What the hole brush does to the samples under its disc.
enum HoleMode : uint8
{
	/// Remove the surface: every triangle touching a cut sample is gone.
	Cut,
	/// Restore it.
	Fill
}
