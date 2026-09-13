namespace Sedulous.Pipeline.Core;

/// Whether a builder's output can differ from one export target to the next.
enum BuildVariance : uint8
{
	/// Cooked ONCE into the host database and copied forward into every target's, never
	/// re-cooked, and its recipe carries no platform salt. The default, so a builder that has
	/// never thought about targets keeps behaving as it did.
	PlatformInvariant,
	/// Cooked per target, with the target salted into the recipe, so one source produces a
	/// distinct product for each. Textures, where BC and ASTC are different bytes.
	PlatformVariant,
}
